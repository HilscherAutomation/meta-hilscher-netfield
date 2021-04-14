#!/bin/sh -e

SCRIPTDIR=$(readlink -f "$0")
SCRIPTDIR=$(dirname "$SCRIPTDIR")

# bring up interface
ifconfig eth0 up
udhcpc -i eth0 -s $SCRIPTDIR/udhcpc-default.sh -p /var/run/udhcpc.pid -R

# Download the device data from database ...
mac=$(cat /sys/class/net/eth0/address | sed 's/://g' | tr "[:lower:]" "[:upper:])
#url=${1:-"http://gatewaydb.hilscher.local/orbeon/gatewaydb/getjsonbymac/${mac}"}
url=${1:-"http://gatewaydb/orbeon/gatewaydb/getjsonbymac/${mac}"}

wget --output-document=/tmp/device_data ${url} || {
	echo "Error: Can't get device data from ${url}."
}

# Release dhcp address
kill $(cat /var/run/udhcpc.pid)
ifconfig eth0 down

# Verify the device data ...
dd=/tmp/device_data
dd_sig=${dd}.sig
offset=$(grep -bm1 { ${dd} | cut -d: -f1)
pub_key=/tmp/owner-public.key

openssl x509 -pubkey -in /proc/sys/srm/owner-cert -noout > ${pub_key}
head -c$((offset)) ${dd} | base64 -d - > ${dd_sig}
tail -c+$((offset+1)) ${dd} | openssl dgst -sha512 -verify ${pub_key} -signature ${dd_sig}

rm ${dd_sig} ${pub_key}

exit 0
