class Debugger

	@@debug = false

	def initialize( obj_name )
		@obj_name = obj_name
	end

	def debugging_on
		@@debug = true
	end

	def err( msg )
	    puts "[ERROR][#{@obj_name}]: #{msg}"
	    exit 1
	end
	
	def warn( msg )
		if @@debug
	    	puts "[WARNING][#{@obj_name}]: #{msg}"
		end
	end
	
	def debug( msg )
		if @@debug
	    	puts "[DEBUG][#{@obj_name}]: #{msg}"
		end
	end

end
