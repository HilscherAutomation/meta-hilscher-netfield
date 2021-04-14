# Disable IPv6 support for libupnp, otherwise upnpd binds to all ipv6 
# addresses, making it impossible to run multiple instances (one per if)
EXTRA_OECONF_append += "--disable-ipv6"

# Dump to 1.14.0 to fix CVE-2020-13848 found in 1.12.1 and earlier
PV = "1.14.0+git${SRCPV}"
SRCREV = "a6c3616530490ca67db41131572ec18f00d95eb0"

inherit pkgconfig
