#!/bin/sh

MYNAME=$(basename ${0})
MYVERSION="20190718"
PV=$(which pv)
PBZIP=$(which pbzip2)

#===============================================================================
# Help Functions
#===============================================================================
vmsg ()
{
	[ "$verbose" = "1" ] && echo "$@" | tee -a "${logfile}"
	return 0
}

vmsg_errout ()
{
	[ "$verbose" = "1" ] && echo -ne "\n\e[1;31m$@\e[0m\n\n" | tee -a "${logfile}"
	exit 1
}

reread_partition_table ()
{
    dev=$1
    retries=5

    [ -x "/sbin/blockdev" ] && reread_cmd="blockdev --rereadpt $dev"
    [ -x "/sbin/hdparm" ] && reread_cmd="hdparm -z $dev"
    [ -z "$reread_cmd" ] && reread_cmd="/bin/true"

    while [ $retries -gt 0 ]; do
        eval $reread_cmd
        error=$?
        if [ $error -ne 0 ]; then
            vmsg "Error re-reading partition table. retries=$retries error=${error}"
            sleep 1
            retries=$(expr $retries - 1)
        else
            return 0
        fi
    done
}

show_help ()
{
	cat <<EOF
Usage: $MYNAME options

 -a wic image
    e.g. netfield-image.wic.bz2

 -d recovery-device
    e.g. : /dev/sdb

 -l errors.log
    File to log errors, warnings and info

 -v
    Enable verbose mode.

 -h
    Show this help menu.

Examples:
  ${MYNAME} -a diskimage.wic -d /dev/sdb
EOF
}

LVM_OPTS="--config global/use_lvmetad=0"

backup_nvd ()
{
	vmsg -n "- Creating a backup of nvd directory ..."
	tmpdir=$(mktemp -d)

	vgchange -ay ${LVM_OPTS} > /dev/null
	vgscan --mknodes ${LVM_OPTS} > /dev/null

	for label in BACKUP BOOT RESC SYSTEM system backup rescue; do
		tmp_dev=$(blkid | grep "LABEL=\"$label\"" | cut -d ':' -f1)
		if [ -b "$tmp_dev" ]; then
			mount -o ro $tmp_dev $tmpdir
			if [ -d "$tmpdir/nvd" ]; then
				tar cf nvd.tar -C $tmpdir nvd
			fi
			umount $tmpdir
		fi
		[ -e "nvd.tar" ] && break
	done

	rmdir $tmpdir

	vgchange -an ${LVM_OPTS} > /dev/null
	if [ -e "nvd.tar" ]; then
		vmsg " done ($tmp_dev)"
	else
		vmsg " done (not found)"
	fi
}

restore_nvd ()
{
	vmsg -n "- Restoring nvd directory from backup ..."

	if [ -e "nvd.tar" ]; then
		tmpdir=$(mktemp -d)

		restore_devs=""

		for label in rescue boot; do
			tmp_dev=$(blkid | grep "LABEL=\"$label\"" | cut -d ':' -f1)
			if [ -b "$tmp_dev" ]; then
				mount $tmp_dev $tmpdir
				tar xf nvd.tar -C $tmpdir
				umount $tmpdir
				sync
				restore_devs="$tmp_dev $restore_devs"
			fi
		done

		rmdir $tmpdir

		vmsg " done ($restore_devs)"
	else
		vmsg " done (no backup found)"
	fi
}

backup_oem ()
{
	vgchange -ay ${LVM_OPTS} > /dev/null
	vgscan --mknodes ${LVM_OPTS} > /dev/null

	tmp_dev=$(blkid | grep "LABEL='system'" | cut -d ':' -f1)
	if [ ! -b "$tmp_dev" ]; then
		vmsg -n "- Creating a backup of oem directory ..."
		tmpdir=$(mktemp -d)
		mount -o ro $tmp_dev $tmpdir
		if [ -d "$tmpdir/oem" ]; then
			vmsg -n "- Creating a backup of oem directory ..."
				tar cf oem.tar -C $tmpdir oem
			fi
			umount $tmpdir
			vmsg " done"
		fi
		rmdir $tmpdir
	done

	vgchange -an ${LVM_OPTS} > /dev/null
}

restore_oem ()
{
	if [ -e "oem.tar" ]; then
		vmsg -n "- Restoring nvd directory from backup ..."
		tmpdir=$(mktemp -d)

		tmp_dev=$(blkid | grep "LABEL='system'" | cut -d ':' -f1)
		if [ -b "$tmp_dev" ]; then
			mount $tmp_dev $tmpdir
			tar xf oem.tar -C $tmpdir
			umount $tmpdir
			sync
		fi

		rmdir $tmpdir
		vmsg " done"
	fi
}

#===============================================================================
# Start Main
#===============================================================================

# Check for sudo execution
[ "$(id -u)" != "0" ] && {
	echo "Please use 'sudo' or root account to run this tool!"
	exit 1
}

logfile="/dev/null"

# Parse Options
while getopts "a:d:l:vh" opt ; do
	echo "${OPTARG}" | grep -q "^-.*" && {
		echo "option -${opt} requires an argument!"
		exit 1
	}
	case ${opt} in
		a) firmware=$OPTARG;;
		d) deploy_dev=$OPTARG;;
		v) verbose=1;;
		l) logfile=$OPTARG;;
		h) show_help && exit 0;;
		?) show_help && exit 1;;
	esac
done

# Show welcome message
vmsg
vmsg "==========================================================="
vmsg " Application: ${MYNAME} (${MYVERSION})"
vmsg "==========================================================="

# Check for required arguments
if [ -z "${firmware}" -o -z "${deploy_dev}" ]; then
	echo "Invalid or missing arguments.";
	exit 1
fi

backup_nvd
backup_oem

if [ -z "${PBZIP}" ]; then
    BZIP="bzip2"
else
    BZIP="${PBZIP}"
fi

vmsg "- Deploying ${firmware} to ${deploy_dev} ..."
if [ -z "${PV}" ]; then
    dd if=${firmware} of=${deploy_dev} bs=1M
else
    pv ${firmware} | ${BZIP} -d | dd of=${deploy_dev} bs=1M
fi


# Re-read partition table
reread_partition_table "$deploy_dev"

restore_nvd
restore_oem

sync

exit 0
