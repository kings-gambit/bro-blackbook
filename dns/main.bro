#--------------------------------------------------------------------------------
#	Author:
#		Nicholas Siow | compilewithstyle@gmail.com
#	
#	Description:
#		Reads from a list of blacklisted domains and writes to `blackbook_dns.log`
#		if any seen domains match these blacklists
#--------------------------------------------------------------------------------

@load base/protocols/dns

module BlackbookDns;

#--------------------------------------------------------------------------------
#	Set up variables for the new logging stream
#--------------------------------------------------------------------------------

export
{
	redef enum Log::ID += { LOG };

	redef record DNS::Info += {
		intel_source: string &log &optional;
	};

	global log_blackbook_dns: event ( rec:DNS::Info );
}

#--------------------------------------------------------------------------------
#	Set up variables and types to be used in this script
#--------------------------------------------------------------------------------

type Idx: record
{
	domain: string;
};

type Val: record
{
	source: string;
};

# global blacklist variable that will be synchronized across nodes
global DNS_BLACKLIST: table[string] of Val &synchronized;

#--------------------------------------------------------------------------------
#	Define a function to reconnect to the database and update the blacklist
#--------------------------------------------------------------------------------

function stream_blacklist()
{
	# reset the existing table
	DNS_BLACKLIST = table();

	# add_table call to repopulate the table
	Input::add_table([
		$source=Blackbook::BLACKBOOK_BASEDIR+"/blacklists/domain_blacklist.brodata",
		$name="dnsblacklist",
		$idx=Idx,
		$val=Val,
		$destination=DNS_BLACKLIST,
		$mode=Input::REREAD
		]);
}

#--------------------------------------------------------------------------------
#	Print results of data import to STDOUT -- can remove after testing!
#	FIXME
#--------------------------------------------------------------------------------

event Input::end_of_data( name:string, source:string )
{
	if( name != "dnsblacklist" )
		return;

	print "DNS_BLACKLIST.BRO -----------------------------------------------------";
	print DNS_BLACKLIST;
	print "----------------------------------------------------------------------";

	flush_all();
}

#--------------------------------------------------------------------------------
#	Setup the blacklist stream upon initialization
#--------------------------------------------------------------------------------

event bro_init()
{
	stream_blacklist();
	Log::create_stream(BlackbookDns::LOG, [$columns=DNS::Info, $ev=log_blackbook_dns]);
}

#--------------------------------------------------------------------------------
#	Hook into the normal logging event and create an entry in the blackbook
#	log if the entry meets the desired criteria
#--------------------------------------------------------------------------------

event DNS::log_dns( r:DNS::Info )
{
	if( r?$query )
	{
		local query: string = sub( r$query, /^www\./, "" );

		if( r$qtype == 1 && query in DNS_BLACKLIST )
		{
			r$intel_source = DNS_BLACKLIST[query]$source;
			Log::write( BlackbookDns::LOG, r );
		}
	}
}
