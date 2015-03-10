#--------------------------------------------------------------------------------
#	Author:
#		FIXME add your name and email
#	
#	Description:
#		FIXME add a description for your module
#--------------------------------------------------------------------------------

# FIXME add any outside modules you need here
#@load base/protocols/conn

# FIXME change this to the name of the new module, follow casing example
#module BlackbookIP;

#--------------------------------------------------------------------------------
#	Set up variables for the new logging stream
#--------------------------------------------------------------------------------

export
{
	redef enum Log::ID += { LOG };

	# FIXME add the alert subject string to whatever Info record you want to use
	#redef record Conn::Info += {
	#	alert_subject: string &log &optional;
	#};

	# FIXME change the name of the event so that it doesn't conflict with
	# other logging events.. also change the module of Info
	# to point to the correct type

	#global log_blackbook_ip: event ( rec:Conn::Info );
}

#--------------------------------------------------------------------------------
#	Set up variables and types to be used in this script
#--------------------------------------------------------------------------------

type Idx: record
{
	# FIXME change the name and type of this to the correct fieldname and type
	#ip: addr;
};

type Val: record
{
	# FIXME change the name of type of this to the correct valuename and type
	#source: string;
};

# global blacklist variable that will be synchronized across nodes
# FIXME change the name and table-index type of this variable to
# match with what was listed above
#global IP_BLACKLIST: table[addr] of Val &synchronized;

#--------------------------------------------------------------------------------
#	Define a function to reconnect to the database and update the blacklist
#--------------------------------------------------------------------------------

function stream_ipblacklist()
{
	# reset the existing table
	IP_BLACKLIST = table();

	# add_table call to repopulate the table
	Input::add_table([
		# FIXME change the source the correct filepath
		#$source="/Users/nsiow/Dropbox/code/bro/blackbook/blacklists/ip_blacklist.brodata",
		# FIXME give an arbitrary name to the input stream -- only used for output printing
		#$name="ipblacklist",
		$idx=Idx,
		$val=Val,
		# FIXME make sure that $destination matches the name of the global blacklist
		# declared above
		#$destination=IP_BLACKLIST,
		$mode=Input::REREAD
		]);
}

#--------------------------------------------------------------------------------
#	Print results of data import to STDOUT -- can remove after testing!
#	FIXME
#--------------------------------------------------------------------------------

event Input::end_of_data( name:string, source:string )
{
	# FIXME change this to the name of the input stream specified in Input::add_table
	#if( name != "ipblacklist" )
		return;

	# FIXME change all instances of IP_BLACKLIST to whatever the name of
	# your global blacklist is -- easier to do a find/replace here
	#print "IP_BLACKLIST.BRO -----------------------------------------------------";
	#print IP_BLACKLIST;
	#print "----------------------------------------------------------------------";
}

#--------------------------------------------------------------------------------
#	Setup the blacklist stream upon initialization
#--------------------------------------------------------------------------------

event bro_init()
{
	# FIXME change this to be the correct stream function declared earlier
	# in this file
	stream_ipblacklist();

	# FIXME change the logging ID, info type, and event here to match what you
	# have specified above
	#Log::create_stream(BLACKBOOK::IP, [$columns=Conn::Info, $ev=log_blackbookip]);
}

#--------------------------------------------------------------------------------
#	Hook into the normal logging event and create an entry in the blackbook
#	log if the entry meets the desired criteria
#--------------------------------------------------------------------------------

# FIXME hook into the proper event here and do whatever logic you need to in order
# to trigger on the right event. make sure you set $alert_subject while you're doing
# this and make sure that your function eventually calls Log::write with the correct
# parameters

#event Conn::log_conn( c:Conn::Info )
#{
#	local orig: addr = c$id$orig_h;
#	local resp: addr = c$id$resp_h;
#
#	if( orig in IP_BLACKLIST )
#	{
#		local alert_subject: string = fmt("Connection to blacklisted IP: %s", orig);
#		local new_rec: Conn::Info = c;
#		c$alert_subject = alert_subject;
#		Log::write( BlackbookIP::LOG, new_rec );
#		return;
#	}
#	else if( resp in IP_BLACKLIST )
#	{
#		alert_subject = fmt("Connection to blacklisted IP: %s", resp);
#		new_rec = c;
#		c$alert_subject = alert_subject;
#		Log::write( BlackbookIP::LOG, new_rec );
#		return;
#	}
#}
