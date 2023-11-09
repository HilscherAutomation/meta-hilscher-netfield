SUMMARY = "cifX device driver example applications for Hilscher netX devices"
HOMEPAGE = "www.hilscher.com"
LICENSE = "CLOSED"

DEPENDS = "libcifx"

SRC_URI = "file://cifxtun.c \
           file://cifxtun.service"

inherit useradd systemd

SYSTEMD_PACKAGES = "${PN}"
SYSTEMD_SERVICE:${PN} = "cifxtun.service"
SYSTEMD_AUTO_ENABLE:${PN} ?= "disable"

USERADD_PACKAGES = "${PN}"
GROUPADD_PARAM:${PN} = "-r cifx"

S = "${WORKDIR}"

FILES:${PN} = "/opt/cifx/demo"

do_compile() {
  ${CC} ${LDFLAGS} cifxtun.c -o cifxtun -I=/usr/include/cifx -lcifx -lpthread
}

do_install() {
  install -d ${D}/opt/cifx/example
  install cifxtun ${D}/opt/cifx/example

  chgrp -R cifx ${D}/opt/cifx
  chmod 0775 ${D}/opt/cifx

  # install systemd unit files
  install -d ${D}${systemd_unitdir}/system
  install -m 0644 ${WORKDIR}/cifxtun.service ${D}${systemd_unitdir}/system
}

FILES:${PN} = "/opt/cifx ${systemd_unitdir}"
