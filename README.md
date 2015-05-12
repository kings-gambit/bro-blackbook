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

You then need to change the filepath in `config.bro` to match the base blackbook directory
for your installation

### Adding items

Adding items is done by changing those files in the `./blacklists` directory. The file should remain
in the standard Bro input/log format, and should conform to the following specifications:

1. The first line should be the separator to be used, so likely "#separator \x09"
2. The second line should be the list of fields
  1. This line should start with '#fields'
  2. There should be 3 fields overall. You can choose the name of the first, but the second should
     be 'source' and the third should be 'date_to_remove'
3. Each line in the file should then have 3 fields following the above order
4. Any data you enter should have leading 'www's and 'http's stripped
5. No field should equal "-", as Bro will interpret that as null
6. Each line should separate fields with the specified separator, probably TAB
7. There should not be any empty lines
8. The date_to_remove column should contain a date in the format YYYY-MM-DD

These are a lot of rules, but they are necessary for Bro to read the file properly.

These rules are all enforced by the `cleaner.py` script I wrote in the bookie repository. I recommend
using this rather than checking manually, as this will bring your attention directly to lines that
are misformatted.

### Updating the Lists

Any of the blacklists can be updated in real time and the changes will be reflected in the Bro
instance. However, I recommend making changes to the file in atomic chunks (i.e., adding full
lines and entries at a time and never writing an incomplete state to the file).
