FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI:append = " \
	file://nginx_gen_ssl_cert \
	file://90.hardening.conf \
	file://nginx.logrotate \
	file://nginx-certificate.service \
	file://nginx-certificate.timer \
	"

APPARMOR_PROFILES="${PN}.apparmor:usr.sbin.nginx"
inherit apparmor

PACKAGECONFIG:append = " http2 http_sub"
PACKAGECONFIG[http_sub] = "--with-http_sub_module,,"

SYSTEMD_SERVICE:${PN}:append = " nginx-certificate.timer nginx-certificate.service"

do_install:append() {
  install -m 755 -d ${D}/etc/nginx/ssl ${D}/etc/ssl/services/nginx

  install -d "${D}/etc/nginx/conf.d"
  install -d "${D}/etc/nginx/services/http"
  install -d "${D}/etc/nginx/services/https"

  if ${@bb.utils.contains('DISTRO_FEATURES', 'systemd', 'true', 'false', d)}; then
    install ${WORKDIR}/nginx_gen_ssl_cert ${D}${sbindir}
    sed -e 's,@SBINDIR@,${sbindir},g' ${WORKDIR}/nginx-certificate.service \
           > ${D}${systemd_unitdir}/system/nginx-certificate.service
    chmod 0644 ${D}${systemd_unitdir}/system/nginx-certificate.service
    install -m 0644 ${WORKDIR}/nginx-certificate.timer ${D}${systemd_unitdir}/system/
  fi

  for add_conf in 90.hardening.conf; do
    install -m 0644 ${WORKDIR}/$add_conf ${D}/etc/nginx/conf.d
  done

  install -d ${D}${sysconfdir}/logrotate.d
  install -m 0644 ${WORKDIR}/nginx.logrotate ${D}${sysconfdir}/logrotate.d/nginx

  # Allow netadmin group to modify basic nginx settings
  install -d ${D}${libdir}/tmpfiles.d/
  cat <<EOF> ${D}${libdir}/tmpfiles.d/nginx-netadmin.conf
z ${sysconfdir}/nginx 0775 root netadmin
z ${sysconfdir}/nginx/nginx.conf 0664 root netadmin
EOF
}
FILES:${PN}:append = " ${libdir}/tmpfiles.d/nginx-netadmin.conf"

PACKAGES =+ "${PN}-conf"
RDEPENDS:${PN}:append = " ${PN}-conf"
FILES:${PN}-conf += "${sysconfdir}/nginx/nginx.conf"

#FILES_${PN} += "/var/lib/nginx"
#FILES_${PN} += "${sysconfdir}/nginx/*"
#FILES_${PN} += "${sysconfdir}/default/volatiles/*"
#FILES_${PN} += "${sysconfdir}/init.d/*"
#FILES_${PN} += "${@bb.utils.contains('DISTRO_FEATURES', 'systemd', '/etc/systemd/*', '', d)}"
