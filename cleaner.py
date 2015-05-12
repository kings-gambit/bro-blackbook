#!/usr/bin/env python

#=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
#   Author:
#       Nicholas Siow
#
#   Description:
#	Enforces formatting and removes old entries for bro blackbook
#=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import os
import datetime
import shutil

#=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
#=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
#
#	CONFIG PANEL - make changes here and nowhere else!
#
#=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
#=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

BRO_LOCAL = "/Users/nsiow/box/code/work_projects/blackbook"

SEPARATOR = r'\x09'
CURRENT_FILE, CURRENT_LINE, CURRENT_LINE_NUMBER = None, None, None

CURRENT_DATE = datetime.date.today()

#=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
#	end of config panel
#=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

#

def _pass():
	print "[PASS]: \t" + CURRENT_FILE

def _fail(reason):
	print "[FAIL] in file {0}, line {1}".format(CURRENT_FILE, CURRENT_LINE_NUMBER)
	print "Error in line: " + CURRENT_LINE
	print reason
	exit(1)

def _info(msg):
	print "[INFO]: " + msg

def main():

	## find all brodata files in the local-BRO directory
	##
	brodata_files = []
	for d, _, files in os.walk(BRO_LOCAL):
		for f in files:
			path = os.path.join(d, f)
			if path.endswith('.brodata'):
				brodata_files.append(path)
	_info("Found {0} .brodata files".format(len(brodata_files)))

	if not brodata_files:
		print "Could not find any .brodata files to parse. Exiting script."
		exit(1)

	## analyze each file, checking it for correctness as well as cleaning out
	## expired entries
	##
	global CURRENT_LINE
	global CURRENT_FILE
	global CURRENT_LINE_NUMBER
	for f in brodata_files:

		_info("Checking file: " + f)

		CURRENT_FILE = f
		CURRENT_LINE = ''
		CURRENT_LINE_NUMBER = 0
		lines = [l.rstrip()for l in open(f, 'r').readlines()]

		if not lines:
			_fail("File is empty!")

		##
		## check for correctness
		##

		## make sure the first line is the separator field
		CURRENT_LINE = lines[0]
		CURRENT_LINE_NUMBER = 0
		expected_sep_line = r'#separator ' + SEPARATOR
		if lines[0] != expected_sep_line:
			_fail('First line of the file was not the expected #separator header')

		## make sure the second line is the #fields field
		##
		CURRENT_LINE = lines[1]
		CURRENT_LINE_NUMBER = 1
		if not CURRENT_LINE.startswith('#fields'):
			_fail('Second line of the file was not the #fields header')

		## make sure the fields has the correct # and type of fields
		##
		fields_data = CURRENT_LINE.split("\t")
		if len(fields_data) != 4:
			_fail("Expected 4 items in #fields header, found {0}".format(len(fields_data)))

		if fields_data[2] != 'source':
			_fail("Third item in #fields line should be 'source'")

		if fields_data[3] != 'date_to_remove':
			_fail("Fourth item in #fields line should be 'date_to_remove'")

		## go through the lines and make sure they are what you would expected
		##
		lines2keep = [ lines[0], lines[1] ]
		for line in lines[2:]:
			CURRENT_LINE = line
			CURRENT_LINE_NUMBER += 1

			## make sure the line isn't empty
			##
			if not line:
				_fail("Empty line, please remove.")

			## make sure the correct number of fields exist and the content is as expected
			##
			line_data = line.split("\t")
			if len(line_data) != 3:
				_fail("Expected 3 items in line, found {0}".format(len(line_data)))

			if any(d == '-' for d in line_data):
				_fail("Found a field containing '-', Bro will interpret this as NULL!")

			if line_data[0].startswith( ('www.','http://', 'https://') ):
				_fail("Data has a leading 'www.' or 'http://' or 'https://', please remove this")

			## check to see if the line should be removed or not
			##
			dtr_string = line_data[2]
			if dtr_string == 'never':
				lines2keep.append(line)
			else:
				try:
					date_info = map(int, dtr_string.split("-"))
					dtr = datetime.date(*date_info)
				except Exception as e:
					print e
					_fail("Error parsing the 'date_to_remove' field: " + dtr_string)

				if dtr > CURRENT_DATE:
					lines2keep.append(line)
				else:
					_info("\tremoving line: " + line)

		## make a copy of the previous file, then create a new file in its place
		##
		if len(lines2keep) != len(lines):
			_info("\tUpdating file: " + f)
			shutil.copyfile(f, f+".backup")

			with open(f, 'w') as new_f:
				for line in lines2keep:
					new_f.write( line + "\n" )

		_pass()


if __name__ == '__main__':
	main()
	print '\nAll files ok!'
