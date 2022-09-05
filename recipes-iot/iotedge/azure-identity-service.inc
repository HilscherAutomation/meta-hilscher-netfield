SUMMARY = "iotedge - Azure IoTEdge identity client"
HOMEPAGE = "https://github.com/Azure/iot-identity-service"
LICENSE = "MIT"
LIC_FILES_CHKSUM="file://LICENSE;md5=4f9c2c296f77b3096b6c11a16fa7c66e"

DEPENDS_append += "libstd-rs openssl"

inherit systemd
SYSTEMD_AUTO_ENABLE = "enable"
# NOTE: We are only selecting the socket services to auto-enable them, so they can be socket-activated by aziot-edged
SYSTEMD_SERVICE_${PN} = " \
    aziot-certd.socket \
    aziot-identityd.socket \
    aziot-keyd.socket \
    aziot-tpmd.socket \
"

inherit useradd
USERADD_PACKAGES="${PN}"
# Users taken from debian/preinst script
USERADD_PARAM_${PN} = " \
    --system --no-create-home --home-dir /var/lib/aziot/keyd --shell /sbin/nologin --user-group --groups iotedge aziotks; \
    --system --no-create-home --home-dir /var/lib/aziot/certd --shell /sbin/nologin --user-group --groups iotedge,aziotks aziotcs; \
    --system --no-create-home --home-dir /var/lib/aziot/tpmd --shell /sbin/nologin --user-group --groups iotedge aziottpm; \
    --system --no-create-home --home-dir /var/lib/aziot/identityd --shell /sbin/nologin --user-group --groups iotedge,aziotcs,aziottpm,aziotks aziotid; \
"
GROUPADD_PARAM_${PN} = "-r docker;-r iotedge;"

DEPENDS += "cbindgen-native bindgen-native clang-native jq-native \
            tpm2-tss"

SRC_URI += " \
    file://makefile_override_target.patch \
    file://rust_hack_panicmode.patch \
    file://makefile_install_without_build.patch \
    file://third_party_pass_platform.patch \
    file://third_party_skip_download.patch \
    https://github.com/hannobraun/inotify/raw/52c18c527fe227b329f8428d73a1c732f2d56ce5/LICENSE;downloadfilename=inotify-LICENSE;name=inotifylicense \
    https://github.com/notify-rs/notify/raw/e0982ffc760bc0e34544d2a7c9d10cdba65183d9/LICENSE;downloadfilename=notify-LICENSE;name=notifylicense \
"
SRC_URI[inotifylicense.sha256sum] = "7f78b31de4e7a3e2ac8de40e2b409eda313f03637aa62b8416fbde9bdc5ce4c9"
SRC_URI[notifylicense.sha256sum] = "e0456cbab4f7b5e7203e678faff37eadbdfef02e822db3b7a52a1dd9d3dc514a"

EXTRA_OEMAKE="RELEASE=1 CARGO_TARGET=${HOST_SYS} RUSTFLAGS='${RUSTLIB} ${RUST_DEBUG_REMAP}' \
    localstatedir=${localstatedir} sysconfdir=${sysconfdir} unitdir=${systemd_system_unitdir}"

do_configure_prepend() {
    # Delete tpm2-tss as we are using the one provided by meta-hilscher-netfield
    rm -rf ${S}/third-party/tpm2-tss
}

do_compile() {
    export RUST_TARGET_PATH="${RUST_TARGET_PATH}"
    export LLVM_CONFIG_PATH="${STAGING_LIBDIR_NATIVE}/llvm-rust/bin/llvm-config"
    export LIBCLANG_PATH="${STAGING_LIBDIR_NATIVE}"
    export FORCE_NO_UNITTEST="yes"

    cd ${B}
    mkdir -p ${B}/tmp
    export TMPDIR="${B}/tmp"
    cd ${S}
    oe_runmake
    # Generate 3rd Party Notices
    export platform="${HOST_SYS}"
    cp ${WORKDIR}/inotify-LICENSE ${CARGO_HOME}/bitbake/inotify-0.7.1/LICENSE-ISC
    cp ${WORKDIR}/notify-LICENSE ${CARGO_HOME}/bitbake/notify-4.0.17/LICENSE-CC0
    contrib/third-party-notices.sh > THIRD-PARTY-NOTICES
}

do_install() {
    cd ${S}

    # Makefile cannot be run correct with S!=B, thus link $B to target where install step expects binaries
    rm -f ${S}/target
    ln -s ${B}/target ${S}/target

    oe_runmake -f ${S}/Makefile DESTDIR=${D} install-deb

    # Adjust permissions (taken from debian/postinst script)
    chown -R aziotcs:aziotcs ${D}${sysconfdir}/aziot/certd/
    chown -R aziotid:aziotid ${D}${sysconfdir}/aziot/identityd/
    chown -R aziotks:aziotks ${D}${sysconfdir}/aziot/keyd/
    chown -R aziottpm:aziottpm ${D}${sysconfdir}/aziot/tpmd/

    chmod 0400 ${D}${sysconfdir}/aziot/certd/config.toml.default
    chmod 0400 ${D}${sysconfdir}/aziot/identityd/config.toml.default
    chmod 0400 ${D}${sysconfdir}/aziot/keyd/config.toml.default
    chmod 0400 ${D}${sysconfdir}/aziot/tpmd/config.toml.default
    chmod 0600 ${D}${sysconfdir}/aziot/config.toml.template

    chown aziotcs:aziotcs ${D}${localstatedir}/lib/aziot/certd
    chown aziotid:aziotid ${D}${localstatedir}/lib/aziot/identityd
    chown aziotks:aziotks ${D}${localstatedir}/lib/aziot/keyd
    chown aziottpm:aziottpm ${D}${localstatedir}/lib/aziot/tpmd
    chmod 0700 ${D}${localstatedir}/lib/aziot/certd
    chmod 0700 ${D}${localstatedir}/lib/aziot/identityd
    chmod 0700 ${D}${localstatedir}/lib/aziot/keyd
    chmod 0700 ${D}${localstatedir}/lib/aziot/tpmd
}

RDEPENDS_${PN} = "aziot-edge"
FILES_${PN} += "${libdir}"
FILES_${PN}-dev = "${includedir}"
INHIBIT_PACKAGE_DEBUG_SPLIT="1"
