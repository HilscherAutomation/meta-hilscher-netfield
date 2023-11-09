# The following patch collides with out used busybox which only supports -t but not --tmpdir
SRC_URI:remove = "file://update-ca-certificates-support-Toybox.patch"

do_install:append() {
    install -d ${D}/usr/local/share/ca-certificates
}

FILES:${PN}:append = " /usr/local/share/ca-certificates"
