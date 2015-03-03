#--------------------------------------------------------------------------------
#	Author:
#		Nicholas Siow | compilewithstyle@gmail.com
#	
#	Description:
#		Reads from a list of blacklisted IPs and raises a NOTICE
#		if these connections are seen anywhere
#--------------------------------------------------------------------------------

@load base/protocols/conn

module Blackbook_IP;

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

# create a new notice type
redef enum Notice::Type += {
	Conn_to_Blacklisted_IP
};

#--------------------------------------------------------------------------------
#	Define a function to reconnect to the database and update the blacklist
#--------------------------------------------------------------------------------

function stream_blacklist()
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

	print "IP_BLACKLIST.BRO -----------------------------------------------";
	print "Succesfully imported IP_BLACKLIST:";
	print IP_BLACKLIST;
	print "IP_BLACKLIST.BRO -----------------------------------------------";
}

#--------------------------------------------------------------------------------
#	Setup the blacklist stream upon initialization
#--------------------------------------------------------------------------------

event bro_init()
{
	stream_blacklist();
}

#--------------------------------------------------------------------------------
#	Hook into the CONNECTION_STATE_REMOVE event and raise a notice
#	if any of the IPs are seen
#--------------------------------------------------------------------------------

event Conn::log_conn( c:Conn::Info )
{
	local orig: addr = c$id$orig_h;
	local resp: addr = c$id$resp_h;

	if( orig in IP_BLACKLIST )
	{
		NOTICE([
			$note=Conn_to_Blacklisted_IP,
			$msg=fmt("Connection to blacklisted IP: <%s>", orig),
			$blackbook_source = IP_BLACKLIST[orig]$source,
			$blackbook_record = fmt("%s", c)
			]);
		return;
	}
	else if( resp in IP_BLACKLIST )
	{
		NOTICE([
			$note=Conn_to_Blacklisted_IP,
			$msg=fmt("Connection to blacklisted IP: <%s>", resp),
			$blackbook_source = IP_BLACKLIST[resp]$source,
			$blackbook_record = fmt("%s", c)
			]);
		return;
	}
}
