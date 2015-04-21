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
#module BlackbookIp;

#--------------------------------------------------------------------------------
#	Set up variables for the new logging stream
#--------------------------------------------------------------------------------

export
{
	redef enum Log::ID += { LOG };

	# FIXME add the alert info string to whatever Info record you want to use
	#redef record Conn::Info += {
		alert_json: string &log &optional;
	};

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

function stream_blacklist()
{
	# reset the existing table
	# FIXME change this to the name of the global blacklist
	#IP_BLACKLIST = table();

	# add_table call to repopulate the table
	Input::add_table([
		# FIXME change the source the correct filepath
		#$source=Blackbook::BLACKBOOK_BASEDIR+"/Users/nsiow/Dropbox/code/bro/blackbook/blacklists/ip_blacklist.brodata",
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

	flush_all();
}

#--------------------------------------------------------------------------------
#	Setup the blacklist stream upon initialization
#--------------------------------------------------------------------------------

event bro_init()
{
	stream_blacklist();

	# FIXME change the logging ID, info type, and event here to match what you
	# have specified above
	#Log::create_stream(BlackbookIp::LOG, [$columns=Conn::Info, $ev=log_blackbook_ip]);
}

#--------------------------------------------------------------------------------
#	Hook into the normal logging event and create an entry in the blackbook
#	log if the entry meets the desired criteria
#--------------------------------------------------------------------------------

# FIXME hook into the proper event here and do whatever logic you need to in order
# to trigger on the right event. make sure you set $alert_subject while you're doing
# this and make sure that your function eventually calls Log::write with the correct
# parameters

#event Conn::log_conn( r:Conn::Info )
#{
#    local alert_subject: string = "";
#    local alert_source: string = "";
#
#    local orig: addr = r$id$orig_h;
#    local resp: addr = r$id$resp_h;
#
#    if( orig in IP_BLACKLIST )
#    {
#        alert_subject = fmt("Connection to blacklisted IP: %s", orig);
#        alert_source = IP_BLACKLIST[orig]$source;
#    }
#    else if( resp in IP_BLACKLIST )
#    {
#        alert_subject = fmt("Connection to blacklisted IP: %s", resp);
#        alert_source = IP_BLACKLIST[resp]$source;
#    }
#
#    if( alert_subject != "" )
#    {
#        r$alert_json = fmt( "{ \"alert_subject\": \"%s\", \"alert_source\": \"%s\" }", alert_subject, alert_source );
#        Log::write( BlackbookIp::LOG, r );
#    }
#}
