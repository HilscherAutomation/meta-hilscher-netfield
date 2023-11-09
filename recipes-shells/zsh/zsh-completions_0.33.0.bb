SUMMARY="Additional completion definitions for Zsh."
HOMEPAGE="https://github.com/zsh-users/zsh-completions"
LICENSE="zsh"

SRC_URI = "git://github.com/zsh-users/zsh-completions.git;protocol=https"
SRCREV = "11ad0a45ff1695cac00e86c687cce6fa1fd1cdbd"

LIC_FILES_CHKSUM = "file://LICENSE;md5=26b9ce7bfd3731f0df81909b2d90129b"

S="${WORKDIR}/git"

PACKAGES="${PN}"

do_install() {
    install -d ${D}${datadir}/zsh/site-functions
    cp ${S}/src/* ${D}${datadir}/zsh/site-functions/
    chmod 0644 ${D}${datadir}/zsh/site-functions/*
}

FILES:${PN} = "${datadir}/zsh"
