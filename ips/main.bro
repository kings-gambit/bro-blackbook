#--------------------------------------------------------------------------------
#	Author:
#		Nicholas Siow | compilewithstyle@gmail.com
#	
#	Description:
#		Reads from a list of blacklisted IPs and writes to `blackbook_ip.log`
#		if any seen IPs match these blacklists
#--------------------------------------------------------------------------------

@load base/protocols/conn

module BlackbookIp;

#--------------------------------------------------------------------------------
#	Set up variables for the new logging stream
#--------------------------------------------------------------------------------

export
{
	redef enum Log::ID += { LOG };

	redef record Conn::Info += {
		intel_source: string &log &optional;
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

function stream_blacklist()
{
	# reset the existing table
	IP_BLACKLIST = table();

	# add_table call to repopulate the table
	Input::add_table([
		$source=Blackbook::BLACKBOOK_BASEDIR+"/blacklists/ip_blacklist.brodata",
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

	flush_all();
}

#--------------------------------------------------------------------------------
#	Setup the blacklist stream upon initialization
#--------------------------------------------------------------------------------

event bro_init()
{
	stream_blacklist();
	Log::create_stream(BlackbookIp::LOG, [$columns=Conn::Info, $ev=log_blackbook_ip]);
}

#--------------------------------------------------------------------------------
#	Hook into the normal logging event and create an entry in the blackbook
#	log if the entry meets the desired criteria
#--------------------------------------------------------------------------------

event Conn::log_conn( r:Conn::Info )
{
	local intel_source: string = "";

	local orig: addr = r$id$orig_h;
	local resp: addr = r$id$resp_h;

	if( orig in IP_BLACKLIST )
	{
		intel_source = IP_BLACKLIST[orig]$source;
	}
	else if( resp in IP_BLACKLIST )
	{
		intel_source = IP_BLACKLIST[resp]$source;
	}

	if( intel_source != "" )
	{
		r$intel_source = intel_source;
		Log::write( BlackbookIp::LOG, r );
	}
}
