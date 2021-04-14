DRIVER_VERSION="1.0.4.0"

SRC_URI = "file://${BPN}_${PV}.tar.gz"

S = "${WORKDIR}/${BPN}_${PV}"

require netanalyzer-firmware.inc
