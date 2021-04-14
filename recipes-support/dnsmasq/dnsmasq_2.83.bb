require dnsmasq.inc

SRC_URI[dnsmasq-2.83.sha256sum] = "6b67955873acc931bfff61a0a1e0dc239f8b52e31df50e9164d3a4537571342f"
SRC_URI += "\
    file://lua.patch \
"
