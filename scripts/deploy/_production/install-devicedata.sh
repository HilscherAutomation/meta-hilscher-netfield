#!/bin/sh -e

tmpdir=$(mktemp -d)
for label in rescue boot; do
    tmp_dev=$(blkid | grep "LABEL=\"$label\"" | cut -d ':' -f1)
    if [ -b "$tmp_dev" ]; then
        mount $tmp_dev $tmpdir
        mkdir -p ${tmpdir}/nvd
        cp /tmp/device_data ${tmpdir}/nvd
        umount $tmpdir
        sync
    fi
done
rm -r ${tmpdir}

if mount -t efivarfs none /sys/firmware/efi/efivars; then
    # Delete old variable first
    if [ -e /sys/firmware/efi/efivars/hilscher-23682453-5d09-4e17-a1a6-f5efb21996d9 ]; then
        chattr -i /sys/firmware/efi/efivars/hilscher-23682453-5d09-4e17-a1a6-f5efb21996d9
        rm /sys/firmware/efi/efivars/hilscher-23682453-5d09-4e17-a1a6-f5efb21996d9
    fi

    # Create device label
    printf "\x07\x00\x00\x00" > /tmp/efivars_temp
    cat /tmp/device_data >> /tmp/efivars_temp
    cat /tmp/efivars_temp > /sys/firmware/efi/efivars/hilscher-23682453-5d09-4e17-a1a6-f5efb21996d9
    rm /tmp/efivars_temp

    umount /sys/firmware/efi/efivars
fi

exit 0
