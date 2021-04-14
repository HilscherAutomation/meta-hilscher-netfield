SUMMARY="Cockpit branding overlay (e.g. to hide plugins from base image)"
LICENSE="CLOSED"

inherit allarch

do_install() {
    install -d ${D}${datadir}/cockpit/
    # Insert whiteout file
    for hideplugin in docker general-settings iotedge-docker onboard terminal; do
        mknod -m 0666 ${D}${datadir}/cockpit/$hideplugin c 0 0
    done
}

# Add plugin removal packages manually, as PACKAGES_DYNAMIC does not work with
# special files (only with regular files, dirs and links)
PACKAGES = "${PN}-remove-docker ${PN}-remove-general-settings ${PN}-remove-iotedge-docker \
            ${PN}-remove-onboarding ${PN}-remove-terminal"

FILES_${PN}-remove-docker = "${datadir}/cockpit/docker"
FILES_${PN}-remove-general-settings = "${datadir}/cockpit/general-settings"
FILES_${PN}-remove-iotedge-docker = "${datadir}/cockpit/iotedge-docker"
FILES_${PN}-remove-onboarding = "${datadir}/cockpit/onboard"
FILES_${PN}-remove-terminal = "${datadir}/cockpit/terminal"
