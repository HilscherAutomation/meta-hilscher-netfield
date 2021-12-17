FILESEXTRAPATHS_prepend := "${THISDIR}/audit-rules:"

SRC_URI_append += "file://30-basic-configuration.rules"

DEFAULT_RULESET="\
    30-basic-configuration.rules \
    30-nispom.rules \
    30-ospp-v42.rules \
    30-pci-dss-v31.rules \
    31-privileged.rules \
    99-finalize.rules \
"

do_install_append() {
    sed -i -e 's/^#-e/-e/g' ${D}${datadir}/audit/sample-rules/99-finalize.rules

    install -m 0640 ${WORKDIR}/30-basic-configuration.rules ${D}${datadir}/audit/sample-rules/
    for rule in ${DEFAULT_RULESET}; do
        ln -s ${datadir}/audit/sample-rules/$rule ${D}${sysconfdir}/audit/rules.d/$rule
    done
}
