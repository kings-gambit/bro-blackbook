#--------------------------------------------------------------------------------
#	Author:
#		Nicholas Siow | compilewithstyle@gmail.com
#	
#	Descrition:
#		Reads from a list of blacklisted IPs and raises a NOTICE
#		if these connections are seen anywhere
#--------------------------------------------------------------------------------

@load base/protocols/conn
@load base/frameworks/notice

module IP_blacklist;

#--------------------------------------------------------------------------------
#	Set up variables and types to be used in this script
#--------------------------------------------------------------------------------

type Idx: record
{
	blacklisted_ip: addr;
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

# add relevant fields to the Notice::Info type
redef record Notice::Info += {
	history: string &log &optional;
	orig_ip_bytes: count &log &optional;
	resp_ip_bytes: count &log &optional;
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

event connection_state_remove( c:connection )
{
	local ips = set( c$id$orig_h, c$id$resp_h );
	for( ip in ips )
	{
		if( ip in IP_BLACKLIST )
		{
			NOTICE([
				$note=Conn_to_Blacklisted_IP,
				$msg=fmt("Connection to blacklisted IP: <%s>", ip),
				$conn=c,
				$history=c$conn$history,
				$orig_ip_bytes=c$conn$orig_ip_bytes,
				$resp_ip_bytes=c$conn$resp_ip_bytes
				]);
		}
	}
}
