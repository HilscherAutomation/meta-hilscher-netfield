# The following patch collides with out used busybox which only supports -t but not --tmpdir
SRC_URI_remove += "file://update-ca-certificates-support-Toybox.patch"

do_install_append() {
    install -d ${D}/usr/local/share/ca-certificates
}

FILES_${PN}_append += "/usr/local/share/ca-certificates"
