# bro-blackbook

### About

These bro scripts are to allow flexible monitoring for a variety of data (IPs, file hashes, URLs, etc)
based on matching various events created by bro. Each directory corresponds to a certain type of
network event that we would like to monitor for. Addition programs can be written easily using the
template file and fixing the filepaths / logic to throw the specified NOTICE event.

### Installation

Add this directory to your local bro install:

	cd $BRO/share/bro/site/ && git clone https://github.com/compilewithstyle/bro-blackbook.git

Then add the following line to your `local.bro` file:

	@load blackbook

<TODO>

### Extending the script

<TODO>
