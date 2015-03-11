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

# mine
require_relative './debugger.rb'

class ArgParser


	@@d = Debugger.new "ArgParser"


	def self.parse_args
    	options = OpenStruct.new
		options.files = []
		options.color = false
		options.debug = false
		options.use_recent = false

    	OptionParser.new do |opts|
    	    opts.banner = "Usage: bookie.rb [OPTIONS]"

    	    opts.on( '-f f1,f2,...', '--files f1,f2,...', Array, 'List of blackbook logs to process' ) do |files|
    	        options.files = files
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
