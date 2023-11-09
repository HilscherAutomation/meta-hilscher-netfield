SUMMARY = "Programmable Completion for Bash 4"
HOMEPAGE = "http://bash-completion.alioth.debian.org/"
BUGTRACKER = "https://alioth.debian.org/projects/bash-completion/"

LICENSE = "GPLv2"
LIC_FILES_CHKSUM = "file://COPYING;md5=751419260aa954499f7abaabaa882bbe"

SECTION = "console/utils"

SRC_URI = "git://github.com/scop/bash-completion.git;protocol=https"
SRCREV = "7c81ef895455d0f7543c65789ff62808e7465578"
S = "${WORKDIR}/git"

PARALLEL_MAKE = ""

inherit autotools

RDEPENDS:${PN} = "bash"

# Some recipes are providing ${PN}-bash-completion packages
PACKAGES =+ "${PN}-extra"
FILES:${PN}-extra = "${datadir}/${BPN}/completions/ \
    ${datadir}/${BPN}/helpers/"

FILES:${PN}-dev += "${datadir}/cmake"

BBCLASSEXTEND = "nativesdk"
