#--------------------------------------------------------------------------------
#
#	Author:
#		Nicholas Siow | compilewithstyle@gmail.com
#
#	Description:
#		Defines the ConfigParser class to find/parse the configuration file
#		for the bookie.rb script and make sure the values are existent/valid
#
#--------------------------------------------------------------------------------

# stdlib
require 'yaml'

# mine
require_relative './debugger.rb'
require_relative './throttler.rb'

class ConfigParser


	@@d = Debugger.new "ConfigParser"


	def self.get_config( base_dir )

		@@d.debug "Looking for configuration files in base dir: #{base_dir}"
		
		# use glob to find all possible configuration files
		possible_configs = Dir.glob "#{base_dir}/**/config.yml"

		# make sure 1 and only 1 config file exists
		config_file = 
		if possible_configs.empty?
			@@d.err "Couldn't find a 'config.yml' file in base directory: #{basedir}"
		elsif possible_configs.size > 1
			@@d.err "Found multiple configuration files: #{possible_configs}"
		else
			possible_configs.first
		end

		# try to read it in
		begin
			config = YAML.load_file config_file
		rescue Exception => e
			@@d.err "Could not load config file '#{config_file}': #{e}"
		end

		# make sure the config is a YAML hash
		unless config.class == Hash
			@@d.err "Given configuration is not a hash as expected: #{config}"
		end

		# make sure it has all the required fields
		['bro_log_dir', 'mailing_list', 'max_alerts', 'throttle_db'].each do |req|
			unless config.has_key? req
				@@d.err "Config file '#{config_file}' is missing required field: #{req}"
			end
		end

		# make sure all fields have valid values
		unless File.directory? config['bro_log_dir']
			@@d.err "Config variable 'bro_log_dir' is not a directory: #{config['bro_log_dir']}"
		end

		unless config['mailing_list'].class == Array
			@@d.err "Config variable 'mailing_list' is not an array as expected: #{config['mailing_list']}"
		end

		config['mailing_list'].each do |rcpt|
			unless rcpt =~ /^\S+@\S+\.\S+$/
				@@d.err "Invalid email address in config_file '#{config_file}': #{rcpt}"
			end
		end

		unless config['max_alerts'].class == Fixnum
			@@d.err "Config variable 'max_alerts' is not an integer as expected: #{config['max_alerts']}"
		end

		@@d.debug "Loaded configuration: #{config}"

		# return the configuration hash
		return config
		
	end

end
