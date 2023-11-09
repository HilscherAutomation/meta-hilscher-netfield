PACKAGES =+ "${PN}-lsconfig"

do_compile:append() {
    ${CC} ${CFLAGS} ${LDFLAGS} -I./lib -L./lib/.libs -o ${B}/ls-config contrib/ls-config/src/ls-config.c -lm -lconfig
}

do_install:append() {
    install -d ${D}${bindir}
    install ${B}/ls-config ${D}${bindir}
}

FILES:${PN}-lsconfig = "${bindir}/ls-config"

BBCLASSEXTEND = "native"
