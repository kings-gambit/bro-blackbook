#!/usr/bin/env ruby

# stdlib
require 'optparse'

# 3rd party

# mine
require_relative './lib/reporter.rb'
require_relative './lib/log_finder.rb'
require_relative './lib/config_parser.rb'
require_relative './lib/debugger.rb'
require_relative './lib/arg_parser.rb'
require_relative './lib/log_reader.rb'
require_relative './lib/throttler.rb'

#--------------------------------------------------------------------------------
#	global variables
#--------------------------------------------------------------------------------

$debug = false

#--------------------------------------------------------------------------------
#	main program function
#--------------------------------------------------------------------------------

def main

	# parse the provided options
	args = ArgParser.parse_args

	# create a debugging object for main and set its debugging value
	#   appropriately (note that this will affect debugging for the
	#   entire class)
	d = Debugger.new "Main"
	d.debugging_on if args.debug
	d.color_on if args.color
	d.debug "Received arguments: #{args}"

	# read in configuration file
	base_dir = File.expand_path( File.dirname __FILE__ )
	config = ConfigParser.get_config base_dir

	# based on received options, either verify the specified logs or
	#   try to locate the most recent logs
	logs =
	if args.use_recent
		LogFinder.find_recent_logs config['bro_log_dir']
	else
		LogFinder.verify_logs args.files
	end

	# set up the Throttler class with the throttle database filepath
	#   given in the configuration
	Throttler.setup config['throttle_db']

	# set up the Reporter class with the throttle database filepath
	#   given in the configuration
	Reporter.setup config['mailing_list']

	# iterate through the logs and have LogReader parse each of them.
	#   send the results to the Reporter class
	logs.each do |log|
		data = LogReader.parse log

		data.each do |datum|
			Reporter.report datum
		end
	end

end

main if __FILE__ == $0
