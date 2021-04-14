SUMMARY="Additional completion definitions for Zsh."
HOMEPAGE="https://github.com/zsh-users/zsh-completions"
LICENSE="zsh"

SRC_URI = "git://github.com/zsh-users/zsh-completions.git;protocol=https"
SRCREV = "cf565254e26bb7ce03f51889e9a29953b955b1fb"

LIC_FILES_CHKSUM = "file://LICENSE;md5=26b9ce7bfd3731f0df81909b2d90129b"

S="${WORKDIR}/git"

PACKAGES="${PN}"

do_install() {
    install -d ${D}${datadir}/zsh/site-functions
    cp ${S}/src/* ${D}${datadir}/zsh/site-functions/
    chmod 0644 ${D}${datadir}/zsh/site-functions/*
}

FILES_${PN} = "${datadir}/zsh"
