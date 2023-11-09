do_install:append() {
    mkdir -p ${D}${sysconfdir}/default/
    echo 'ZRAM_SIZE_PERCENT=50' > ${D}${sysconfdir}/default/zram
    echo 'ZRAM_ALGORITHM=lz4' >> ${D}${sysconfdir}/default/zram
}
