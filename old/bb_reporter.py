#!/usr/bin/env python

#--------------------------------------------------------------------------------
#	Author:
#		Nicholas Siow | compilewithstyle@gmail.com
#
#	Description:
#		Reads through the Notice log and generates email alerts based on
#		lines created by the NSO Bro Blackbook
#--------------------------------------------------------------------------------

# filepath to the YAML configuration file
CONFIG_FP = "/Users/nsiow/Dropbox/code/bro/blackbook/etc/config.yml"

# variable to turn debugging on or off
DEBUG = True

import os
import re
import sys
import yaml
import string
import pickle
import random
from glob import glob
from termcolor import colored
from datetime import datetime
from subprocess import Popen, check_output

#--------------------------------------------------------------------------------
#	some helpful runtime debugging functions
#--------------------------------------------------------------------------------

def err(msg):
	print colored( "[ERROR] {0}".format(msg), 'red' )
	exit(1)

def warn(msg):
	if DEBUG:
		print colored( "[WARNING] {0}".format(msg), 'yellow' )

def debug(msg):
	if DEBUG:
		print colored( "[DEBUG] {0}".format(msg), 'green' )

#--------------------------------------------------------------------------------
#	Reporter object to hold the logic for sending the alerts
#--------------------------------------------------------------------------------

class Reporter( object ):
	"""objects containing the data structures and methods necessary to 
	generate email alerts for the Blackbook entries"""

	def __init__( self, config ):
		"""create a new Reporter object from the given configuration"""
		self.num_emails_sent = 0
		self.mailing_list = config['mailing_list']

	def parse_record( self, record_string ):
		"""translate a bro record into a python dictionary"""
		record = {}

		## keep solving the smallest dictionaries and merge them
		## into larger ones
		##
		while True:
			nested = re.search(r'\[[^\[\]]+\]', record_string)

			if not nested:
				break
			else:
				nested = nested.group()

			ndict = {}
			n = nested[1:-1]
			pairs = n.split(', ')
			for p in pairs:
				pdata = re.findall(r'^(.*?)=(.*)$', p)

				if not pdata: continue

				for pd in pdata:
					ndict[pd[0]] = pd[1]

			record_string = record_string.replace(nested, pickle.dumps(ndict))

		return pickle.loads(record_string)

	def send_email( self, linedata ):
		"""calls a subprocess to send the alert to everyone on the
		mailing list"""

		## pull out the key-value pairs, organize them alphabetically, and
		## put them into an ordered list
		##
		r = linedata['blackbook_record']
		fv_pairs = []

		## pull out timestamp first so it is at the beginning of the list
		##
		if 'ts' in r:
			ts = r.pop('ts')
			fv_pairs.append( ('ts', ts) )

		for key in sorted(r):
			fv_pairs.append( (key,r[key]) )

		## create the email file
		##
		email_subject = linedata['msg']
		rand_hash = ''.join(random.choice(string.ascii_lowercase + string.digits) for _ in range(20))
		email_file = "/tmp/{0}_{1}.email".format(rand_hash, self.num_emails_sent)
		with open( email_file, 'w' ) as f:
			f.write( "msg = " + linedata['msg'] + '\n' )
			f.write( "source = " + linedata['blackbook_source'] + '\n' )
			f.write( "original_log = " + linedata['original_log'] + '\n\n' )

			max_field_len = max(len(k[0]) for k in fv_pairs) + 3
			for k, v in fv_pairs:
				if v == '<uninitialized>':
					f.write( "{1:{0}} = {2}\n".format(max_field_len, k, "") )
				else:
					# remove escaped characters put there by bro
					for x in [ '{\\x0a', '\\x0a}', '\\x0a', '\\x09' ]:
						v = v.replace(x, '')
					f.write( "{1:{0}} = {2}\n".format(max_field_len, k, v) )

		## send the email
		##
		cmd = "cat {0} | mail -s '{1}' '{2}'"
		for rcpt in self.mailing_list:
			mycmd = cmd.format(email_file, email_subject, rcpt)
			Popen( mycmd, shell=True )

		## increment the email counter
		##
		self.num_emails_sent += 1

	def report( self, linedata ):
		"""takes in a dict containing the info from a Notice log"""

		## try to translate the Bro record into a python dict
		##
		try:
			linedata['blackbook_record'] = self.parse_record(linedata['blackbook_record'])
		except:
			err( "couldn't parse bro record: " + linedata['blackbook_record'] )

		## pass the info to the send_email subroutine to be converted
		## to a readable form and sent out
		##
		self.send_email( linedata )

#--------------------------------------------------------------------------------
#	main script let's do this
#--------------------------------------------------------------------------------

if __name__ == '__main__':

	## print usage message if it was requested
	##
	if '-h' in sys.argv or '--help' in sys.argv:
		print "usage: bb_reporter.py [OPTIONS] [LOGS...]\n"
		print "-a, --auto  |  automatically choose the most recent notice log"
		exit(1)

	## make sure CONFIG_FP was specified and is a valid file
	##
	if not CONFIG_FP or not os.path.isfile(CONFIG_FP):
		err( "invalid filepath for configuration file: " + CONFIG_FP )

	## read in the YAML config file
	##
	with open(CONFIG_FP, 'r') as f:
		try:
			raw_config = yaml.load(f)
		except yaml.scanner.ScannerError as e:
			err( "couldn't parse YAML config file due to the following error: {0}".format(e) )

	debug( "found raw configuration: {0}".format(raw_config) )

	## make sure configuration file is valid
	##
	for field in [ 'bro_log_dir', 'mailing_list' ]:
		if field not in raw_config:
			err( "config is missing field: " + field )

	## if logs are specified, use those
	##
	if any( a.startswith('notice') and a.endswith('.gz') for a in sys.argv ):
		logs = [ a for a in sys.argv if a.startswith('notice') and a.endswith('.gz') ]
	## otherwise if they requested auto function, then find the most recent notice log
	##
	elif '--auto' in sys.argv:
		logs = sorted(glob(raw_config['bro_log_dir']+'/**/notice.*'))

		if not logs:
			err( "couldn't find any logs in specified directory: {0}".format(raw_config['bro_log_dir']) )
		else:
			logs = [ logs[-1] ]
	## if neither of those are given, throw an error
	##
	else:
		err( 'please specify notice log files to run against or run with "--auto" option' )

	debug( "found logs: {0}".format(logs) )

	## create the Reporter object
	##
	r = Reporter( raw_config )

	## parse through the file and send each line to the reporter
	##
	fields = [ 'note', 'msg', 'blackbook_source', 'blackbook_record' ]
	for log in logs:
		cmd = "gzcat -f {0} | bro-cut {1} | grep Blackbook".format(log, ' '.join(fields))
		lines = check_output(cmd, shell=True).splitlines()[:25] #FIXME

		if len(lines) > raw_config['max_alerts']:
			err( "too many lines, check for false positives in your data: {0} lines".format(len(lines)) )

		for line in lines:
			linedata = dict(zip(fields, line.split('\t')))
			linedata['original_log'] = log
			r.report( linedata )

