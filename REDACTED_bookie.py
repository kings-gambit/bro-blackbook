#!/usr/bin/env python

#=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
#	Author:
#		Nicholas Siow
#
#	Description:
#		Generates email alerts for blackbook/intel/notice logs
#=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import os
import gzip
import time
import smtplib
import argparse
from email.mime.text import MIMEText

#=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
#=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
#
#	CONFIG PANEL - make changes here and nowhere else!
#
#=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
#=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

BRO_LOG_DIRECTORY = "/opt/bro/logs"

MAILING_LIST = [
	REDACTED
]

EMAIL_SUBJECTS = {
	"intel": "Intel hit for IP: ",
	"notice": "NOTICE hit for IP: ",
	"blackbook": "BLACKBOOK hit for IP: ",
}

USERSEARCH = None

FROM_ADDR = REDACTED

MAX_ALERTS = 200

###############################################################################
#	program variables
###############################################################################

TESTING = False
DEBUGGING = False

###############################################################################
#	helper functions
###############################################################################

def debug( msg ):
	if DEBUGGING:
		print "[DEBUG]: " + msg

def err( msg, code=1 ):
	print "[ERROR]: " + msg
	exit(code)

###############################################################################
#	main script subroutine
###############################################################################

def main():

	###########################################################################
	#	parse cmd-line arguments
	###########################################################################

	parser = argparse.ArgumentParser(description='Generate email alerts for blackbook/intel/notice logs')
	parser.add_argument('--logs', nargs='+', metavar='L', help='specify the logs to be used')
	parser.add_argument('--debug', action='store_true', help='turn on program debugging')
	parser.add_argument('--recent', action='store_true', help='use the most recent logs')
	parser.add_argument('--test', action='store_true', help='test the script without sending any emails')
	args = parser.parse_args()

	global DEBUGGING
	DEBUGGING = args.debug
	global TESTING
	TESTING = args.test

	###########################################################################
	#	sanity checks for arguments
	###########################################################################

	debug("Starting argument sanity checks")

	if not MAILING_LIST:
		err("Empty mailing list")

	if args.recent and args.logs:
		err("Cannot run with the --logs argument as well as the --recent argument")

	if not args.recent and not args.logs:
		err("Please either specify logs to check or run with the --recent option.")

	if args.logs:
		for log in args.logs:
			if not os.path.isfile(log):
				err("Specified log does not exist: " + log)

			parseable_logs = ('intel', 'notice', 'blackbook')

			if not os.path.basename.startswith( parseable_logs ):
				err("Log must be of type: {0}".format(parseable_logs))

	if args.recent:
		if not os.path.isdir(BRO_LOG_DIRECTORY):
			err("Specified BRO_LOG_DIRECTORY does not exist: " + BRO_LOG_DIRECTORY)

	# TODO - add more checks if you can think of edge cases

	debug("Finished argument sanity checks")

	###########################################################################
	#	find logs if requested by arguments
	###########################################################################

	# if the user wants to use the most recent files, find those in the
	# filesystem
	if args.recent:

		# find the most recent bro log directory that is not empty
		dirs = reversed(sorted(os.listdir(BRO_LOG_DIRECTORY)))
		mrd = next(d for d in dirs if d.startswith('20') and os.listdir(os.path.join(BRO_LOG_DIRECTORY, d)))
		debug("Found most recent log directory: " + mrd)

		all_logs = os.listdir(os.path.join(BRO_LOG_DIRECTORY, mrd))

		# find the most recent time stamp within that directory
		mrt = max(os.path.basename(l).split('.')[1] for l in all_logs)
		debug("Found most recent log time: " + mrt)

		# pull out those logs that were created the same time as the most recent
		temp = [ os.path.join(BRO_LOG_DIRECTORY, mrd, l) for l in all_logs if mrt in l ]
		args.logs = [ t for t in temp if any(k in t for k in EMAIL_SUBJECTS.keys()) ]
		debug("Found most recent logs: {0}".format(args.logs))

		if not args.logs:
			err("Could not find any appropriate logs to report on!")

		# sanity check, make sure each of these files exists
		for log in args.logs:
			if not os.path.isfile(log):
				err("Found log file does not exist: " + log)

	###########################################################################
	#	parse logs
	###########################################################################

	headers = {}
	data = []

	for log in args.logs:

		with gzip.open(log, 'r') as f:
			lines = [l.rstrip() for l in f.readlines()]
		debug("Read {0} lines from file: {1}".format(len(lines), log))

		header = next(line for line in lines if line.startswith("#fields")).split("\t")[1:]
		if header:
			debug("Found {0} as header for file: {1}".format(header, log))
		else:
			err("Could not find header in file: " + log)
		headers[log] = header

		for line in lines:
			if not line.startswith('#'):
				this_data = dict(zip(header, line.split("\t")))
				this_data['source_log'] = log
				data.append(this_data)

	debug("Found {0} pieces of data".format(len(data)))

	# make sure there aren't too many alerts to send
	if len(data) > MAX_ALERTS:
		err("Too many alerts! Found {0} and the max is {1}".format(len(data), MAX_ALERTS))

	###########################################################################
	#	connect to and clean throttle file
	###########################################################################

	current_time = int(time.time())

	# get location of this file
	throttle_file = os.path.join(os.path.dirname(os.path.realpath(__file__)), 'throttle')

	# if the file exists, read from it. otherwise, set an empty throttle
	throttle = {}
	if os.path.isfile(throttle_file):
		with open(throttle_file, 'r') as f:
			for line in f:
				line = line.rstrip()
				expire, key = line.split(',')
				expire = int(expire)
				if expire > current_time:
					throttle[key] = expire
				else:
					debug("Deleted throttle item {0}, current time = {1}".format(line, current_time))

	debug("Read {0} entries from throttle file: {1}".format(len(throttle), throttle_file))

	###########################################################################
	#	add extra info to alerts if necessary
	###########################################################################

	for d in data:
		
		# find the WUSTL IP
		if 'id.orig_h' in d and 'id.resp_h' in d:
			if d['id.orig_h'].startswith(('128.252.', '65.254.')):
				d['wustl_ip'], d['wustl_port'] = d['id.orig_h'], d['id.orig_p']
			elif d['id.resp_h'].startswith(('128.252.', '65.254.')):
				d['wustl_ip'], d['wustl_port'] = d['id.resp_h'], d['id.resp_p']
		elif 'tx_hosts' in d and 'rx_hosts' in d:
			if d['tx_hosts'].startswith(('128.252.', '65.254.')):
				d['wustl_ip'] = d['tx_hosts']
				d['wustl_port'] = None
			elif d['rx_hosts'].startswith(('128.252.', '65.254.')):
				d['wustl_ip'] = d['rx_hosts']
				d['wustl_port'] = None
		else:
			err("Not sure how to find WUSTL IP for alert: {0}".format(d))
		debug("Found WUSTL info: {0},{1}".format(d['wustl_ip'], d['wustl_port']))

		# if the correct fields are present, try to do a user lookup
		if USERSEARCH and d['wustl_ip'] and d['wustl_port']:
			debug("Starting user lookup...")
			cmd = " ".join(USERSEARCH, d['ts'], d['wustl_ip'], d['wustl_port'])
			d['user'] = check_output(cmd, shell=True)
			debug("Found user info: " + d['user'])

	###########################################################################
	#	send email alerts
	###########################################################################

	# throttle for 1 day
	throttle_period = 86400

	for d in data:

		# determine alert subject
		alert_subject = None
		for k, v in EMAIL_SUBJECTS.iteritems():
			if k in d['source_log']:
				alert_subject = v + d['wustl_ip']
				break
		if not alert_subject:
			err("Could not find subject for alert: {0}".format(d))

		# check whether or not to throttle
		throttle_key = d['wustl_ip'] + '~' + alert_subject
		debug("Created throttle key: " + throttle_key)
		if throttle_key in throttle:
			debug("Item with key {0} is throttled".format(throttle_key))
			continue
		else:
			throttle[throttle_key] = int(time.time()) + throttle_period

		# find the appropriate header
		header = headers[d['source_log']]

		# organize data into a sorted string
		organized_data = []
		for h in header:
			organized_data.append( "{0} = {1}".format(h,d.pop(h, '?'))  )
		for k, v in d.iteritems():
			organized_data.append( "{0} = {1}".format(k,v) )

		msg = MIMEText("\n".join(organized_data))
		msg['Subject'] = alert_subject
		msg['From'] = FROM_ADDR

		# send the data
		s = smtplib.SMTP('localhost')
		for rcpt in MAILING_LIST:
			msg['To'] = rcpt
			if TESTING:
				debug("Rcpt {0} would have received the following email:\n{1}".format(rcpt, msg.as_string()))
			else:
				s.sendmail(FROM_ADDR, rcpt, msg.as_string())
				debug("Sent email to rcpt: " + rcpt)
		s.quit()

	###########################################################################
	#	rewrite throttle file
	###########################################################################

	debug("throttle now has {0} items, writing to file".format(len(throttle)))
	debug("{}".format(throttle))
	with open(throttle_file, 'w') as f:
		for key, expire in throttle.iteritems():
			f.write( "{0},{1}\n".format(expire, key) )


if __name__ == '__main__':
	main()
