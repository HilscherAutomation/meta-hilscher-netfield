#!/bin/sh

#===============================================================================
# Functions
#===============================================================================

do_hardware_test() {
  err=0

  while [ "$err" = "0" ]; do
    log "########################################"
    log "#                                      #"
    log "#            Hardware Test             #"
    log "#                                      #"
    log "########################################"
    log ""

    for led in /var/platform/led_*; do
        led_name=$(echo $(basename $led) | cut -d '_' -f2- | tr '[:lower:]' '[:upper:]')
        log -n "  Leuchtet LED ${led_name} [j/n] ... "
        echo 0 > $led # disable the trigger settings fom the platform_init
        echo 1 > $led
        read -s -n1 val; log "$val"; [ "${val}" != "j" ] && err=$((err+1))
    done

    for led in /var/platform/led_*; do
        echo 0 > $led
    done
    log -n "  Sind alle LEDs aus [j/n] ... "
    read -s -n1 val; log "$val"; [ "${val}" != "j" ] && err=$((err+1))
    log ""

    for eth in /sys/class/net/eth*; do
        eth_name=$(basename $eth)
        log -n "  ${eth_name} ... "
        ifconfig -a | grep -q ${eth_name} &&
        mac=$(ifconfig ${eth_name} | grep -o "HWaddr.*" | cut -d' ' -f2 | sed 's/:/-/g')
        [ $? -eq 0 ] && log "gefunden ... MAC: $mac" || { log "nicht gefunden"; err=$((err+1)); }
    done

    # Test the LAN interfaces (eth0, eth1)
    for eth in /sys/class/net/eth*; do
        eth_if=$(basename $eth)
        log -n "  Testen der LAN-Schnittstelle ${eth_if} ... "
        ifconfig ${eth_if} up
        sleep 1
        # Discover dhcp address
        udhcpc -i ${eth_if} -s udhcpc-default.sh -n -q -f -R >/dev/null 2>&1 && {
          log "erfolgreich"
        } || {
          log "fehlerhaft"
          err=$((err+1))
        }
        ifconfig ${eth_if} down
    done
    log ""

    if [ "$err" == "0" ]; then
      log -e "  Test erfolgreich bestanden!\n"
    else
      log -e "  Es ist/sind $err Fehler aufgetreten!\n"
    fi

    log -n "  Soll der Test wiederholt werden [j/n] ... "
    read -s -n1 val; log "$val"; log ""; [ "${val}" != "j" ] && break

    err=0
  done

  return $err
}

do_firmware_update() {
  log "########################################"
  log "#                                      #"
  log "#           Production mode            #"
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
    if [ -b "${scan_dev}" ]; then
      dev="${scan_dev}"
      break
    fi
  done
  [ -n "${dev}" ] && log "done (${dev})" || { log "failed"; return 1; }

  [ -e /etc/mtab ] || ln -s /proc/mounts /etc/mtab # required for mkfs.ext4

  log "########################################"
  log "#                                      #"
  log "#    Holen der Geraetedaten            #"
  log "#                                      #"
  log "########################################"
  log ""
  ./fetch-devicedata.sh
  [ $? -eq 0 ] && log "OK" || { log "***** FEHLGESCHLAGEN ******"; return 1; }

  log "########################################"
  log "#                                      #"
  log "#    Firmware aufspielen               #"
  log "#                                      #"
  log "########################################"
  log ""
  log -n "  Deploying ${firmware} to ${dev} ... "
  ./deploy.sh -a ${firmware} -d ${dev} -v -l "${logfile}" &&
  [ $? -eq 0 ] && log "done" || { log "failed"; return 1; }
  sync

  log "########################################"
  log "#                                      #"
  log "#    Aufspielen der Geraetedaten       #"
  log "#                                      #"
  log "########################################"
  log ""
  ./install-devicedata.sh
  [ $? -eq 0 ] && log "OK" || { log "***** FEHLGESCHLAGEN ******"; return 1; }
  sync

  if [ -e "/var/platform/update_led" ]; then
    echo 0 > /var/platform/update_led  # disable the trigger
    echo 1 > /var/platform/update_led
  fi

  log -e "Firmware update successfully done!\n"
  log -e "Please remove USB stick and reboot!\n"

  return 0
}

#===============================================================================
# Start Main
#===============================================================================

source ./common

rm -f ${logfile}

do_hardware_test

do_firmware_update
rc=$?

log -n "  Soll eine command shell geoeffnet werden [j/n] ... "
val=""; read -s -n1 -t5 val;
[ -z "$val" ] && {
  log -n "timeout ... "
  val="n"
}
log -e "$val\n";
[ "$val" == "j" ] && /bin/sh

[ ${rc} -eq 0 ] && {
  do_shutdown
}

# This should never be reached
while true; do sleep 1; done
