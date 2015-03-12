#--------------------------------------------------------------------------------
#
#		Author:
#			Nicholas Siow | compilewithstyle@gmail.com
#
#		Description:
#			Custom argument parser that checks for existence/
#			validity of required arguments
#
#--------------------------------------------------------------------------------

# stdlib
require 'optparse'
require 'ostruct'

# 3rd party

# mine
require_relative './debugger.rb'

=begin rdoc
	ArgParser class to handle parsing options and arguments given via the command-line interface
=end
class ArgParser


	@@d = Debugger.new "ArgParser"

	# Parses ARGV to determine various runtime configuration options
	#
	# ==== Returns:
	# - An OpenStruct object containing the configuration variables
	#
	def self.parse_args
    	options = OpenStruct.new
		options.files = []
		options.test = false
		options.color = false
		options.debug = false
		options.use_recent = false

    	OptionParser.new do |opts|
    	    opts.banner = "Usage: bookie.rb [OPTIONS]"

    	    opts.on( '-f f1,f2,...', '--files f1,f2,...', Array, 'List of blackbook logs to process' ) do |files|
    	        options.files = files
    	    end

    	    opts.on( '-t', '--test', 'Run for testing purposes -- no emails will be sent' ) do |test|
    	        options.test = test
    	    end

    	    opts.on( '-d', '--debug', 'Turn on program debugging' ) do |debug|
    	        options.debug = debug
    	    end

    	    opts.on( '-r', '--use-recent', 'Use the most recent set of logs' ) do |use_recent|
    	        options.use_recent = use_recent
    	    end

			opts.on( '-c', '--color', 'Use color in debugging statements' ) do |color|
				options.color = color
			end

    	    opts.on( '-h', '--help', 'Print this message and exit' ) do |help|
    	        puts opts
    	        exit 1
    	    end

    	    if ARGV.size == 0
    	        puts opts
    	        exit 1
    	    end
    	end.parse!

		# make sure either -f or -r was specified
		if !options.use_recent && options.files.empty?
			@@d.err "Please either specify files to run against or use the '-r' flag"
		end

		return options
	end

end
