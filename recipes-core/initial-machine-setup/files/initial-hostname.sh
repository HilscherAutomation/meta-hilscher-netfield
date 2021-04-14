#!/bin/sh

# Setting up default hostname
if [ -z "$(cat /etc/hostname 2>/dev/null)" ]; then
  echo -n "Setting up default hostname ... "
  hostname_part1="nt"
  hostname_part2=$(cat /sys/class/net/eth0/address | sed 's/://g' | tr '[:upper:]' '[:lower:]')
  hostname=${hostname_part1}${hostname_part2}

  # Set linux host name
  hostname ${hostname}
  sed -i -e "s/\(127.0.0.1.*\)/\1\n127.0.1.1 ${hostname}\n/" /etc/hosts

  # Set pretty host name
  if [ ! -e /etc/machine-info ]; then
    pretty_hostname=$(echo $hostname | tr '[:lower:]' '[:upper:]')
    echo "PRETTY_HOSTNAME=$pretty_hostname" > /etc/machine-info
  fi
  echo ${hostname} > /etc/hostname
  sync
fi

exit 0
