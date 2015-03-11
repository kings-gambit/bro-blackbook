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

class Debugger

	@@registered_obj_names = Set.new
	@@color_hash = {}
	@@debug = false
	@@color = false

	#--------------------------------------------------------------------------------
	#	initialization function that sets the object name for that particular
	#	Debugger instance
	#--------------------------------------------------------------------------------

	def initialize( obj_name )

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

		p @@color_hash
	end

	#--------------------------------------------------------------------------------
	#	function to enable debugging for ALL Debugger objects
	#--------------------------------------------------------------------------------

	def debugging_on
		@@debug = true
	end

	#--------------------------------------------------------------------------------
	#	function to enable coloring for ALL Debugger objects
	#--------------------------------------------------------------------------------

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

	def err( msg )
	    puts "[ERROR][#{@obj_name}]: #{msg}".colorize @@color_hash[@obj_name]
	    exit 1
	end
	
	def warn( msg )
		if @@debug
	    	puts "[WARNING][#{@obj_name}]: #{msg}".colorize @@color_hash[@obj_name]
		end
	end
	
	def debug( msg )
		if @@debug
	    	puts "[DEBUG][#{@obj_name}]: #{msg}".colorize @@color_hash[@obj_name]
		end
	end

end
