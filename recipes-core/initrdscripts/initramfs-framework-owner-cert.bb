SUMMARY = "Load and install owner-certificate"
HOMEPAGE = "www.hilscher.com"
LICENSE = "CLOSED"

LIC_FILES_CHKSUM = ""

RDEPENDS_${PN} = "pub-key-loader"

SRC_URI =  "file://owner_cert"

S = "${WORKDIR}"

do_install () {
  install -d ${D}/init.d
  install -m 500 ${S}/owner_cert ${D}/init.d/01-owner_cert
}

FILES_${PN} = "/init.d"
