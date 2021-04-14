#!/bin/sh

#===============================================================================
# Functions
#===============================================================================

do_restore_firmware() {
  log "########################################"
  log "#                                      #"
  log "#       Restore Firmware Image         #"
  log "#                                      #"
  log "########################################"
  log ""

  if [ -e "/var/platform/update_led" ]; then
    echo timer > $(dirname $(readlink /var/platform/update_led))/trigger
    echo 100 > $(dirname $(readlink /var/platform/update_led))/delay_off
    echo 100 > $(dirname $(readlink /var/platform/update_led))/delay_on
  fi

  mkdir -p /mnt
  dev_system=$(blkid -L system 2>/dev/null)
  mount $dev_system /mnt

  firmware=/mnt/restore.tar.bz2

  # Delete all files except /nvd and restore.tar.bz2
  find /mnt -max-depth 1 -not -name restore.tar.bz2 -not -name nvd -exec rm -rf {} \;
  rm -rf /mnt/

  # Extract restore.tar.bz2
  PBZIP2=$(which pbzip2)
  # Use paralell unzipping if available
  if [ ! -z "${PBZIP2}" ]; then
    PARALLEL_BZ2="--use-compress-program=${PBZIP2}"
  fi

  if [ -z "${PV}" ]; then
    tar ${PARALLEL_BZ2} -xf ${firmware} -C /mnt
  else
    vmsg ""
    ${PV} ${firmware} | tar ${PARALLEL_BZ2} -x -C /mnt
  fi

  # Update boot files
  mkdir /tmp/boot
  mount $(blkid -L BOOT) /tmp/boot
  unsquashfs -f -d /tmp/boot /mnt/rootfs.img boot >> "${logfile}"
  mv /tmp/boot/boot/* /tmp/boot
  rmdir /tmp/boot/boot
  umount /tmp/boot

  # Remove tarball
  rm -f $firmware

  log -n "  cleanup ... "
  rm -f ${firmware} &&
  rm -f ${image_path}"/firmware" &&
  sync
  [ $? -eq 0 ] && log "done" || { log "failed"; return 1; }

  if [ -e "/var/platform/update_led" ]; then
    echo 0 > /var/platform/update_led  # disable the trigger
    echo 1 > /var/platform/update_led
  fi

  log -e "Restoring image successfully done!\n"

  return 0
}

#===============================================================================
# Start Main
#===============================================================================

source ./common

rm -f ${logfile}

# Remove the API file for singleshot execution ...
rm ${apifile}

do_restore_firmware
do_reboot

# This should never be reached
while true; do sleep 1; done
