@load base/frameworks/notice

redef record Notice::Info += {
	blackbook_source: string &log &optional;
	blackbook_record: string &log &optional;
};
