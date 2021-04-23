FILESEXTRAPATHS_prepend := "${THISDIR}/files:"
# Apply fix to avoid hanging with
#  WARNING: Device /dev/ram0 not initialized in udev database even after waiting 10000000 microseconds.
# if udev is not running yet, which is the case in initrd for example
#
# see https://bugzilla.redhat.com/show_bug.cgi?id=1676612
#
# NOTE: Since dunfell (lvm 2.03.06) this fix is already integrated
SRC_URI_append += "${@ 'file://0001-apply-obtain_device_list_from_udev-to-all-libudev-us.patch' if d.getVar("PV") < "2.03.06" else ''}"
