FILESEXTRAPATHS_prepend := "${THISDIR}/${PN}:"

SRC_URI_append += "file://do_not_embed_pubkeys.patch"

# crda tries to access /lib/crda/regulatory.bin which comes from wireless-regdb
RDEPENDS_${PN}_append += "wireless-regdb"

DEPENDS_append += "openssl"
DEPENDS_remove += "libgcrypt"

EXTRA_OEMAKE_append += "USE_OPENSSL=1 RUNTIME_PUBKEY_ONLY=1"
