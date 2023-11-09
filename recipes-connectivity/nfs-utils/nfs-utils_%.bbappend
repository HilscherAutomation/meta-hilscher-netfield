# Make sure client utils don't start automatically,
# as they will expose a possible vulnerable port
SYSTEMD_AUTO_ENABLE:${PN}-client = "disable"
