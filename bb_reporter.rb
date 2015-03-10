#!/usr/bin/env ruby

=begin

	Author:
		Nicholas Siow | compilewithstyle@gmail.com

	Description:
		Reads through the Notice log and generates email alerts based on
		lines created by the NSO Bro Blackbook

=end

#--------------------------------------------------------------------------------
#	global variables to be used within the script
#--------------------------------------------------------------------------------

$config_fp = "/Users/nsiow/Dropbox/code/bro/blackbook/etc/config.yml"
$debug = true

#--------------------------------------------------------------------------------
#	debugging helper functions
#--------------------------------------------------------------------------------

def err( msg )
	puts "[ERROR]: #{msg}"
	exit 1
end

def warn( msg )
	puts "[WARNING]: #{msg}" if $debug
end

def debug( msg )
	puts "[DEBUG]: #{msg}" if $debug
end

#--------------------------------------------------------------------------------
#	Reporter class which contains the necessary logic and data structures
#	for reporting upon a NOTICE entry
#--------------------------------------------------------------------------------

class Reporter

	##
	## function to parse a Bro record and translate it into a ruby hash
	##
	def parse_record( rstring )
	end

	##
	## function to send an email to everyone on the mailing list
	##
	def send( alert_data ) 
	end

	##
	## function to serve as interface between Reporter and main(), takes in a
	## hash of line data and passes it through the workflow of the Reporter
	##
	def report( alert_data )
	end

	private :parse_record
	private :send
end

def main

	##
	##
	##
end

if __FILE__ == $0
	main
end
