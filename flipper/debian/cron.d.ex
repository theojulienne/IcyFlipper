#
# Regular cron jobs for the flipper package
#
0 4	* * *	root	[ -x /usr/bin/flipper_maintenance ] && /usr/bin/flipper_maintenance
