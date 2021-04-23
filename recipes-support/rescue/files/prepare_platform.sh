#!/bin/sh

source /etc/default/rescue

if [ -z $swupdate_port ]; then
  swupdate_port="80"
fi

if [ -e /etc/swupdate.conf ]; then
  sed -i 's/listening_ports.*/listening_ports="0.0.0.0:'${swupdate_port}'"/g' /etc/swupdate.conf
fi

if [ $# -gt 0 ]; then
  swupdate_iface=$1
fi

if [ -z $swupdate_iface ]; then
  swupdate_iface="eth0"
fi

if [ -z $swupdate_ipaddr ]; then
  swupdate_ipaddr="192.168.253.1"
fi

ifconfig $swupdate_iface $swupdate_ipaddr
ifconfig $swupdate_iface up

#signal that device is in rescue boot mode
if [ -e "/var/platform/rescue_mode_led" ]; then
  echo timer > $(dirname $(readlink /var/platform/rescue_mode_led))/trigger
  echo 200 > $(dirname $(readlink /var/platform/rescue_mode_led))/delay_off
  echo 1000 > $(dirname $(readlink /var/platform/rescue_mode_led))/delay_on
fi
