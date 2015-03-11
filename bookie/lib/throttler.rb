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

class Throttler


	# create a new debugging object
	@@d = Debugger.new "Throttler"

	def self.setup( throttle_db_fp )

		# initialize the set of items to throttle
		@@throttle_on = Set.new

		# class instance of the sqlite database handler
		@@db = nil

		# create the database if it doesn't already exist
		if File.file? throttle_db_fp
			@@d.debug "#{throttle_db_fp} exists, using it"
			read_db throttle_db_fp
		else
			@@d.debug "#{throttle_db_fp} does not exist, creating now!"
			Throttler.create_db throttle_db_fp
			read_db throttle_db_fp
		end
		
	end

	def self.create_db( fp )

		@@d.debug "Attempting to create new database at #{fp}"

		create_str = 'create table throttle( ip VARCHAR(15) not null, tag VARCHAR(100) not null, expire_on DATE not null );'

		begin
			SQLite3::Database.new( fp ) do |newdb|
				newdb.execute create_str
			end
		rescue Exception => e
			@@d.err "Failed to make database at #{fp}: #{e}"
		end
		@@d.debug "Succesfully created data at #{fp}"

	end

	def self.read_db( throttle_db_fp )

		# try to connect to the database
		@@d.debug "Attempting to connect to sqlite database: #{throttle_db_fp}"
		begin
			@@db = SQLite3::Database.new throttle_db_fp
		rescue Exception => e
			@@d.err "Failed to connect to database at #{fp}: #{e}"
		end
		@@d.debug "\tSuccess! Connected to sqlite database: #{throttle_db_fp}"

		# try to clean it
		@@d.debug "Attempting to remove old entries from database"
		begin
			@@db.execute 'DELETE FROM throttle WHERE expire_on <= Date(\'now\');'
		rescue Exception => e
			@@d.err "Failed to remove old entries from throttle db: #{e}"
		end
		@@d.debug "\tSuccess! Removed old entries from database: #{throttle_db_fp}"

		# try to read in the table
		@@d.debug "Attempting to read values from databse"
		begin
			rows = @@db.execute 'SELECT * FROM throttle;'
		rescue Exception => e
			@@d.err "Failed to read values from database: #{e}"
		end
		@@d.debug "\tSuccess! Retrieved #{rows.size} values from database: #{throttle_db_fp}"

		rows.each do |row|
			ip, tag, _ = row

			@@throttle_on << [ip,tag]
		end

		@@d.debug "Throttle now has #{@@throttle_on.size} items"

	end

	def self.write_db( item )
		@@d.debug "Attempting to write new throttle item: #{item}"
		begin
			@@db.execute "INSERT INTO throttle VALUES (?, ?, Date('now', '1 days'));", item
		rescue Exception => e
			@@d.debug "\tFailed to insert item: #{item}: #{e}"
		end
		@@d.debug "Success! Wrote item #{item} to throttle database!"
	end

	def self.should_throttle?( wustl_ip, tag )
		if wustl_ip.nil? || tag.nil?
			return false
		end

		item = [ wustl_ip, tag ]

		if @@throttle_on.include? tag
			return true
		else
			@@throttle_on << item
			write_db item
			return false
		end
	end

	at_exit { @@db.close unless @@db.nil? }

end
