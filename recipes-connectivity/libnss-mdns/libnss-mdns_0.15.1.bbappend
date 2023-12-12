pkg_postinst:${PN} () {
        sed '
                /^hosts:/ !b
                /\<mdns\(4\|6\)\?\(_minimal\)\?\>/ b
                s/\([[:blank:]]\+\)dns\>/\1mdns4_minimal dns/g
                ' -i $D${sysconfdir}/nsswitch.conf
}

pkg_prerm:${PN} () {
        sed '
                /^hosts:/ !b
                s/[[:blank:]]\+mdns\(4\|6\)\?\(_minimal\( \)\?\)\?//g
                ' -i $D${sysconfdir}/nsswitch.conf
}
