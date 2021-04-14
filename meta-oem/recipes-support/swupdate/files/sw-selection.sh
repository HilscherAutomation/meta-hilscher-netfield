#!/bin/sh

# Select software,mode
if [ -r /firmware.vendor_id ]; then 
	vendor_id="$(cat /firmware.vendor_id)"
	SWUPDATE_ARGS="${SWUPDATE_ARGS} -e oem,$vendor_id"
fi


