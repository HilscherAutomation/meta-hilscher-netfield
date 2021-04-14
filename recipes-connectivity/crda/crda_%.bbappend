# crda tries to access /lib/crda/regulatory.bin which comes from wireless-regdb
RDEPENDS_${PN}_append += "wireless-regdb"
