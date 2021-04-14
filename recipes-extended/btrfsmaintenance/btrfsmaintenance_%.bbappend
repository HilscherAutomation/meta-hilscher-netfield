FILESEXTRAPATHS_prepend := "${THISDIR}/files:"
SRC_URI_append += "file://fix_fstype_detection.patch"

MOUNT_POINTS_TO_CHECK="/run/.system_part"

do_install_append() {
	# Patch btrfs mount points an parameters to check
	sed -i  -e 's@BTRFS_DEFRAG_PATHS=.*@BTRFS_DEFRAG_PATHS="${MOUNT_POINTS_TO_CHECK}"@' \
		-e 's@BTRFS_BALANCE_MOUNTPOINTS=.*@BTRFS_BALANCE_MOUNTPOINTS="${MOUNT_POINTS_TO_CHECK}"@' \
		-e 's@BTRFS_SCRUB_MOUNTPOINTS=.*@BTRFS_SCRUB_MOUNTPOINTS="${MOUNT_POINTS_TO_CHECK}"@' \
		-e 's@BTRFS_TRIM_MOUNTPOINTS=.*@BTRFS_TRIM_MOUNTPOINTS="${MOUNT_POINTS_TO_CHECK}"@' \
		-e 's@BTRFS_LOG_OUTPUT=.*@BTRFS_LOG_OUTPUT="journal"@' \
		${D}${sysconfdir}/default/btrfsmaintenance
}
