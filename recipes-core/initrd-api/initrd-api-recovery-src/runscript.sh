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

  log "Searching update device ... "
  for scan_dev in @PHYSICAL_SYSTEM_DEVICE@; do
    if [ -b "${scan_dev}" ]; then
      log "  $scan_dev ... found"
      dev="${scan_dev}"
      break
    fi
    log "  $scan_dev ... not found"
  done
  [ -n "${dev}" ] && log "... done (${dev})" || { log "... failed"; return 1; }

  [ -e /etc/mtab ] || ln -s /proc/mounts /etc/mtab # required for mkfs.ext4

  # Unmount all partitions from the target device ...
  devmounts=$(mktemp)
  grep ^$dev /proc/mounts > $devmounts
  while read line; do
    devmp=$(cut -d' ' -f2 <<< $line)
    log "Unmounting $devmp ... "
    umount $devmp;
  done < $devmounts

  # Get update version information
  update_version_str=$(cat firmware/firmware.version)

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
            mount -o ro,loop $img $tmp_sys
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

  log "Deploying ${firmware} to ${dev} ... "
  ./recovery.sh -a ${firmware} -d ${dev} -v -l "${logfile}" &&
  sync
  [ $? -eq 0 ] && log "... done" || { log "... failed"; return 1; }

  if [ -e "/var/platform/update_led" ]; then
    echo 0 > /var/platform/update_led  # disable the trigger
    echo 1 > /var/platform/update_led
  fi

  # Remount all previously unmounted partitions of the device to be modified.
  if [ -r $devmounts ]; then
    while read line; do
      # NOTE:
      # The device mount takes place in two steps, first as read-only and then as read/write.
      # This is to avoid mount errors for devices already mounted read-only.
      log "Remounting $devmp ... "
      mount $(cut -d' ' -f1 <<< $line) $(cut -d' ' -f2 <<< $line) -t $(cut -d' ' -f3 <<< $line) -o ro
      mount $(cut -d' ' -f1 <<< $line) $(cut -d' ' -f2 <<< $line) -t $(cut -d' ' -f3 <<< $line) -o remount,$(cut -d' ' -f4 <<< $line)
    done < $devmounts
    rm $devmounts
  fi

  log "Firmware recovery successfully done!"

  return 0
}

#===============================================================================
# Start Main
#===============================================================================

source ./common

# Since older netfield-os versions prior to v2.4 uses an initrd-api filename such as "initrd-api"
# the log function is overloaded to create more meaningful log file content.
log() {
  echo "initrd-api-recovery: $@" | tee -a $logfile
}

do_firmware_recovery && {
  log "Rebooting system ..."

  cp $logfile $(dirname $apifile)
  sync

  [ "$removable" = "0" ] && do_reboot

  # Copy logfile to system partition on persistent storage.
  mp=$(mktemp -d) && mkdir -p $mp && mount -o ro $(blkid -L system) $mp && mount -o remount,rw $(blkid -L system) $mp
  cp $logfile $mp
  sync && umount $mp && rmdir $mp

  do_shutdown
}

# This should never be reached
while true; do sleep 1; done

