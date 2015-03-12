#--------------------------------------------------------------------------------
#
#	Author:
#		Nicholas Siow | compilewithstyle@gmail.com
#
#	Description:
#		A helper class that allows easy unified logging 
#		and debugging across the many classes used in the
#		bookie.rb script
#
#--------------------------------------------------------------------------------

# stdlib
require 'set'

# 3rd party
require 'colorize'

# mine

$colors = [
	:light_red,
	:light_green,
	:light_yellow,
	:light_blue,
	:light_magenta,
	:light_cyan,
	:red,
	:green,
	:yellow,
	:blue,
	:magenta,
	:cyan,
]

=begin rdoc
	A simple debugging/logging class that allows logging with progname tags and in various colors
=end
class Debugger

	@@registered_obj_names = Set.new
	@@color_hash = {}

	# class variable that determines whether or not debugging should be enabled
	@@debug = false

	# class variable that determines if color should be used
	@@color = false

	#--------------------------------------------------------------------------------
	#	initialization function that sets the object name for that particular
	#	Debugger instance
	#--------------------------------------------------------------------------------

	def initialize( obj_name ) # :nodoc:

		# make sure the object name hasn't been registered already
		if @@registered_obj_names.include? obj_name
			puts "DEBUGGER ERROR: object name already registered: #{obj_name}"
			exit 1
		else
			@@registered_obj_names << obj_name
		end

		# if color was requested, make sure there is still an available color
		if @@color && $colors.empty?
			puts "DEBUGGER ERROR: no more available colors"
			exit 1
		end

		@obj_name = obj_name

		if @@color
			@@color_hash[@obj_name] = colors.shift
		else
			@@color_hash[@obj_name] = :default
		end

	end

	#--------------------------------------------------------------------------------
	#	function to enable debugging for ALL Debugger objects
	#--------------------------------------------------------------------------------

	# Function to turn on debugging for all objects
	#
	def debugging_on
		@@debug = true
	end

	#--------------------------------------------------------------------------------
	#	function to enable coloring for ALL Debugger objects
	#--------------------------------------------------------------------------------

	# Function to turn on colorized logging for all objects
	#
	def color_on
		@@color = true

		# retroactively turn on colors for already-registered objects
		@@registered_obj_names.each do |r|
			@@color_hash[r] = $colors.shift
		end
	end

	#--------------------------------------------------------------------------------
	#	debug printing functions
	#--------------------------------------------------------------------------------

	# Print a message with an [ERROR] tag and exit the program
	#
	# ==== Params:
	# +msg+ (+String+):: the message to be displayed
	#
	def err( msg )
	    puts "[ERROR][#{@obj_name}]: #{msg}".colorize @@color_hash[@obj_name]
	    exit 1
	end
	
	# Print a message with a [WARN] tag if debugging is enabled
	#
	# ==== Params:
	# +msg+ (+String+):: the message to be displayed
	#
	def warn( msg )
		if @@debug
	    	puts "[WARNING][#{@obj_name}]: #{msg}".colorize @@color_hash[@obj_name]
		end
	end
	
	# Print a message with a [DEBUG] tag if debugging is enabled
	#
	# ==== Params:
	# +msg+ (+String+):: the message to be displayed
	#
	def debug( msg )
		if @@debug
	    	puts "[DEBUG][#{@obj_name}]: #{msg}".colorize @@color_hash[@obj_name]
		end
	end

end
