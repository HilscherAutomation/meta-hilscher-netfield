SUMMARY="FSArchiver is a system tool that allows you to save the contents of a file-system to a compressed archive file."
HOMEPAGE="http://www.fsarchiver.org/"
LICENSE="GPLv2"

LIC_FILES_CHKSUM="file://COPYING;md5=cbbd794e2a0a289b9dfcc9f513d1996e"

inherit autotools pkgconfig

SRC_URI = "https://github.com/fdupoux/fsarchiver/releases/download/0.8.5/fsarchiver-0.8.5.tar.gz"
SRC_URI[sha256sum] = "c694f52e42703d7e8c4d56f2db97a8ff5616df1d723429126de97c22217c88fe"

DEPENDS = "libgcrypt e2fsprogs"

RDEPENDS_${PN}="e2fsprogs-tune2fs"

PACKAGECONFIG ??= "gz bz2 xz lzo lz4"
PACKAGECONFIG[gz]=",--disable-zlib,zlib"
PACKAGECONFIG[bz2]=",--disable-bzip2,bzip2"
PACKAGECONFIG[xz]=",--disable-lzma,xz"
PACKAGECONFIG[lzo]=",--disable-lzo,lzo"
PACKAGECONFIG[lz4]=",--disable-lz4,lz4"
PACKAGECONFIG[zstd]=",--disable-zstd,zstd"
