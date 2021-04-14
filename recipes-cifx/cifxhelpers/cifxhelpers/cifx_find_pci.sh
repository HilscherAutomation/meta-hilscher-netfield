#!/bin/sh

idx=0

for dev in $(find /sys/devices/pci* -name vendor 2>/dev/null); do
    vendor_id=$(cat $dev)
    if [ "$vendor_id" = "0x15cf" ]; then
        basedir=$(dirname $dev)
        device_id=$(cat $basedir/device)
        subsystem_device_id=$(cat $basedir/subsystem_device)
        subsystem_vendor_id=$(cat $basedir/subsystem_vendor)
        if [ "$device_id" = "0x0000" -a "$subsystem_device_id" = "0x0000" -a "$subsystem_vendor_id" = "0x0000" ]; then
            echo "cifX$idx;$basedir"
            idx=$((idx + 1))
        fi
    fi
done
