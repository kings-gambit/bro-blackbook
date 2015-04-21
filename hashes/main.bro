#--------------------------------------------------------------------------------
#	Author:
#		Nicholas Siow | compilewithstyle@gmail.com
#	
#	Description:
#		Reads from a list of blacklisted filehashes and writes to
#		`blackbook_filehash.log` if any seen hashes match these blacklists
#--------------------------------------------------------------------------------

@load base/files/hash
@load base/frameworks/files

module BlackbookFilehash;

#--------------------------------------------------------------------------------
#	Set up variables for the new logging stream
#--------------------------------------------------------------------------------

export
{
	redef enum Log::ID += { LOG };

	redef record Files::Info += {
		alert_json: string &log &optional;
	};

	global log_blackbook_filehash: event ( rec:Files::Info );
}

#--------------------------------------------------------------------------------
#	Set up variables and types to be used in this script
#--------------------------------------------------------------------------------

type Idx: record
{
	filehash: string;
};

type Val: record
{
	source: string;
};

# global blacklist variable that will be synchronized across nodes
global FILEHASH_BLACKLIST: table[string] of Val &synchronized;

#--------------------------------------------------------------------------------
#	Define a function to reconnect to the database and update the blacklist
#--------------------------------------------------------------------------------

function stream_blacklist()
{
	# reset the existing table
	FILEHASH_BLACKLIST = table();

	# add_table call to repopulate the table
	Input::add_table([
		$source=Blackbook::BLACKBOOK_BASEDIR+"/blacklists/filehash_blacklist.brodata",
		$name="filehashblacklist",
		$idx=Idx,
		$val=Val,
		$destination=FILEHASH_BLACKLIST,
		$mode=Input::REREAD
		]);
}

#--------------------------------------------------------------------------------
#	Print results of data import to STDOUT -- can remove after testing!
#	FIXME
#--------------------------------------------------------------------------------

event Input::end_of_data( name:string, source:string )
{
	if( name != "filehashblacklist" )
		return;

	print "FILEHASH_BLACKLIST.BRO -----------------------------------------------";
	print FILEHASH_BLACKLIST;
	print "----------------------------------------------------------------------";
}

#--------------------------------------------------------------------------------
#	Setup the blacklist stream upon initialization
#--------------------------------------------------------------------------------

event bro_init()
{
	stream_blacklist();
	Log::create_stream(BlackbookFilehash::LOG, [$columns=Files::Info, $ev=log_blackbook_filehash]);
}

#--------------------------------------------------------------------------------
#	Hook into the normal logging event and create an entry in the blackbook
#	log if the entry meets the desired criteria
#--------------------------------------------------------------------------------

event Files::log_files( r:Files::Info )
{
    local hash: string;
	local alert_subject: string = "";
	local alert_source: string = "";

    if( r?$md5 )
    {
        hash = r$md5;
        if( hash in FILEHASH_BLACKLIST )
        {
			alert_subject = fmt("Malicious file downloaded: %s", hash);
			alert_source = FILEHASH_BLACKLIST[hash]$source;
        }
    }

    else if( r?$sha1 )
    {
        hash = r$sha1;
        if( hash in FILEHASH_BLACKLIST )
        {
			alert_subject = fmt("Malicious file downloaded: %s", hash);
			alert_source = FILEHASH_BLACKLIST[hash]$source;
        }
    }

    else if( r?$sha256 )
    {
        hash = r$sha256;
        if( hash in FILEHASH_BLACKLIST )
        {
			alert_subject = fmt("Malicious file downloaded: %s", hash);
			alert_source = FILEHASH_BLACKLIST[hash]$source;
        }
    }

	# if a malicious file was found and the alert subject was changed,
	# then log this file
	if( alert_subject != "" ) 
	{
		r$alert_json = fmt( "{ \"alert_subject\": \"%s\", \"alert_source\": \"%s\" }", alert_subject, alert_source );
		Log::write( BlackbookFilehash::LOG, r );
	}
}

