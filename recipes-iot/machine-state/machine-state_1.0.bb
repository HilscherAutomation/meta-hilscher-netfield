SUMMARY = "Service monitors the device state and triggers LEDs accordingly."
HOMEPAGE = "www.hilscher.com"
LICENSE = "CLOSED"

SRC_URI = "file://process_machine_state \
           file://machine_state \
           file://led_state \
           file://system-leds \
           file://machine-state.service \
          "

RDEPENDS_${PN} = "jq"

inherit systemd

SYSTEMD_PACKAGES = "${PN}"
SYSTEMD_SERVICE_${PN} = "machine-state.service"
SYSTEMD_AUTO_ENABLE_${PN} ?= "enable"

USERADD_PACKAGES = "${PN}"

S = "${WORKDIR}"

do_install() {
	install -d ${D}${libdir_native}/machine-state/
	install -m 0744 ${WORKDIR}/process_machine_state ${D}${libdir_native}/machine-state/
	install -m 0744 ${WORKDIR}/machine_state         ${D}${libdir_native}/machine-state/
	install -m 0744 ${WORKDIR}/led_state             ${D}${libdir_native}/machine-state/

	install -d ${D}${sysconfdir}/machine-state/
	install -m 0744 ${WORKDIR}/system-leds ${D}${sysconfdir}/machine-state/system-leds

	# install systemd unit files
	install -d ${D}${systemd_unitdir}/system
	install -m 0644 ${WORKDIR}/machine-state.service ${D}${systemd_unitdir}/system
}

FILES_${PN} = "${sysconfdir}/machine-state/system-leds \
               ${systemd_unitdir} \
               ${libdir_native}/machine-state/ \
              "
