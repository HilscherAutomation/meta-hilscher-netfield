# Disable IPv6 support for libupnp, otherwise upnpd binds to all ipv6 
# addresses, making it impossible to run multiple instances (one per if)
EXTRA_OECONF:append = " --disable-ipv6"
