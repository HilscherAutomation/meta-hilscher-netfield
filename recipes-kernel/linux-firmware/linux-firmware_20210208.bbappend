# linux-firmware-bcm4339 pulls in complete linux-firmware package after update
# as the file is not correctly packaged:
#   DEBUG: linux-firmware-bcm4339 contains dangling link /lib/firmware/cypress/cyfmac4339-sdio.bin
#   DEBUG: target found in linux-firmware
FILES_${PN}-bcm4339_append += "${nonarch_base_libdir}/firmware/cypress/cyfmac4339-sdio.bin"
FILES_${PN}-bcm43340_append += "${nonarch_base_libdir}/firmware/cypress/cyfmac43340-sdio.bin \
                                ${nonarch_base_libdir}/firmware/cypress/cyfmac43340-sdio.clm_blob"
FILES_${PN}-bcm43362_append += "${nonarch_base_libdir}/firmware/cypress/cyfmac43362-sdio.bin"
FILES_${PN}-bcm43430_append += "${nonarch_base_libdir}/firmware/cypress/cyfmac43430-sdio.bin \
                                ${nonarch_base_libdir}/firmware/cypress/cyfmac43430-sdio.clm_blob"
FILES_${PN}-bcm43455_append += "${nonarch_base_libdir}/firmware/cypress/cyfmac43455-sdio.bin \
                                ${nonarch_base_libdir}/firmware/cypress/cyfmac43455-sdio.clm_blob"
FILES_${PN}-bcm4354_append += "${nonarch_base_libdir}/firmware/cypress/cyfmac4354-sdio.bin"
FILES_${PN}-bcm4356_append += "${nonarch_base_libdir}/firmware/cypress/cyfmac4356-sdio.bin"
FILES_${PN}-bcm4356-pcie_append += "${nonarch_base_libdir}/firmware/cypress/cyfmac4356-pcie.bin \
                                   ${nonarch_base_libdir}/firmware/cypress/cyfmac4356-pcie.clm_blob"
FILES_${PN}-bcm43570_append += "${nonarch_base_libdir}/firmware/cypress/cyfmac43570-pcie.bin"
FILES_${PN}-bcm4373_append += "${nonarch_base_libdir}/firmware/cypress/cyfmac4373-sdio.bin"
FILES_${PN}-netronome_append += "${nonarch_base_libdir}/firmware/netronome/bpf \
                                 ${nonarch_base_libdir}/firmware/netronome/flower \
                                 ${nonarch_base_libdir}/firmware/netronome/nic \
                                 ${nonarch_base_libdir}/firmware/netronome/nic-sriov \
                                 ${nonarch_base_libdir}/firmware/netronome/nic_AMDA0058-0011_2x40.nffw \
                                 ${nonarch_base_libdir}/firmware/netronome/nic_AMDA0058-0012_2x40.nffw \
                                 ${nonarch_base_libdir}/firmware/netronome/nic_AMDA0078-0011_1x100.nffw"
