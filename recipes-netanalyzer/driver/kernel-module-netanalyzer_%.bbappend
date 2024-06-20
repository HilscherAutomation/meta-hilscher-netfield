# Make sure package signing works correctly
inherit sign-wrapper
INHIBIT_PACKAGE_STRIP="1"
EXTRA_OEMAKE += "INSTALL_MOD_STRIP=1"
