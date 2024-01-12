SUMMARY = "netANALYZER device driver for Hilscher netANALYZER devices"
HOMEPAGE = "www.hilscher.com"
LICENSE = "CLOSED"

inherit autotools

require driver_version.inc

S .= "/libnetana"

RDEPENDS:${PN} = "kernel-module-netanalyzer"

PR="r1"
