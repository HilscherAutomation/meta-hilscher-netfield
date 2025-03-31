echo Wait until 90 seconds of uptime is reached ...
while [ $(cat /proc/uptime | cut -d. -f1) -lt 90 ]; do sleep 1; done;

echo "Create a DUT journald logfile ..."
journalctl -p warning -b --output json | jq '. | {'SYSLOG_IDENTIFIER': .SYSLOG_IDENTIFIER, 'MESSAGE': .MESSAGE}' -c | sort | uniq > MACHINE.log
