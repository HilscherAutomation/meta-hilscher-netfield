do_install:append() {
  install -d -m 0775 -g cifx ${D}/opt/cifx/deviceconfig/FW
  cat <<EOF> ${D}/opt/cifx/deviceconfig/FW/device.conf
eth=yes
dma=no
irq=no
EOF
}
