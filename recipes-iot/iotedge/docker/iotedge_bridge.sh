#!/bin/sh

BRIDGE_IP="172.16.0.1/16"

if [ -e "/etc/default/iotedge" ]; then
	. /etc/default/iotedge
fi

if [ "${1}" = "create" ]; then
	brctl addbr iotedge0
	ip addr add "${BRIDGE_IP}" dev iotedge0
	echo "1" > /proc/sys/net/ipv6/conf/iotedge0/disable_ipv6
	ip link set dev iotedge0 up
else
	ip link set dev iotedge0 down
	brctl delbr iotedge0
fi
