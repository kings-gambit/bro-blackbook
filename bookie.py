#!/usr/bin/env python

import os
import re
import sys
from glob import glob
from datetime import datetime
from termcolor import colored

# find the directory where this script is located
my_dir = os.path.dirname(os.path.realpath(__file__))

# find all .brodata files
brodata_files = glob("**/*.brodata")

def error( msg ):
	print colored("[FAIL] " + msg, 'red')
	exit(1)

def clean():
	for b in brodata_files:
		old = open(b, 'r')
		new = open(b + '.tmp', 'w')
	
		lines2keep = []
		for line in old:
			pass
	
		old.close()
		new.close()

		# move the files over!

def check():

	for b in brodata_files:
		with open(b, 'r') as f:
			line_num = 0
			num_fields = 0
			for line in f:
				line = line.strip()

				if line_num == 0:
					if line != r"#separator \x09":
						error("no separator header in line0 of file: " + b)

				elif line_num == 1:
					if not line.startswith('#fields'):
						error("no field string in lin1 of file: " + b)
					else:
						if len(line.split()) != len(line.split('\t')):
							error("field string isn't tab-delimited: " + line)
						num_fields = len(line.split('\t')) - 1

				else:
					# make sure there are no empty lines
					if not line or line.isspace():
						error("found empty line in file: " + b)

					# make sure every line has the proper number of fields
					if len(line.split('\t')) != num_fields:
						error("incorrect number of fields in line: " + line)

				line_num += 1

		print colored("[PASS] " + b, 'green')

if __name__ == '__main__':
	if len(sys.argv) != 2 or '-h' in sys.argv or '--help' in sys.argv:
		print "USAGE: bookie.py (clean|check)"
		exit(1)

	if 'clean' in sys.argv:
		check()
		clean()
	elif 'check' in sys.argv:
		check()
