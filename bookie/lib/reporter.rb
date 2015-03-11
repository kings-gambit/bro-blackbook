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

# 3rd party

# mine
require_relative './debugger.rb'
require_relative './throttler.rb'

class Reporter

	# create a new debugging object
	@@d = Debugger.new "Reporter"

	def self.send_email( data )
		puts 'here'
	end

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

	def self.usersearch( ts, wustl_ip, wustl_port )
		@@d.debug "Attempting usersearch with info: #{ts} #{wustl_ip} #{wustl_port}"

		return "?"
	end

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
