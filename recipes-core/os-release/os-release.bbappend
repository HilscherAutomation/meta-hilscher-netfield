inherit hilscher-firmware-version

python() {
    d.setVar('MAJOR_VERSION', '.'.join(d.getVar('FULL_FW_VERSION').split('.')[:2]))
}

# Setup ID, version, etc. according to requirement. Don't use distro settings,
# as this will render sstate-cache useless, resulting in rebuilds on every firmware version change
ID = "netfield"
NAME = "netFIELD OS"
VERSION = "${FULL_FW_VERSION}"
VERSION_ID = "${MAJOR_VERSION}"
PRETTY_NAME = "${NAME} ${VERSION}"
