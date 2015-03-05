#--------------------------------------------------------------------------------
#	Author:
#		Nicholas Siow | compilewithstyle@gmail.com
#	
#	Description:
#		Checks the URL of each web connection and raises a NOTICE if
#		any of them match one of the blacklisted URLs
#--------------------------------------------------------------------------------

@load base/protocols/http

module Blackbook_URL;

#--------------------------------------------------------------------------------
#	Set up variables and types to be used in this script
#--------------------------------------------------------------------------------

type Idx: record
{
	url: string;
};

type Val: record
{
	source: string;
};

# global blacklist variable that will be synchronized across nodes
# global IP_BLACKLIST: table[addr] of Val &synchronized;
global URL_BLACKLIST: table[string] of Val &synchronized;

# create a new notice type
redef enum Notice::Type += {
	Blacklisted_URL_Visited
};

#--------------------------------------------------------------------------------
#	Define a function to reconnect to the database and update the blacklist
#--------------------------------------------------------------------------------

function stream_blacklist()
{
	# reset the existing table
	URL_BLACKLIST = table();

	# add_table call to repopulate the table
	Input::add_table([
		$source="/Users/nsiow/Dropbox/code/bro/blackbook/blacklists/url_blacklist.brodata",
		$name="urlblacklist",
		$idx=Idx,
		$val=Val,
		$destination=URL_BLACKLIST,
		$mode=Input::REREAD
		]);
}

#--------------------------------------------------------------------------------
#	Print results of data import to STDOUT -- can remove after testing!
#	FIXME
#--------------------------------------------------------------------------------

event Input::end_of_data( name:string, source:string )
{
		if( name != "urlblacklist" )
			return;

		print "URL_BLACKLIST.BRO -----------------------------------------------";
		print "Succesfully imported URL_BLACKLIST:";
		print URL_BLACKLIST;
		print "URL_BLACKLIST.BRO -----------------------------------------------";
}

#--------------------------------------------------------------------------------
#	Setup the blacklist stream upon initialization
#--------------------------------------------------------------------------------

event bro_init()
{
	stream_blacklist();
}

#--------------------------------------------------------------------------------
#	Hook into the LOG_HTTP event and raise a notice
#	if any of the URLs
#--------------------------------------------------------------------------------

event HTTP::log_http( r:HTTP::Info )
{
	if( r?$host && r?$uri )
	{
		# clean leading/trailing characters from the host
		local host: string = r$host;
		host = sub( host, /^http:\/\//, "" );
		host = sub( host, /^www\./, "" );

		# concatenate the host and uri to create a full URL string
		local url: string = string_cat( host, r$uri );

		if( host in URL_BLACKLIST )
		{
			NOTICE([
				$note=Blacklisted_URL_Visited,
				$msg=fmt("Blacklisted url visited: %s", host),
				$blackbook_source = URL_BLACKLIST[host]$source,
				$blackbook_record = fmt("%s", r)
				]);
			return;
		}
		else if( url in URL_BLACKLIST )
		{
			NOTICE([
				$note=Blacklisted_URL_Visited,
				$msg=fmt("Blacklisted url visited: %s", url),
				$blackbook_source = URL_BLACKLIST[url]$source,
				$blackbook_record = fmt("%s", r)
				]);
			return;
		}
	}
}
