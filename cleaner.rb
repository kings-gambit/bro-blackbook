#!/usr/bin/env ruby

=begin

	Author:
		Nicholas Siow | compilewithstyle@gmail.com

	Description:
		Script to parse all .brodata files for the bro-blackbook and make
		sure they are all correctly formatted to be read in by bro

		Also performs cleanup duty by removing those lines that are
		past their expiration date

=end

require 'date'
require 'fileutils'
require 'colorize'

_files = []

#--------------------------------------------------------------------------------
#	global variables to make printing file/ln easier
#--------------------------------------------------------------------------------

$time_format = "%Y-%m-%d"
$curr_file, $curr_line, $curr_line_num = nil, nil, nil

#--------------------------------------------------------------------------------
#	helper functions for printing colored output
#--------------------------------------------------------------------------------

def _pass( f )
	puts "[PASS] #{f}".colorize :light_green
end

def _fail( s )
	puts "[FAIL] in file #{$curr_file}, line ##{$curr_line_num}".colorize :light_red
	puts "line: '#{$curr_line}'\n".colorize :light_red
	puts s.colorize :light_red
	exit 1
end

def _info( s )
	puts s.colorize :light_yellow
end

def check( files )
	files.each do |file|
		File.open(file, 'r') do  |f|

			## set variables that should be constant for each line of a file,
			## but different between the various files
			##
			$curr_file = file
			$curr_line = nil
			$curr_line_num = 1
			header = nil
			num_fields = nil
			expected_separator = '#separator \x09'
			dtr_index = nil

			f.each_line do |line|

				line.chomp!
				$curr_line = line

				## make sure the data doesn't have leading http://
				## or www.
				datum = line.split("\t")
				if datum.start_with?( 'http://' ) || datum.start_with?( 'www.' )
					_fail "data item starts with leading http:// or www., please remove"
				end

				## make sure the header is correct
				##
				if $curr_line_num == 1
					if line != expected_separator
						_fail  "invalid separator line, expected #{expected_separator}"
					end
				## parse out the #fields header and determine how many
				## fields each line should have
				##
				elsif $curr_line_num == 2
					if !line.start_with? "#fields"
						_fail  "expected #fields line"
					else
						header = line.split("\t")[1..-1]
						num_fields = header.size
						if !header.include? "date_to_remove"
							_fail "no date_to_remove field in header: #{header}" 
						else
							dtr_index = header.index  'date_to_remove'
						end
					end
				else
					## make sure the line isn't empty
					##
					if line.strip.empty?
						_fail  "found empty line, please remove"
					end

					## make sure the line has the expected number of fields
					##
					this_num_fields = line.split("\t").size
					if this_num_fields != num_fields
						_fail  "expected #{num_fields} fields #{header}, found #{this_num_fields}"
					end

					## make sure the line has a parseable date_to_remove field
					##
					dtr_string = line.split("\t")[dtr_index]

					begin
						unless dtr_string == 'never'
							dtr = Date.strptime( dtr_string, $time_format )
						end
					rescue ArgumentError
						_fail "could not parse date string, please reformat to #{$time_format} or 'never': #{dtr_string}"
					end
				end

				$curr_line_num += 1
			end
		end

		_pass file

	end
end

def clean( files )

	today = Date.today

	files.each do |file|

		lines2keep = []
		lines2remove = []
		dtr_index = nil

		$curr_line_num = 1
		$curr_file = file

		File.open(file, 'r') do |f|

			f.each_line do |line|

				line.chomp!

				## we want to keep the header intact, so add both of those lines
				##
				if $curr_line_num == 1
					lines2keep << line
				elsif $curr_line_num == 2
					dtr_index = line.split("\t")[1..-1].index( 'date_to_remove' )
					lines2keep << line
				else
					dtr = line.split("\t")[dtr_index]

					## keep the line if the expiration date is 'never'
					##
					if dtr == 'never'
						lines2keep << line

					## otherwise, check whether or not its date has passed
					##
					else
						dtr = Date.strptime( line.split("\t")[dtr_index], $time_format )

						if dtr > today
							lines2keep << line
						else
							lines2remove << line
						end
					end
				end

			$curr_line_num += 1

			end
		end

		## if file should be rewritten do it here
		##
		if lines2remove.size > 0
			puts "removed #{lines2remove.size} lines from #{file}".colorize :light_magenta
			lines2remove.each { |l2r| puts "\t'#{l2r}'" }

			File.open( file + ".tmp", 'w' ) { |new_file| new_file.puts lines2keep }

			FileUtils.mv file, file + ".prev"
			FileUtils.mv file + ".tmp", file
		else
			_info "file unchanged: #{file}"
		end
	end
end

#--------------------------------------------------------------------------------
#	main script functionality
#--------------------------------------------------------------------------------

def main

	## parse arguments and make sure they are valid / not asking for help
	##
	if ARGV.size != 0 || ARGV.include?('-h') || ARGV.include?('--help')
		puts 'USAGE: cleaner.rb'
		exit 1
	end

	## find all of the .brodata files under this directory
	##
	brodata_files = Dir.glob "#{File.dirname __FILE__}/**/*.brodata"

	## perform check first to make sure that clean can rely on valid
	## files, then perform the clean. finish with check to make sure that
	## the files are good to go
	##
	puts "-"*60, "CHECKING, FIRST PASS...", "-"*60
	check brodata_files
	puts "-"*60, "CLEANING", "-"*60
	clean brodata_files
	puts "-"*60, "CHECKING, SECOND PASS...", "-"*60
	check brodata_files
	
	puts "-"*60, "DONE", "-"*60

end

if __FILE__ == $0
	main
end
