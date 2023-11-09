# Make sure rpcbind does not start automatically,
# as it will expose a possible vulnerable port
SYSTEMD_AUTO_ENABLE:${PN} = "disable"
