SUMMARY="Cockpit is a server manager that makes it easy to administer your GNU/Linux servers via a web browser."
HOMEPAGE="http://www.cockpit-project.org/"
LICENSE="LGPL-2.1-or-later"

SRC_URI +="file://cockpit.service \
           file://cockpit.socket \
           file://cockpit.pam \
           file://cockpit.conf \
           file://99-cockpit.conf \
           file://cockpit-session-socket-user.service \
           file://cockpit-session.socket \
           file://0001-change-user-group-to-cockpit-ws.patch \
"

inherit autotools-brokensep gettext useradd systemd

USERADD_PACKAGES = "${PN}"
USERADD_PARAM:${PN} = "--system --no-create-home --home-dir /var/lib/cockpit --shell /sbin/nologin --user-group ${COCKPIT_USER_GROUP}"

SYSTEMD_PACKAGES="${PN}"
SYSTEMD_SERVICE:${PN}="${PN}.service"
SYSTEMD_AUTO_ENABLE:${PN} = "enable"

export SUDO="/usr/bin/sudo"
export CHCON="/usr/bin/chcon"
export USERMOD="/usr/sbin/usermod"
export SSH_ADD="/usr/bin/ssh-add"
export SSH_AGENT="/usr/bin/ssh-agent"
export PKEXEC="/usr/bin/pkexec"

PACKAGECONFIG[asan]="--enable-asan=yes,--enable-asan=no,asan"

RDEPENDS:${PN} = "glib-networking openssh-misc libpwquality libpam"

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

  install -d ${D}${sysconfdir}/pam.d/
  install -m 0644 ${S}/tools/cockpit.pam ${D}${sysconfdir}/pam.d/cockpit

  install -m 0644 ${WORKDIR}/${PN}.service ${D}${systemd_unitdir}/system
  install -m 0644 ${WORKDIR}/${PN}.socket ${D}${systemd_unitdir}/system

  install -m 0644 ${WORKDIR}/cockpit-session-socket-user.service ${D}${systemd_unitdir}/system
  install -m 0644 ${WORKDIR}/cockpit-session.socket ${D}${systemd_unitdir}/system

  install -d ${D}${sysconfdir}/nginx/services/https
  install ${WORKDIR}/99-cockpit.conf ${D}${sysconfdir}/nginx/services/https/

  install -m 0644 ${WORKDIR}/cockpit.pam ${D}${sysconfdir}/pam.d/cockpit

  # Remove non-required files
  rm -r ${D}${datadir}/metainfo

  # Remove notification on console, about how to enable cockpit
  rm ${D}${sysconfdir}/issue.d/cockpit.issue
  rm ${D}${sysconfdir}/motd.d/cockpit

  chown 0:0 -R ${D}/${datadir}/cockpit

  # Create home directories for users
  install -d ${D}${libdir}/tmpfiles.d
  echo 'd /var/lib/cockpit 0775 ${COCKPIT_USER_GROUP} ${COCKPIT_USER_GROUP} -' > ${D}${libdir}/tmpfiles.d/cockpit.conf
}

SECURITY_CFLAGS = "${SECURITY_NO_PIE_CFLAGS}"

FILES:${PN} += "${systemd_unitdir} \
                ${datadir}/locale \
		${datadir}/polkit-1 \
                ${datadir}/cockpit/shell/ \
                ${libdir} \
                /lib/security \
                ${datadir}/common-licenses/cockpit/cockpit-netiot-third-party-web-licenses.json \
"

INHIBIT_PACKAGE_DEBUG_SPLIT="1"
PACKAGE_NO_LOCALE="1"
CVE_PRODUCT = "cockpit-project:cockpit"
