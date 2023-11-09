FILESEXTRAPATHS:prepend := "${THISDIR}/audit-rules:"

SRC_URI:append = " file://30-basic-configuration.rules"

DEFAULT_RULESET="\
    10-base-config.rules \
    11-loginuid.rules \
    30-basic-configuration.rules \
    30-nispom.rules \
    30-ospp-v42-1-create-failed.rules 30-ospp-v42-1-create-success.rules \
    30-ospp-v42-2-modify-failed.rules 30-ospp-v42-2-modify-success.rules \
    30-ospp-v42-4-delete-failed.rules 30-ospp-v42-4-delete-success.rules \
    30-ospp-v42-5-perm-change-failed.rules   \
    30-ospp-v42-5-perm-change-success.rules  \
    30-ospp-v42-6-owner-change-failed.rules  \
    30-ospp-v42-6-owner-change-success.rules \
    30-ospp-v42.rules \
    30-pci-dss-v31.rules \
    31-privileged.rules \
    99-finalize.rules \
"

do_install:append() {
    sed -i -e 's/^#-e/-e/g' ${D}${datadir}/audit/sample-rules/99-finalize.rules

    install -m 0640 ${WORKDIR}/30-basic-configuration.rules ${D}${datadir}/audit/sample-rules/
    for rule in ${DEFAULT_RULESET}; do
        [ ! -e "${D}${datadir}/audit/sample-rules/$rule" ] && bbfatal "Unable to enable missing rule '$rule'"
        ln -sf ${datadir}/audit/sample-rules/$rule ${D}${sysconfdir}/audit/rules.d/$rule
    done
}
