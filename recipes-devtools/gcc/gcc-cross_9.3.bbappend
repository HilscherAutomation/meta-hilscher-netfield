# TODO: For some reason a append in distro.conf does not work
#  CVE_CHECK_WHITELIST_append_pn-gcc-source-9.3.0 += "CVE-2019-15847"

# CVE-2019-15847 only affects PowerPC and GCC < 10, as we are not PowerPC whitelist it
CVE_CHECK_WHITELIST_append += "CVE-2019-15847"
