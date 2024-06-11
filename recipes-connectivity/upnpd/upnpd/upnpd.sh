#!/bin/sh

interface=$1

port=$(cat /etc/nginx/nginx.conf | grep listen | grep -v ssl | sed -e 's/.*:\([0-9]\+\).*/\1/g')

if [ "$port" != "80" ]; then
  /opt/upnpd/upnpd -if $interface -extport $port -extweb desc/netiotdevicedesc_${interface}.xml
else
  /opt/upnpd/upnpd -if $interface -extweb desc/netiotdevicedesc_${interface}.xml
fi
