SUMMARY = "SSPD service configuration files"
HOMEPAGE = ""
LICENSE = "CLOSED"

SRC_URI = "file://init-desc \
           file://netiotdevicedesc.xml \
           file://logo.png \
"

PACKAGE_ARCH="${MACHINE_ARCH}"
S = "${WORKDIR}"

PACKAGES = "${PN}"

EMULATED_MANUFACTURER     ??= "Unknown vendor"
EMULATED_MANUFACTURER_URL ??= ""
EMULATED_PRODUCT_NAME     ??= "Unknown device"
EMULATED_MODEL_NAME       ??= "Unknown device"
EMULATED_MODEL_NUMBER     ??= "Unknown device model - $(cat /var/platform/device_data/product_name)"
EMULATED_MODEL_URL        ??= ""

python() {
    defaults = [
        {'var': 'MANUFACTURER',              'value': 'Unknown vendor'},
        {'var': 'MANUFACTURER_URL',          'value': ''},
        {'var': 'MODEL_URL',                 'value': ''},
    ]
    for val in defaults:
        if d.getVar(val['var']) is None:
            var = val['var']
            default = val['value']

            bb.warn(f"{var} not set by machine and will default to {default}")
            d.setVar(val['var'], default)

}

do_install() {
  install -d -m 0775 "${D}/opt/upnpd/desc"

  sed -e 's;@EMULATED_MANUFACTURER@;${EMULATED_MANUFACTURER};g' \
      -e 's;@EMULATED_MANUFACTURER_URL@;${EMULATED_MANUFACTURER_URL};g' \
      -e 's;@EMULATED_PRODUCT_NAME@;${EMULATED_PRODUCT_NAME};g' \
      -e 's;@EMULATED_MODEL_NAME@;${EMULATED_MODEL_NAME};g' \
      -e 's;@EMULATED_MODEL_NUMBER@;${EMULATED_MODEL_NUMBER};g' \
      -e 's;@EMULATED_MODEL_URL@;${EMULATED_MODEL_URL};g' \
      -e 's;@MANUFACTURER@;${MANUFACTURER};g' \
      -e 's;@MANUFACTURER_URL@;${MANUFACTURER_URL};g' \
      -e 's;@MODEL_URL@;${MODEL_URL};g' \
      ${WORKDIR}/init-desc > ${D}/opt/upnpd/init-desc

  chmod 0755 ${D}/opt/upnpd/init-desc
  chown 0:0 ${D}/opt/upnpd/init-desc
  install -m 0664 ${WORKDIR}/netiotdevicedesc.xml "${D}/opt/upnpd"
  install -m 0774 ${WORKDIR}/logo.png             "${D}/opt/upnpd/desc"
}

FILES:${PN} = "/opt/upnpd"
