do_install:append() {
    # Make sure users of group sudo can actually use sudo
    sed -i 's/# \(%sudo.*\)/\1/' ${D}${sysconfdir}/sudoers
}
