SRC_URI:append = " file://authz.rego"

inherit useradd

USERADD_PACKAGES="${PN}"
GROUPADD_PARAM:${PN} = "-r docker-readonly"

do_install:append() {
    # Override sample policy
    rm ${D}${sysconfdir}/docker/policies/authz.rego
    install -m 0644 ${WORKDIR}/authz.rego ${D}${sysconfdir}/docker/policies/
}

# Make sure docker uses opa-docker-authz
pkg_postinst:${PN}:prepend() {
    # Add service dependency to docker.service / iotedge-docker.service and pass authz plugin
    for service in docker.service iotedge-docker.service; do
        sed -i -e 's@dockerd@dockerd --authorization-plugin="${BPN}"@g' \
               -e 's@Requires=@Requires=${BPN}.service @g' \
               -e 's@After=@After=${BPN}.service @g' \
            $D${systemd_system_unitdir}/$service
    done
}
