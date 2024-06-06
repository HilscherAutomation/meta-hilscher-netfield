FILESEXTRAPATHS:prepend := "${THISDIR}/cockpit-netiot:"

SRC_URI:append = " \
    file://0001-Allow-using-external-proxy.patch \
    file://0002-netFIELDOS-does-not-use-the-default-zones-of-firewal.patch \
    file://0003-Hide-wheel-group-which-is-not-used-on-netFIELDOS.patch \
    file://firewall_dont_add_cockpit.patch \
    file://cockpit.pam \
    file://cockpit.conf \
    file://99-cockpit.conf \
"

inherit useradd

USERADD_PACKAGES = "${PN}"
USERADD_PARAM:${PN} = "--system --no-create-home --home-dir /var/lib/cockpit --shell /sbin/nologin --user-group cockpit-ws"

COCKPIT_USER_GROUP = "cockpit-ws"

# Split up branding themes into separate packages
PACKAGES_DYNAMIC += "^${PN}-branding-.*"
python populate_packages:prepend () {
    branding_basedir = os.path.join(d.expand('${datadir}'), 'cockpit', 'branding')
    do_split_packages(d, branding_basedir,
                      r'^(.*)$', 'cockpit-branding-%s',
                      'Cockpit theme for %s',
                      prepend = True,
                      allow_dirs = True,
                      extra_depends = '',
                      postinst='[ ! -e "$D${datadir}/cockpit/branding/default" ] && ln -sf $(ls -1 $D${datadir}/cockpit/branding | head -n1) $D${datadir}/cockpit/branding/default || true')
}

do_install:append() {
  install -d ${D}${sysconfdir}/cockpit
  install -m 0644 ${WORKDIR}/cockpit.conf ${D}${sysconfdir}/cockpit

  install -d ${D}${sysconfdir}/nginx/services/https
  install ${WORKDIR}/99-cockpit.conf ${D}${sysconfdir}/nginx/services/https/

  install -d ${D}${sysconfdir}/pam.d/
  install -m 0644 ${WORKDIR}/cockpit.pam ${D}${sysconfdir}/pam.d/cockpit

  # Remove non-required files
  rm -r ${D}${datadir}/metainfo

  # Remove notification on console, about how to enable cockpit
  rm ${D}${sysconfdir}/issue.d/cockpit.issue
  rm ${D}${sysconfdir}/motd.d/cockpit
}
