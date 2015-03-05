#!/usr/bin/env python

import os
import re
from glob import glob
from datetime import datetime

# find the directory where this script is located
my_dir = os.path.dirname(os.path.realpath(__file__))

# find all .brodata files
brodata_files = glob("**/*.brodata")

def error( msg ):
	print "[ERROR] " + msg
	exit(1)

def clean():
	for b in brodata_files:
		old = open(b, 'r')
		new = open(b + '.tmp', 'w')
	
		lines2keep = []
		for line in old:
			
	
		old.close()
		new.close()

def check():
	for b in brodata_files:
		with open(b, 'r') as f:
			lines = f.readlines()

		# make sure there are no empty lines
		empty_line = next( l for l in lines if l.isspace() )
		if empty_line:
			error("found empty line in file: " + b)

		# check for separator info in header
		if lines[0] != r"#separator \x09":
			error("no separator header in file: " + b)

		# check for #fields info in header
		field_string = lines[1]
		if not field_string.startswith("#fields"):
			error("no separator header in file: " + b)

		# make sure field string is tab delimited
		if len(field_string.split()) != len(field_string.split('\t')):
			error("field string isn't tab-delimited: " + field_string)
		num_fields = len(field_string.split('\t')) - 1

		# make sure every line has the proper number of fields
			
		

if __name__ == '__main__':
	if len(sys.argv) != 2 or '-h' in sys.argv or '--help' in sys.argv:
		print "USAGE: bookie.py (clean|check)"
		exit(1)

	if 'clean' in sys.argv:
		check()
		clean()
	elif 'check' in sys.argv:
		check()
