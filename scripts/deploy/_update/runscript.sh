#!/bin/sh

do_find_block_device() {
  bdev=""
  rfs_label=$1
  waited=0;
  while [ -z "${bdev}" -a ${waited} -lt 10 ]; do
    waited=`expr ${waited} + 1`
    bdev=$(blkid -L ${rfs_label} 2>/dev/null) && continue
    sleep 1
  done
  [ -z "${bdev}" ] && {
    # Fallback ...
    for tmp_dev in @PHYSICAL_SYSTEM_DEVICE@; do
      if [ -b $tmp_dev ]; then
        [ -e "${tmp_dev}p3" ] && bdev="${tmp_dev}p3" || bdev="${tmp_dev}3"
      fi
    done
  }
  echo "${bdev}"
}

do_update_partition(){
  src=$1
  dst=$2

  #check if rsync command exists
  command -v rsync > /dev/null
  if [ $? -eq 0 ]; then
    logopt="--log-file=${rsync_log}"

    # update only if necessary (recursive,checksum,links,permissions)
    # NOTE: option permission may always update(/write) on a FAT partition
    rsync -rcl --delete "${logopt}" "${src}/" "${dst}" 2> rsync_err
    ret=$?
    if [ $ret -ne 0 ]; then
      log "  Updating partition failed: $ret"
      echo "*** rsync error:" >> ${rsync_log}
      cat rsync_err >> ${rsync_log}
    fi
  else
    echo "no rsync available" >> ${rsync_log}
    # clean and update/copy all files to destination
    rm -rf ${dst}/*
    cp -r ${src}/* ${dst}/
  fi
}

do_updates(){

  log "  Check for relevant updates ..."
  # list all available directories (directory=partition)
  for partition in $(ls -D "firmware/update/"); do
    # find and extract the update partition via name
    devpart=$(do_find_block_device "${partition}")
    if [ -n "${devpart}" ]; then
      tmpdir=$(mktemp -d)
      mount "${devpart}" "${tmpdir}"

      log "  Updating firmware (partition: ${partition}) ... "
      do_update_partition "firmware/update/${partition}" "${tmpdir}"
      log ""

      sync
      umount $tmpdir
      rmdir $tmpdir
    fi
  done
}

#===============================================================================
# Functions
#===============================================================================

do_firmware_update() {
  log "$(date -u +'%Y%m%d-%H%M%S') (utc):"
  log "########################################"
  log "#                                      #"
  log "#           Firmware update            #"
  log "#                                      #"
  log "########################################"
  log ""

  if [ -e "/var/platform/update_led" ]; then
    echo timer > $(dirname $(readlink /var/platform/update_led))/trigger
    echo 100 > $(dirname $(readlink /var/platform/update_led))/delay_off
    echo 100 > $(dirname $(readlink /var/platform/update_led))/delay_on
  fi

  # get version of currently installed system
  dev=$(do_find_block_device system)
  [ -z "${dev}" ] && { log "searching for system device failed"; return 1; }

  mkdir rootfs
  mount -o nodelalloc ${dev} rootfs

  # Delete apifile to prevents boot loops
  rm -f rootfs/$(basename ${apifile})

  installed_rootfs=$(ls -1 rootfs/*.squashfs* | head -n1)

  # Extract version information from installed rootfs
  tmpdir=$(mktemp -d)
  mount -o loop $installed_rootfs $tmpdir
  installed_version_str=$(cat $tmpdir/fw_version)
  umount $tmpdir
  sleep 1
  umount rootfs
  rmdir $tmpdir
  rmdir rootfs

  # Get update version information
  update_version_str=$(cat firmware.version)

  do_check_version "$installed_version_str" "$update_version_str"
  if [ $? -eq 0 ]; then
    log "Performing update from $installed_version_str to $update_version_str"
  else
    log "Denying update from $installed_version_str to $update_version_str"
    return -1
  fi

  # start update process
  do_updates

  if [ -e "/var/platform/update_led" ]; then
    echo 0 > /var/platform/update_led  # disable the trigger
    echo 1 > /var/platform/update_led
  fi

  log "Firmware update done!"
  log ""

  # Copy logfile to new rootfs
  mp=$(mktemp -d)
  mount $(blkid -L system) ${mp}
  cat ${logfile} >> ${mp}/last_update.log
  cat "${rsync_log}" >> ${mp}/last_update.log
  # sync seems required otherwise logfile sometimes not written
  sync
  umount ${mp}
  rmdir ${mp}

  return 0
}

#===============================================================================
# Start Main
#===============================================================================

source ./common

rm -f ${logfile}
rsync_log=$(mktemp)
echo "--- rsync info -----------------" >> ${rsync_log}

do_firmware_update && {
	[ "$removable" = "0" ] && do_reboot
	do_shutdown
}

# This should never be reached
while true; do sleep 1; done

