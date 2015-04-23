#--------------------------------------------------------------------------------
#
#	Author:
#		Nicholas Siow | compilewithstyle@gmail.com
#
#	Description:
#		Defines the LogFinder class for finding/verifying the logs to be used
#		in the bookie.rb script. Makes sure that the logs exist and contains
#		logic for finding the most recent logs if requested
#
#--------------------------------------------------------------------------------

# stdlib

# mine
require_relative './debugger'

class LogFinder

	# create a new debugging object
	@@d = Debugger.new "LogFinder"

	def self.find_recent_logs( bro_log_dir )

		# use glob to find the list of bro log directories
		globstr = "#{bro_log_dir}/*-*-*"
		logdirs = Dir.glob(globstr).reverse # reverse so that more recent comes first

		# find the most recent one that has some contents
		#   (this avoids reading from an empty directory that Bro hasn't logged to yet)
		most_recent = logdirs.find { |dir|
			Dir.glob("#{dir}/*").any?
		}
		@@d.debug "Using most recent log dir: #{most_recent}"

		# find the most recent hour timestamp in those logs
		all_logs = Dir.glob "#{most_recent}/*"
		@@d.debug "Found #{all_logs.size} logs in directory"
		max_ts = all_logs.map { |log|
			if log.split("/").last =~ /^\w+\.(\d+)/
				$1.to_i
			else
				-1
			end
		}.max
		@@d.debug "Found max ts: #{max_ts}"

		# find all blackbook logs with the given timestamp
		globstr = "#{most_recent}/blackbook*#{max_ts}*-*"
		bb_logs = Dir.glob globstr
		@@d.debug "Found blackbook logs: #{bb_logs}"

		# find all intel logs with the given timestamp
		globstr = "#{most_recent}/intel*#{max_ts}*-*"
		intel_logs = Dir.glob globstr
		@@d.debug "Found intel logs: #{intel_logs}"

		# find all notice logs with the given timestamp
		globstr = "#{most_recent}/notice*#{max_ts}*-*"
		notice_logs = Dir.glob globstr
		@@d.debug "Found notice logs: #{notice_logs}"

		# concatenate the list of logs
		log_list = bb_logs + intel_logs + notice_logs
		@@d.debug "Found overall log list: #{log_list}"

		# return the list of logs to process
		return log_list

	end

	def self.verify_logs( logs )
		logs.each do |l|
			# make sure the given log exists
			unless File.exist? l
				@@d.err "Specified log does not exist: #{l}"
			end
			
			# TODO -- use regex to verify that the log filename
			# looks more or less correct
		end

		return logs
	end

end
