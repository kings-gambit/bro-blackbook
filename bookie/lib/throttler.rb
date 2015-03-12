#--------------------------------------------------------------------------------
#
#	Author:
#		Nicholas Siow | compilewithstyle@gmail.com
#
#	Description:
#		Defines the Throttler class which reads from the throttling
#		database and allows the Reporter class to determine whether
#		or not an email should be sent (to prevent spam)
#
#--------------------------------------------------------------------------------

# stdlib
require 'set'

# 3rd party
require 'sqlite3'

# mine
require_relative './debugger.rb'

=begin rdoc
	Throttler class to limit the amount of duplicate/similar emails that are being sent out.
	The Reporter class will check in with this before sending out an email.
=end
class Throttler

	# create a new debugging object for the Throttler class
	@@d = Debugger.new "Throttler"

	# Connects the Throttler class to the database and reads in the throttle-table
	#
	# ==== Params:
	# +throttle_db_fp+ (+String+):: The filepath to the throttle database as given in the config file
	#
	def self.setup( throttle_db_fp )

		# initialize the set of items to throttle
		@@throttle_on = Set.new

		# class instance of the sqlite database handler
		@@db = nil

		# if the database exists, use it! otherwise, try to create an empty
		#   throttle database
		if File.file? throttle_db_fp
			@@d.debug "#{throttle_db_fp} exists, using it"
			read_db throttle_db_fp
		else
			@@d.debug "#{throttle_db_fp} does not exist, creating now!"
			Throttler.create_db throttle_db_fp
			read_db throttle_db_fp
		end
		
	end

	# If the database does not exist, thie function is privately called to try to create it
	#
	# ==== Params
	# +fp+ (+String+):: The filepath destination for the database to be created
	#
	def self.create_db( fp )
		@@d.debug "Attempting to create new database at #{fp}"

		# define the string to be used for new database creation
		create_str = 'create table throttle( ip VARCHAR(15) not null, tag VARCHAR(100) not null, expire_on DATE not null );'

		# try to apply the creation command to a new database at the specified filepath,
		#   throw exception if this fails
		begin
			SQLite3::Database.new( fp ) do |newdb|
				newdb.execute create_str
			end
		rescue Exception => e
			@@d.err "Failed to make database at #{fp}: #{e}"
		end

		@@d.debug "Succesfully created data at #{fp}"
	end

	# Connect to the database at the specified filepath and try to read its contents
	# into a throttle-table
	#
	# ==== Params:
	# +throttle_db_fp+ (+String+):: The filepath for the database to be connected to
	#
	def self.read_db( throttle_db_fp )

		# try to connect to the database, fail otherwise
		@@d.debug "Attempting to connect to sqlite database: #{throttle_db_fp}"
		begin
			@@db = SQLite3::Database.new throttle_db_fp
		rescue Exception => e
			@@d.err "Failed to connect to database at #{fp}: #{e}"
		end
		@@d.debug "\tSuccess! Connected to sqlite database: #{throttle_db_fp}"

		# try to remove expired items, fail otherwise
		@@d.debug "Attempting to remove old entries from database"
		begin
			@@db.execute 'DELETE FROM throttle WHERE expire_on <= Date(\'now\');'
		rescue Exception => e
			@@d.err "Failed to remove old entries from throttle db: #{e}"
		end
		@@d.debug "\tSuccess! Removed old entries from database: #{throttle_db_fp}"

		# try to read in the table, fail otherwise
		@@d.debug "Attempting to read values from databse"
		begin
			rows = @@db.execute 'SELECT * FROM throttle;'
		rescue Exception => e
			@@d.err "Failed to read values from database: #{e}"
		end
		@@d.debug "\tSuccess! Retrieved #{rows.size} values from database: #{throttle_db_fp}"

		# for each row, read in the ip and tag (ignore the expire date) and build a Set
		# from the data
		rows.each do |row|
			ip, tag, _ = row
			@@throttle_on << [ip,tag]
		end

		@@d.debug "Throttle now has #{@@throttle_on.size} items"

	end

	# Writes a new throttling item to the database
	#
	# ==== Params:
	# +wustl_ip+ (+String+):: the IP (as a string) of the WUSTL address to throttle on
	# +tag+ (+String+):: a string describing the type of incident to throttle on
	#
	def self.write_db( wustl_ip, tag )
		@@d.debug "Attempting to write new throttle item: #{wustl_ip},#{tag}"
		begin
			@@db.execute "INSERT INTO throttle VALUES (?, ?, Date('now', '1 days'));", wustl_ip, tag
		rescue Exception => e
			@@d.debug "\tFailed to insert item: #{wustl_ip},#{tag}: #{e}"
		end
		@@d.debug "Success! Wrote item #{wustl_ip},#{tag} to throttle database!"
	end

	# Function to determine whether or not an item should be throttled. If so, then it returns
	# true and performs no other action. If not, then it returns false and lets the item
	# go by but then adds it to the current throttle set as well as the database
	#
	# ==== Params:
	# +wustl_ip+ (+String+):: the IP (as a string) of the WUSTL address to throttle on
	# +tag+ (+String+):: a string describing the type of incident to throttle on
	#
	# ==== Returns:
	# - +true+ or +false+ based on whether or not the given item should be throttled
	#
	def self.should_throttle?( wustl_ip, tag )
		if wustl_ip.nil? || tag.nil?
			return false
		end

		item = [ wustl_ip, tag ]

		if @@throttle_on.include? tag
			return true
		else
			@@throttle_on << item
			write_db wustl_ip, tag
			return false
		end
	end

end
