=begin

	Author:
		Nicholas Siow | compilewithstyle@gmail.com

	Description:
		Defines the LogReader class which deals with parsing
		through the given log and converting each line into
		a Field->Value hash

=end

# stdlib
require 'zlib'

# mine

class LogReader


	# create a new debugging object
	@@d = Debugger.new "LogReader"


	def self.parse( logfile )
	
		# read the entire log into memory (faster and
		#   easier to play with, but a little unsafe?)
		lines = 
		if logfile.end_with? '.log.gz'
			Zlib::GzipReader.new( File.open(logfile, 'r') )
		else
			File.open( logfile, 'r' )
		end.lines.map &:chomp

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
		@@d.debug "Found header: #{header}"

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
