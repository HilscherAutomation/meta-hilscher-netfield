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
	[ "$verbose" = "1" ] && echo "$MYNAME: $@" | tee -a "${logfile}"
	return 0
}

vmsg_errout ()
{
	[ "$verbose" = "1" ] && echo -ne "\n\e[1;31m$MYNAME: $@\e[0m\n\n" | tee -a "${logfile}"
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
	local mp

	mkdir -p /tmp/rescue
	mount $(blkid -L rescue) /tmp/rescue

	vgchange -ay ${LVM_OPTS} > /dev/null
	vgscan --mknodes ${LVM_OPTS} > /dev/null

	for label in backup; do
		if dev=$(blkid -L $label); then
			mp=$(mktemp -d) && mount $dev $mp

			if [ -e "/tmp/rescue/nvd/device_data" ] && [ ! -e "$mp/nvd/device_data" ]; then
				vmsg "Moving production device data to final location"
				mkdir -p "$mp/nvd"
				mv /tmp/rescue/nvd/device_data $mp/nvd/device_data
				rmdir /tmp/rescue/nvd
				sync
			fi

			if [ -d "$mp/nvd" ]; then
				vmsg "Creating backup file ${label}_nvd.tar ..."
				tar cf /tmp/${label}_nvd.tar -C $mp nvd
				vmsg "... done"
			else
				vmsg "No 'nvd' directory found on partition ${label}."
			fi
			umount $mp && rmdir $mp
		else
			vmsg "Invalid or missing partition '$label'!"
		fi
	done

	vgchange -an ${LVM_OPTS} > /dev/null

	umount /tmp/rescue
	rmdir /tmp/rescue
}

restore_nvd ()
{
	local mp

	vgchange -ay ${LVM_OPTS} > /dev/null
	vgscan --mknodes ${LVM_OPTS} > /dev/null

	for label in backup; do
		if [ -e "/tmp/${label}_nvd.tar" ]; then
			if dev=$(blkid -L $label); then
				mp=$(mktemp -d) && mount $dev $mp
				vmsg "Restoring backup file ${label}_nvd.tar ..."
				tar xf "/tmp/${label}_nvd.tar" -C $mp
				vmsg "... done"
				umount $mp && rmdir $mp
			else
				vmsg "Invalid or missing partition '$label'!"
			fi
		else
			vmsg "No backup file ${label}_nvd.tar found."
		fi
	done

	vgchange -an ${LVM_OPTS} > /dev/null
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

if [ -z "${PBZIP}" ]; then
    BZIP="bzip2"
else
    BZIP="${PBZIP}"
fi

vmsg "Deploying ${firmware} to ${deploy_dev} ..."
if [ -z "${PV}" ]; then
    dd if=${firmware} of=${deploy_dev} bs=1M
else
    pv ${firmware} | ${BZIP} -d | dd of=${deploy_dev} bs=1M
fi


# Re-read partition table
reread_partition_table "$deploy_dev"

# Handle initrd-api files of recovered firmware.
# This ensures that the initrd-api-part-cfg is executed to create the LVM backup- and data-partition.
vmsg "Processing initrd-api files of currently deployed firmware image ..."
__debug() {
	vmsg $@
}
__fatal() {
	vmsg_errout $@
}
. /init.d/*-initrd_api
boot_dev=$(blkid -L system) && initrd_api_run
vmsg "... done"

restore_nvd

sync

exit 0
