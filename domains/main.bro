#--------------------------------------------------------------------------------
#	Author:
#		Nicholas Siow | compilewithstyle@gmail.com
#	
#	Description:
#		Reads from a list of blacklisted domains and writes to
#		`blackbook_domain.log` if any seen domains match that blacklist
#--------------------------------------------------------------------------------

@load base/protocols/http

module BlackbookDomain;

#--------------------------------------------------------------------------------
#	Set up variables for the new logging stream
#--------------------------------------------------------------------------------

export
{
	redef enum Log::ID += { LOG };

	redef record HTTP::Info += {
		alert_json: string &log &optional;
	};

	global log_blackbook_domain: event ( rec:HTTP::Info );
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
global DOMAIN_BLACKLIST: table[string] of Val &synchronized;

#--------------------------------------------------------------------------------
#	Define a function to reconnect to the database and update the blacklist
#--------------------------------------------------------------------------------

function stream_blacklist()
{
	# reset the existing table
	DOMAIN_BLACKLIST = table();

	# add_table call to repopulate the table
	Input::add_table([
		$source=Blackbook::BLACKBOOK_BASEDIR+"/blacklists/domain_blacklist.brodata",
		$name="domainblacklist",
		$idx=Idx,
		$val=Val,
		$destination=DOMAIN_BLACKLIST,
		$mode=Input::REREAD
		]);
}

#--------------------------------------------------------------------------------
#	Print results of data import to STDOUT -- can remove after testing!
#	FIXME
#--------------------------------------------------------------------------------

event Input::end_of_data( name:string, source:string )
{
	if( name != "domainblacklist" )
		return;

	print "DOMAIN_BLACKLIST.BRO -----------------------------------------------------";
	print DOMAIN_BLACKLIST;
	print "----------------------------------------------------------------------";
}

#--------------------------------------------------------------------------------
#	Setup the blacklist stream upon initialization
#--------------------------------------------------------------------------------

event bro_init()
{
	stream_blacklist();
	Log::create_stream(BlackbookDomain::LOG, [$columns=HTTP::Info, $ev=log_blackbook_domain]);
}

#--------------------------------------------------------------------------------
#	Hook into the normal logging event and create an entry in the blackbook
#	log if the entry meets the desired criteria
#--------------------------------------------------------------------------------

event HTTP::log_http( r:HTTP::Info )
{
    if( r?$host )
    {
        # clean leading/trailing characters from the host
        local host: string = sub( r$host, /^www\./, "" );

        if( host in DOMAIN_BLACKLIST )
        {
			local alert_subject: string = fmt("Malicious domain visited: %s", host);
			local alert_source: string = DOMAIN_BLACKLIST[host]$source;
			r$alert_json = fmt( "{ \"alert_subject\": \"%s\", \"alert_source\": \"%s\" }", alert_subject, alert_source );

			Log::write( BlackbookDomain::LOG, r );
        }
    }
}
