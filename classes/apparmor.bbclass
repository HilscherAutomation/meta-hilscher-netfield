# bbclass to support easy installation of apparmor rules
# rules will be automatically installed to correct location
# and loaded prior to installation

RDEPENDS_${PN}_append += "apparmor"

APPARMOR_PROFILES_ADDITIONAL ??= ""
APPARMOR_PROFILES_TARGET     ??= ""

pkg_postinst_${PN}_prepend() {
    apparmor_profiles="${APPARMOR_PROFILES_TARGET}"

    if ${@bb.utils.contains('DISTRO_FEATURES','apparmor','true','false',d)}; then
        if [ -z "$D" ]; then
            for profile in $apparmor_profiles; do
                apparmor_parser -r ${sysconfdir}/apparmor.d/$profile
            done
        fi
    fi
}

pkg_prerm_${PN}_prepend() {
    apparmor_profiles="${APPARMOR_PROFILES_TARGET}"

    if ${@bb.utils.contains('DISTRO_FEATURES','apparmor','true','false',d)}; then
        if [ -z "$D" ]; then
            for profile in $apparmor_profiles; do
                apparmor_parser -R ${sysconfdir}/apparmor.d/$profile
            done
        fi
    fi
}

do_install_append() {
    if ${@bb.utils.contains('DISTRO_FEATURES','apparmor','true','false',d)}; then
	profiles="${APPARMOR_PROFILES} ${APPARMOR_PROFILES_ADDITIONAL}"
        for profile in $profiles; do
            if [ $(echo $profile | grep ":") ]; then 
                profile_local=$(echo $profile | cut -d ":" -f1)
                profile_target=$(echo $profile | cut -d ":" -f2)
            else
                profile_local=$profile
                profile_target=$profile_local
            fi

            basedir=$(dirname $profile_target)
            fname=$(basename $profile_target)

            install -d ${D}${sysconfdir}/apparmor.d/$basedir
            install -m 644 ${WORKDIR}/$profile_local ${D}${sysconfdir}/apparmor.d/$basedir/$fname

            # Make sure rule contains attach_disconnected
            if ! grep -q -e '^profile .* flags=.* {$' -e '^/ .* flags=.* {$' ${D}${sysconfdir}/apparmor.d/$basedir/$fname ; then
                sed -i \
                    -e 's;\(^profile .*\) {$;\1 flags=(attach_disconnected) {;g' \
                    -e 's;\(^/.*\) {$;\1 flags=(attach_disconnected) {;g' \
                    ${D}${sysconfdir}/apparmor.d/$basedir/$fname
            fi
        done
    fi
}

python __anonymous () {
    # Determine installed apparmor profiles
    for prof_types in ["APPARMOR_PROFILES", "APPARMOR_PROFILES_ADDITIONAL"]:
        for tmp in d.getVar(prof_types, True).split():
            if ":" in tmp:
                prof_local = tmp.split(":")[0]
                prof_target = tmp.split(":")[1]
            else:
                prof_target = prof_local = tmp

            d.appendVar("%s_TARGET" % prof_types, prof_target)
            d.appendVar("SRC_URI", " file://" + prof_local)
}

FILES_${PN}_append += "${sysconfdir}/apparmor.d"
