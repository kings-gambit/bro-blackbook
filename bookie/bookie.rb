#!/usr/bin/env ruby

require 'yaml'
require 'zlib'
require 'json'
require 'securerandom'

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

def usage
	puts "USAGE: bb_reporter.rb [OPTIONS] [FILES...]\n\n"
	puts "OPTIONS:"
	puts "\t-r, --recent\trun on the most recent set of logs"
	exit 1
end

#--------------------------------------------------------------------------------
#	Reporter class which contains the necessary logic and data structures
#	for reporting upon a NOTICE entry
#--------------------------------------------------------------------------------

class Reporter

	##
	## initialization function
	##
	def initialize( mailing_list, throttle_db )
		@mailing_list = mailing_list
		@throttle_db = throttle_db
	end

	def read_throttle
	end

	def write_throttle
	end

	##
	## function that takes in the alert data and returns a 4-item
	## array of wustl_ip, wustl_port, other_ip, and other_port
	##
	def parse_ips( alert )
		ip1 = alert['id.orig_h']
		ip2 = alert['id.resp_h']

		if ip1.nil? || ip2.nil?
			return ip1, ip2
		end

		ips = [ip1, ip2]
		
		wustl_ips = ips.select{ |ip| ip.start_with? '128.252.', '65.254.' }
		other_ips = ips.select{ |ip| !ip.start_with? '128.252.', '65.254.' }

		if wustl_ips.size != 1
			warn "found 2 wustl IPs in #{ip1}, #{ip2}"
			return [ip1, ip2]
		end

		if other_ips.size != 1
			warn "found no wustl IPs in #{ip1}, #{ip2}"
			return [ip1, ip2]
		end

		return wustl_ips.first, other_ips.first
	end

	##
	## usersearch function that will call the full usersearch script
	## living elsewhere on the system
	##
	def usersearch( ts, port, wustl_ip )
		unless wustl_ip.start_with? '128.252.', '65.254.'
			return '?'
		end

		return '?'
	end

	##
	## function to serve as interface between Reporter and main(), takes in a
	## hash of line data and passes it through the workflow of the Reporter
	##
	def report( header, alert )

		# parse the JSON-formatting alert metadata
		begin
			alert_meta = JSON.parse alert['alert_json']
		rescue
			warn "couldn't parse JSON alert info, skipping alert: #{alert['alert_json']}"
		end

		# make sure the alert has a subject specified
		if alert_meta['alert_subject'] == '-'
			warn "alert is missing email subject, skipping: #{alert}"
			return
		end

		# differentiate between the wustl_ip and the other ip
		wustl_ip, other_ip = parse_ips alert

		# if all the required fields exist, perform a usersearch
		user = ''


		# make a temporary email file
		randstr = "/tmp/" + SecureRandom.hex + ".email"
		File.open( randstr, 'w' ) do |f|

			# first, place general/universal info from the alert into the file
			f.puts "Alert subject: #{alert_meta['alert_subject']}"
			f.puts "Alert data source: #{alert_meta['alert_source']}\n\n"
			f.puts "User lookup results: FIXME}"

			# next, place the contents of the line pretty-printed
			header.each do |field|
				f.puts "#{field} = #{alert[field]}"
			end

		end
	end

	private :usersearch
	private :parse_ips
	private :read_throttle
	private :write_throttle

end

def main

	#--------------------------------------------------------------------------------
	# print usage if requested or if arguments are invalid
	#--------------------------------------------------------------------------------

	if ARGV.include?('-h') || ARGV.include?('--help')
		usage
	end

	#--------------------------------------------------------------------------------
	# make sure configuration file exists and read it in
	#--------------------------------------------------------------------------------

	unless File.exist? $config_fp
		err "Could not find YAML configuration file @ #{$config_fp}"
	end

	config = YAML.load_file $config_fp
	debug "continuing with config: #{config}"

	#--------------------------------------------------------------------------------
	# make sure necessary config variables exist and are valid filepaths
	#--------------------------------------------------------------------------------

	['bro_log_dir', 'mailing_list', 'throttle_db'].each do |required|
		unless config.include? required
			err "Config file #{$config_fp} is missing required field: #{required}"
		end
	end

	if config['mailing_list'].class != Array || config['mailing_list'].length == 0
		err "Invalid type or size for mailing list: #{config['mailing_list']}"
	end

	unless File.exist? config['throttle_db']
		err "Could not find specified throttle database: #{config['throttle_db']}"
	end

	#--------------------------------------------------------------------------------
	# make a reporter object using the configuration from the config file
	#--------------------------------------------------------------------------------

	reporter = Reporter.new( config['mailing_list'], config['throttle_db'] )

	#--------------------------------------------------------------------------------
	# make sure some valid logs were specified
	#--------------------------------------------------------------------------------

	logs = []

	##
	## handle case where user requested most recent logs
	##
	if ARGV.include?('-r') || ARGV.include?('--recent')
		logdirs =  Dir.glob(config['bro_log_dir']+"/*-*-*").reverse

		# find the most recent logdir with logs inside
		recent_log_dir = logdirs.find { |dir| !Dir.glob(dir+"/*").empty? }

		if recent_log_dir.nil?
			err "No blackbook logs found in bro dir: #{config['bro_log_dir']}"
		end

		logs = Dir.glob recent_log_dir+"/**/blackbook*.log*"

		if logs.empty?
			err "No blackbook logs found in bro dir: #{config['bro_log_dir']}"
		end
	##
	## handle case where user specifically provided logs
	##
	else
		# select statement to pull out bro logs from the filepath
		logs = ARGV.select { |arg|
			file = arg.split('/').last
			file.start_with?('blackbook') &&
				(file.end_with?('.log') || file.end_with?('.log.gz'))
		}

		if logs.empty?
			err "please either specify logs or run with '--recent' option"
		end

		logs.each do |l|
			err "specified logfile does not exist: #{l}" unless File.exist? l
		end
	end

	debug "continuing with logs: #{logs}"

	#--------------------------------------------------------------------------------
	# go through the notice log file and send each reporting line to the Reporter
	# object
	#--------------------------------------------------------------------------------

	logs.each do |log_fp|

		debug "Parsing log file: #{log_fp}"

		# determine line-reading method based off filetype
		lines = 
		if log_fp.end_with? '.gz'
			Zlib.GzipReader.new(log_fp).readlines
		else
			File.open(log_fp).readlines
		end.map &:chomp

		# find the header of the file
		header = lines.find { |line| line.start_with? '#fields' }.split("\t").slice(1..-1)

		# iterate through the lines and send each to the reporter
		lines.each do |l|
			unless l.start_with? '#'
				linedata = Hash[ header.zip l.split("\t") ]
				linedata['source_file'] = log_fp
				reporter.report header, linedata
			end
		end
	end
end

if __FILE__ == $0
	main
end
