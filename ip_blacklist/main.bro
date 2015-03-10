#--------------------------------------------------------------------------------
#	Author:
#		Nicholas Siow | compilewithstyle@gmail.com
#	
#	Description:
#		Reads from a list of blacklisted IPs and writes to `blackbook_ip.log`
#		if any seen IPs match these blacklists
#--------------------------------------------------------------------------------

@load base/protocols/conn

module BlackbookIP;

#--------------------------------------------------------------------------------
#	Set up variables for the new logging stream
#--------------------------------------------------------------------------------

export
{
	redef enum Log::ID += { LOG };

	redef record Conn::Info += {
		alert_subject: string &log &optional;
	};

	global log_blackbook_ip: event ( rec:Conn::Info );
}

#--------------------------------------------------------------------------------
#	Set up variables and types to be used in this script
#--------------------------------------------------------------------------------

type Idx: record
{
	ip: addr;
};

type Val: record
{
	source: string;
};

# global blacklist variable that will be synchronized across nodes
global IP_BLACKLIST: table[addr] of Val &synchronized;

#--------------------------------------------------------------------------------
#	Define a function to reconnect to the database and update the blacklist
#--------------------------------------------------------------------------------

function stream_ipblacklist()
{
	# reset the existing table
	IP_BLACKLIST = table();

	# add_table call to repopulate the table
	Input::add_table([
		$source="/Users/nsiow/Dropbox/code/bro/blackbook/blacklists/ip_blacklist.brodata",
		$name="ipblacklist",
		$idx=Idx,
		$val=Val,
		$destination=IP_BLACKLIST,
		$mode=Input::REREAD
		]);
}

#--------------------------------------------------------------------------------
#	Print results of data import to STDOUT -- can remove after testing!
#	FIXME
#--------------------------------------------------------------------------------

event Input::end_of_data( name:string, source:string )
{
	if( name != "ipblacklist" )
		return;

	print "IP_BLACKLIST.BRO -----------------------------------------------------";
	print IP_BLACKLIST;
	print "----------------------------------------------------------------------";
}

#--------------------------------------------------------------------------------
#	Setup the blacklist stream upon initialization
#--------------------------------------------------------------------------------

event bro_init()
{
	stream_ipblacklist();
	Log::create_stream(BlackbookIP::LOG, [$columns=Conn::Info, $ev=log_blackbook_ip]);
}

#--------------------------------------------------------------------------------
#	Hook into the normal logging event and create an entry in the blackbook
#	log if the entry meets the desired criteria
#--------------------------------------------------------------------------------

event Conn::log_conn( c:Conn::Info )
{
	local orig: addr = c$id$orig_h;
	local resp: addr = c$id$resp_h;

	if( orig in IP_BLACKLIST )
	{
		local alert_subject: string = fmt("Connection to blacklisted IP: %s", orig);
		local new_rec: Conn::Info = c;
		c$alert_subject = alert_subject;
		Log::write( BlackbookIP::LOG, new_rec );
		return;
	}
	else if( resp in IP_BLACKLIST )
	{
		alert_subject = fmt("Connection to blacklisted IP: %s", resp);
		new_rec = c;
		c$alert_subject = alert_subject;
		Log::write( BlackbookIP::LOG, new_rec );
		return;
	}
}
