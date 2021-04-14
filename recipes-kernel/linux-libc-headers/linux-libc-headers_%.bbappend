# For some reason linux-libc-headers has a machine dependency
# which results in rebuilding glibc and every application if MACHINE changes
# linux-libc-headers is meant to be used machine independent.
# This comes from STAGING_KERNEL_DIR which is machine dependent (work-shared/${MACHINE}/kernel-source)
#   sstate-diff-machine.sh --tmpdir=build_intel/tmp/ --targets=linux-libc-headers --machines="niot-e-tijcx-gb niot-e-tib100"
#   bitbake-diffsigs 4.18-r0.do_configure.sigdata.91984f9ef1fb7888b2ff3584b6c81369 4.18-r0.do_configure.sigdata.aa594847e79cf6ede0276cb3f36be044
#     - basehash changed from 7c525b6e5adfc96eeef942dcf76656f1 to acb2413740de205fef9cd26528eb3a1a
#     - Variable MACHINE value changed from 'niot-e-tijcx-gb' to 'niot-e-tib100'
#   bitbake-dumpsig 4.18-r0.do_configure.sigdata.aa594847e79cf6ede0276cb3f36be044  | grep MACHINE
#     - Variable STAGING_KERNEL_DIR value is ${TMPDIR}/work-shared/${MACHINE}/kernel-source
#
# Make this recipe machine independent#
STAGING_KERNEL_DIR[vardepsexclude] += "MACHINE"
