#--------------------------------------------------------------------------------
#
#	Author:
#		Nicholas Siow | compilewithstyle@gmail.com
#
#	Description:
#		Defines the LogReader class which deals with parsing
#		through the given log and converting each line into
#		a Field->Value hash
#
#--------------------------------------------------------------------------------

# stdlib
require 'zlib'
require 'mkmf'

# 3rd party

# mine
require_relative './debugger.rb'

=begin
	Log-reading class that handles reading from a Bro log file and turning
	each line into a field->value +Hash+
=end
class LogReader

	@@zcat = nil

	# create a new debugging object
	@@d = Debugger.new "LogReader"

	# Preps the LogReader by looking in the system $PATH variable for a program to
	# read gzip files
	#
	# === Params:
	# => none
	# === Returns:
	# => none
	#
	def self.setup

		options = %w|
			gzcat
			zcat
		|

		while @@zcat.nil?

			zcat_try = find_executable options.shift

			if !zcat_try.nil?
				@@zcat = zcat_try
			end

			if options.empty?
				@@d.err "Could not find program to read .gz files"
			end

		end

	end

	# Parse the given file and return an +Array+ of line data
	#
	# ==== Params:
	# +logfile+ (+String+):: The filepath of the log to be read in
	#
	# ==== Returns:
	# - An +Array+ of String->String +Hashes+ representing the data in the log
	#
	def self.parse( logfile )

		# read the entire log into memory (faster and
		#   easier to play with, but a little unsafe?)
		lines = 
		if logfile.include? 'notice'
			`#{@@zcat} -f #{logfile} | grep TeamCymru`
		else
			`#{@@zcat} -f #{logfile}`
		end.split("\n")

		@@d.debug "Read #{lines.size} lines from file #{logfile}"

		# try to find the header in the lines
		header = lines.find { |line|
			line.start_with? '#fields'
		}

		if header.nil?
			@@d.err "Couldn't find #fields line in file: #{logfile}"
		else
			header = header.split("\t")[1..-1]
		end
		@@d.debug "\tFound header with #{header.size} items"

		data = []

		# read through each line and convert it to a f->v hash
		#   add the filename to the info as you do this
		lines.each do |line|
			unless line.start_with? '#'
				linedata = Hash[ header.zip line.split("\t") ]
				linedata['source_file'] = logfile

				data << linedata
			end
		end

		@@d.debug "Done reading logfile: #{logfile}"

		return data

	end
end
