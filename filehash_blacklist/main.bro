#--------------------------------------------------------------------------------
#	Author:
#		Nicholas Siow | compilewithstyle@gmail.com
#	
#	Description:
#		Looks for MD5 / SHA1 / SHA256 hashes in the flow of files
#		across the network
#--------------------------------------------------------------------------------

@load base/files/hash
@load base/frameworks/files

module Blackbook_FILES;

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

# create a new notice type
redef enum Notice::Type += {
	Blacklisted_File_Downloaded
};

#--------------------------------------------------------------------------------
#	Define a function to reconnect to the database and update the blacklist
#--------------------------------------------------------------------------------

function stream_blacklist()
{
	# reset the existing table
	FILEHASH_BLACKLIST = table();

	# add_table call to repopulate the table
	Input::add_table([
		$source="/Users/nsiow/Dropbox/code/bro/blackbook/blacklists/filehash_blacklist.brodata",
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
		print "Succesfully imported FILEHASH_BLACKLIST:";
		print FILEHASH_BLACKLIST;
		print "FILEHASH_BLACKLIST.BRO -----------------------------------------------";
}

#--------------------------------------------------------------------------------
#	Setup the blacklist stream upon initialization
#--------------------------------------------------------------------------------

event bro_init()
{
	stream_blacklist();
}

#--------------------------------------------------------------------------------
#	Hook into the LOG_FILES event and raise a notice
# if any of the specified filehashes are seen
#--------------------------------------------------------------------------------

event Files::log_files( r:Files::Info )
{
	local hash: string;

	if( r?$md5 )
	{
		hash = r$md5;
		if( hash in FILEHASH_BLACKLIST )
		{
			NOTICE([
				$note=Blacklisted_File_Downloaded,
				$msg=fmt("Download of malicious file: <%s>", hash),
				$blackbook_source = FILEHASH_BLACKLIST[hash]$source,
				$blackbook_record = fmt("%s", r)
				]);
			return;
		}
	}

	if( r?$sha1 )
	{
		hash = r$sha1;
		if( hash in FILEHASH_BLACKLIST )
		{
			NOTICE([
				$note=Blacklisted_File_Downloaded,
				$msg=fmt("Download of malicious file: <%s>", hash),
				$blackbook_source = FILEHASH_BLACKLIST[hash]$source,
				$blackbook_record = fmt("%s", r)
				]);
			return;
		}
	}

	if( r?$sha256 )
	{
		hash = r$sha256;
		if( hash in FILEHASH_BLACKLIST )
		{
			NOTICE([
				$note=Blacklisted_File_Downloaded,
				$msg=fmt("Download of malicious file: <%s>", hash),
				$blackbook_source = FILEHASH_BLACKLIST[hash]$source,
				$blackbook_record = fmt("%s", r)
				]);
			return;
		}
	}
}


