SUMMARY="Define and run multi-container applications with Docker"
HOMEPAGE="https://docs.docker.com/compose/"
LICENSE="Apache-2.0"

GO_IMPORT="github.com/docker/compose"
COMPOSE_PKG = "github.com/docker/compose/v2"

SRC_URI="git://${GO_IMPORT};protocol=https;branch=v2 \
         file://modules.txt"
SRCREV="8318f66330358988a058bf611a953f464ab7973f"

include src_uri.inc

LIC_FILES_CHKSUM="file://src/${GO_IMPORT}/LICENSE;md5=175792518e4ac015ab6696d16c4f607e"

inherit go goarch

DEPENDS="rsync-native"
include relocations.inc

do_compile() {
	cd ${S}/src/${GO_IMPORT}

	export GOPATH="$GOPATH:${S}/src/import/.gopath"

	# Pass the needed cflags/ldflags so that cgo
	# can find the needed headers files and libraries
	export GOARCH=${TARGET_GOARCH}
	export CGO_ENABLED="1"
	export CGO_CFLAGS="${CFLAGS} --sysroot=${STAGING_DIR_TARGET}"
	export CGO_LDFLAGS="${LDFLAGS} --sysroot=${STAGING_DIR_TARGET}"

	export GOFLAGS="-mod=vendor -trimpath"

	# our copied .go files are to be used for the build
	rm -f vendor
	ln -sf ${S}/src/import/vendor.copy vendor
	# inform go that we know what we are doing
	cp ${WORKDIR}/modules.txt vendor/

	GO_LDFLAGS="-s -w -X internal.Version=${PV} -X ${COMPOSE_PKG}/internal.Version=${PV}"
	GO_BUILDTAGS=""
	mkdir -p ./bin
	${GO} build $GOFLAGS -tags "$GO_BUILDTAGS" -ldflags "$GO_LDFLAGS" -o ${B}/bin/docker-compose ./cmd
}

do_install() {
	# commonly installed to: /usr/lib/docker/cli-plugins/
	install -d "${D}${libdir}/docker/cli-plugins/"
	install -m 755 "${B}/bin/docker-compose" "${D}${libdir}/docker/cli-plugins/"

	# Make sure that docker-compose works as well as docker compose
	install -d "${D}${bindir}"
	ln -s ${libdir}/docker/cli-plugins/docker-compose ${D}${bindir}/docker-compose
}

INHIBIT_PACKAGE_DEBUG_SPLIT="1"
INHIBIT_PACKAGE_STRIP = "1"
INSANE_SKIP_${PN} += "ldflags already-stripped"

FILES_${PN} = "${libdir} ${bindir}"
RDEPENDS_${PN} = "docker"
