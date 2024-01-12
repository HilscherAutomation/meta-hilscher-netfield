DRIVER_VERSION="1.0.5.0"
SRC_URI = "file://netanalyzerdriver-${DRIVER_VERSION}.tar.bz2"
SRC_URI[sha256sum] = "b1b057585e4284fc13d6b0efdba663b4f123281e7e5e79fabde0e8efcc2346bf"

S = "${WORKDIR}/netanalyzerdriver-${DRIVER_VERSION}"
PV ??= "${DRIVER_VERSION}"
