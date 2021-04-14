#!/bin/sh

#===============================================================================
# Functions
#===============================================================================

do_firmware_recovery() {
  log "$(date -u +'%Y%m%d-%H%M%S') (utc):"
  log "########################################"
  log "#                                      #"
  log "#           Firmware recovery          #"
  log "#                                      #"
  log "########################################"
  log ""

  if [ -e "/var/platform/update_led" ]; then
    echo timer > $(dirname $(readlink /var/platform/update_led))/trigger
    echo 100 > $(dirname $(readlink /var/platform/update_led))/delay_off
    echo 100 > $(dirname $(readlink /var/platform/update_led))/delay_on
  fi

  firmware=`ls -1 firmware/*.wic.bz2 | head -n1`

  log -n "  Searching update device ... "
  for scan_dev in @PHYSICAL_SYSTEM_DEVICE@; do
    echo -n "$scan_dev ... "
    if [ -b "${scan_dev}" ]; then
      dev="${scan_dev}"
      break
    fi
  done
  [ -n "${dev}" ] && log "done (${dev})" || { log "failed"; return 1; }

  [ -e /etc/mtab ] || ln -s /proc/mounts /etc/mtab # required for mkfs.ext4

  # Unmount all mounted partitions from target device
  dev_mounts=$(cat /proc/mounts | grep "^$dev" | cut -d " " -f2 | tr '\n' ' ')
  for tmp_mnt in $dev_mounts; do
    umount $tmp_mnt
  done

  # Get update version information
  update_version_str=$(cat firmware.version)

  # Check installed firmware (if any) and verify if recovery shall be possible
  for system_dev in $(blkid | grep -i 'LABEL="system"' | cut -d ':' -f1); do
      tmpdir=$(mktemp -d)
      mount -o ro $system_dev $tmpdir
      if [ $? -ne 0 ]; then
          log "!!! Mounting $system_dev failed !!!"
          rmdir $tmpdir
          continue
      fi
      for img in $tmpdir/rootfs.img $tmpdir/*.squashfs; do
        if [ -e $img ]; then
            tmp_sys=$(mktemp -d)
            mount -o loop $img $tmp_sys
            if [ -e $tmp_sys/fw_version ]; then
                installed_version_str=$(cat $tmp_sys/fw_version)
                umount $tmp_sys
                rmdir $tmp_sys
                break;
            fi
            umount $tmp_sys
            rmdir $tmp_sys
        fi
      done
      # Some device (e.g. rpi) requires some time before having unmounted the squashfs image completely
      while ! umount $tmpdir; do
        log "Retrying unmounting of system partition"
        sleep 1
      done
      rmdir $tmpdir
  done

  if [ -z "$installed_version_str" ]; then
    log "!!!Unable to determine installed version. Performing recovery!!!"
  else
    do_check_version "$installed_version_str" "$update_version_str"
    if [ $? -eq 0 ]; then
      log "Installing firmware $update_version_str (previous firmware: $installed_version_str)"
    else
      log "Denying downgrade of firmware (installed:$installed_version_str, to be installed: $update_version_str)"
      return -1
    fi
  fi

  log -n "  Deploying ${firmware} to ${dev} ... "
  ./deploy.sh -a ${firmware} -d ${dev} -v -l "${logfile}" &&
  sync
  [ $? -eq 0 ] && log "done" || { log "failed"; return 1; }

  if [ -e "/var/platform/update_led" ]; then
    echo 0 > /var/platform/update_led  # disable the trigger
    echo 1 > /var/platform/update_led
  fi

  log "Firmware recovery successfully done!"
  log ""

  # Copy logfile to new rootfs
  mp=$(mktemp -d)
  log "Trying to mount system device!"
  mount $(blkid -L system) ${mp}
  log "Trying to copy log file!"
  cp ${logfile} ${mp}/last_update.log
  log "Trying to unmount system device!"
  umount ${mp}
  rmdir ${mp}

  return 0
}

#===============================================================================
# Start Main
#===============================================================================

source ./common

rm -f ${logfile}

do_firmware_recovery

[ $? -eq 0 ] && {
  [ "${reboot}" == "1" ] && do_reboot
  [ "${shutdown}" == "1" ] && do_shutdown
}

# This should never be reached
while true; do sleep 1; done

