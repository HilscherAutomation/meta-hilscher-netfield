#!/bin/sh

rm -f /etc/sw-versions

# Write installed bootloader version to /etc/sw-versions
dev="$(blkid | grep LABEL=\"boot\" | head -n1 | cut -d: -f1)"
mp=$(mktemp -d)
mount -o ro $dev $mp
[ -e $mp/boot_*.bin ] && bootloader="$mp/boot_*.bin"
[ -z "$bootloader" -a -e $mp/boot.bin ] && bootloader="$mp/boot.bin"
[ -n "$bootloader" ] && {
	version="$(basename $bootloader | sed 's,boot\(.*\).bin,\1,' | cut -c 2-)"
	[ -z "$version" ] && version="$(sha256sum $bootloader | cut -d' ' -f1)"
	[ -n "$version" ] && echo "boot.bin $version" | tee -a /etc/sw-versions
}
umount $mp
rmdir $mp
