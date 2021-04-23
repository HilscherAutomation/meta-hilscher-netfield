########################################
# Anonymous python function for firmware version handling
########################################
python() {
    import re

    version = d.getVar('FIRMWARE_VERSION')

    # Validate FIRMWARE_VERSION string
    if version is None:
        bb.fatal("No Firmware version defined. Please set FIRMWARE_VERSION (e.g. '1.0.0.0') in either local.conf or BSP layer.conf")

    # Check for invalid characters
    if '/' in version:
        bb.fatal('Invalid character ("/") found in FIRMWARE_VERSION. As the version is used for filename it must not contain path separators.')

    # Append .debug on debug builds, if not already done
    if 'debug-tweaks' in d.getVar('IMAGE_FEATURES').split():
        if '.debug' not in version:
            match = re.search('^(\d+)\.(\d+)\.(\d+)\.(\d+)(.*)', version)
            if not match:
                bb.warn('Unable to split version string. Simply adding .debug to end of full version')
                version = version + '.debug'
            else:
                version = '.'.join(match.group(1,2,3,4)) + '.debug' + match.group(5)

    bb.debug(1, 'Setting full firmware version to %r' % version)
    d.setVar('FULL_FW_VERSION', version)
}
