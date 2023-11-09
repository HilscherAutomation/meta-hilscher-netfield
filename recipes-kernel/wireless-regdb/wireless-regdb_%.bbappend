# Allow installing wireless-regdb together with wireless-regdb-static
RCONFLICTS:${PN}:remove = "${PN}-static"
