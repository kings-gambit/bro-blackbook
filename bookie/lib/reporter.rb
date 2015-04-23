#--------------------------------------------------------------------------------
#
#	Author:
#		Nicholas Siow | compilewithstyle@gmail.com
#
#	Description:
#		Defines the Reporter class which takes in log line data and
#		checks against a Throttler before sending tne alert via email
#
#--------------------------------------------------------------------------------

# stdlib
require 'fileutils'
require 'securerandom'

# 3rd party
require 'json'

# mine
require_relative './debugger.rb'
require_relative './throttler.rb'

=begin
	Reporter class that organizes the parsed data from Bro logs into an
	email form and sends it. Checks with the Throttler to make sure emails
	are not spammed.
=end
class Reporter

	# create a new debugging object
	@@d = Debugger.new "Reporter"

	# placeholder for the class mailing list
	@@mailing_list

	# Assign the given mailing list to the reporter class to use as TO addresses
	#
	# ==== Params:
	# +mailing_list+ (+Array of String+):: An +Array+ containing the email addresses to be used
	#
	def self.setup( mailing_list, test )
		@@mailing_list = mailing_list
		@@test = test
	end

	# Prints the given data to a temporary file and sends it via MAILX
	#
	# ==== Params:
	# +data+ (+Hash of String->String+):: a data hash containing the info from the Bro log line
	#
	# ==== Note:
	# - The given +data+ hash must contain a properly-formatted +alert_json+ field
	#
	def self.send_email( data )

		# parse the alert info out of the json string
		alert_info = 
		if data['source_file'].include? 'blackbook'
			if data.has_key? 'alert_json'
				parse_alert_json data['alert_json']
			else
				@@d.err "Line data was missing the field 'alert_json': #{data}"
			end
		elsif data['source_file'].include? 'notice'
			{ 'alert_subject' => 'TeamCymru Malware Registry hit', 'alert_source' => 'TeamCymru' }
		elsif data['source_file'].include? 'intel'
			{ 'alert_subject' => 'Bro Intel match', 'alert_source' => data['sources'] }
		else
			@@d.err "Not sure how to get alert info for log: #{data['source_file']}"
		end

		@@d.debug "Prepping email with subject: #{alert_info['alert_subject']}"

		# generate a random string for the email name
		email_file = "/tmp/#{SecureRandom.hex}"
		@@d.debug "\tCreated email file @ #{email_file}"

		# open the file and write the contents of `data`
		File.open( email_file, 'w' ) do |e|
			# add meta information to the top of the email
			e.puts "Subject = #{alert_info['alert_subject']}"
			e.puts "Data source = #{alert_info['alert_source']}"
			e.puts "Source file = #{data.delete 'source_file'}"
			e.puts "User = #{data.delete 'user'}"
			e.puts "\n\n"

			# add the remainder of the alert
			data.each do |field,value|
				e.puts "#{field} = #{value}"
			end
		end

		# send the email
		unless @@test
			# join the recipients into a single string
			rcpt_string = @@mailing_list.join(',')
			@@d.debug "\tSending to recipients: #{rcpt_string}"

			# replace single quotes in subject/recipients that would mess with shell
			alert_info['alert_subject'].gsub! "'", "\\'"
			rcpt_string.gsub! "'", "\\'"

			# create and run the system mailx command
			cmd = "cat #{email_file} | mailx -s '#{alert_info['alert_subject']}' '#{rcpt_string}'"
			@@d.debug "\tRunning command: #{cmd}"
			system cmd
		end

		# delete it!
		FileUtils.rm email_file
		@@d.debug "\tDeleted email: #{email_file}"

		exit
	end

	# Parses the alert_json field to get the alert subject and alert source
	#
	# ==== Params:
	# +alert_json+ (+String+):: a +String+ representing a JSON dict with alert_subject and alert_source fields
	#
	# ==== Retuns:
	# - a hash of String->String representing the data contained in the JSON string
	#
	def self.parse_alert_json( alert_json )

		@@d.debug "Parsing alert json: #{alert_json}"

		begin
			return JSON.parse alert_json
		rescue Exception => e
			@@d.err "Failed to parse alert json: #{alert_json}"
		end

	end

	# Parses the data from the Bro log line and returns the IPs/ports organized by whether or not
	# they correspond to WUSTL hosts
	#
	# ==== Params:
	# +data+ (+Hash of String->String+):: a data hash containing the info from the Bro log line
	#
	# ==== Returns:
	# - a 2-element array in the form of [ wustl_info, other_info ], where each item is the 3-tuple of ts/ip/port
	#   
	def self.get_wustl_info( data )
		
		# go ahead and return nil unless all the required data is present
		unless ['ts', 'id.orig_h', 'id.orig_p', 'id.resp_h', 'id.resp_p'].all? { |x| data.has_key? x }
			return [nil,nil]
		end

		# map each field to its respective value in the data hash
		info1 = [ 'ts', 'id.orig_h', 'id.orig_p' ].map { |x| data[x] }
		info2 = [ 'ts', 'id.resp_h', 'id.resp_p' ].map { |x| data[x] }

		# find the ip starting with the WUSTL subnets and return it
		if info1[1].start_with? '128.252.', '65.254.'
			@@d.debug "Found wustl info: #{info1}"
			@@d.debug "Found other info: #{info2}"
			return [ info1,info2 ]
		elsif info2[1].start_with? '128.252.', '65.254.'
			@@d.debug "Found wustl info: #{info2}"
			@@d.debug "Found other info: #{info1}"
			return [ info2,info1 ]
		else
			@@d.debug "Couldn't find WUSTL info for #{data}"
			return [nil,nil]
		end

	end

	# Takes in WUSTL info and calls an external script to perform a user lookup
	#
	# ==== Params:
	# +ts+ (+String+):: a UNIX-timestamp formatted string representing the time of connection
	# +wustl_ip+ (+String+):: the *external* WUSTL IP
	# +wustl_port+ (+String+):: the *external* WUSTL port
	#
	# ==== Returns:
	# - a +String+ containing the user information
	#
	def self.usersearch( ts, wustl_ip, wustl_port )

		@@d.debug "Attempting usersearch with info: #{ts} #{wustl_ip} #{wustl_port}"
		return "?" #FIXME

	end

	# Takes in a +Hash+ containing the line data and cals #send_email if it passes the Throttler check
	#
	# ==== Params:
	# +data+ (+Hash of String->String+):: a data hash containing the info from the Bro log line
	#
	def self.report( data )
		wustl_info, other_info = get_wustl_info data

		# if the wustl info was successfully retrieved, try a usersearch. otherwise, 
		#   set the user to unknown
		data['user'] = 
		if wustl_info.nil?
			"UNKNOWN"
		else
			usersearch( *wustl_info )
		end

		# pull out the WUSTL ip and throttle tag to see whether or not
		#   this alert should be throttled
		wustl_ip = wustl_info.nil? ? nil : wustl_info[1]
		throttle_tag = data['source_file'].split('/').last.split('.').first

		unless Throttler.should_throttle? wustl_ip, throttle_tag
			send_email( data )
		end
	end

end
