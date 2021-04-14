SUMMARY="Initrd-helpers contains scripts and tools that can be used in init ramdisks."
HOMEPAGE="https://github.com/sailfishos/initrd-helpers"
LICENSE="GPLv2"

LIC_FILES_CHKSUM="file://LICENSE;md5=b234ee4d69f5fce4486a80fdaf4a4263"

SRC_URI="git://github.com/sailfishos/initrd-helpers.git;protocol=https \
	 file://remove_warning.patch"
SRCREV="0b07304988171998953158d4deb41f21d40f7980"

S="${WORKDIR}/git"

inherit allarch

do_install() {
	install -d ${D}${bindir}
	install ${S}/btrfs-mount-repair  ${D}${bindir}
}

FILES_${PN} = "${bindir}"
