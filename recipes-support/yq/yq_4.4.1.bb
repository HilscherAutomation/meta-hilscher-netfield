SUMMARY="A lightweight and portable command-line YAML processor"
HOMEPAGE="https://github.com/mikefarah/yq"
LICENSE="MIT"

LIC_FILES_CHKSUM="file://src/${GO_IMPORT}/LICENSE;md5=090d381b4b3eb93194e8cbff4aaae2de"

SRC_URI = "git://${GO_IMPORT}.git;nobranch=1"
SRCREV = "917fd0eb6a857fca69a582a0efb3e20708c5876f"

GO_IMPORT = "github.com/mikefarah/yq"

inherit go-mod

# Remove binaries from git, which result in sysroot errors on non intel platforms:
#  | sysroot-destdir/usr/lib/go/src/github.com/mikefarah/yq/yqt: file format not recognized
do_unpack_append() {
    s = d.getVar('S', True)
    goimport = d.getVar('GO_IMPORT', True)
    os.unlink(os.path.join(s, 'src', goimport, 'yqt'))
}

do_install_append() {
    # Delete library stuff, which is not needed, as we only need to cli
    rm -r ${D}${libdir}
}
