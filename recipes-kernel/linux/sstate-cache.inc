# Enable the usage of sstate chache for kernel compile tasks!

SSTATETASKS += "do_compile"
do_compile[sstate-plaindirs] = "${B}"
python do_compile_setscene () {

    # To avoid overwriting the build directory,
    # test if do_compile_kernelmodules_setscene task was already run.
    if not os.path.isdir(d.getVar('B')):
        sstate_setscene(d)
}
addtask do_compile_setscene

SSTATETASKS += "do_compile_kernelmodules"
do_compile_kernelmodules[sstate-plaindirs] = "${B} ${STAGING_KERNEL_DIR}"
python do_compile_kernelmodules_setscene () {
    sstate_setscene(d)
}
addtask do_compile_kernelmodules_setscene

# HACK: When building clean and saving do_compile to sstate
#       libgcc-initial might get linked it and resulting in duplicate files in sysroot crtbegint.o
#       This is due to an existing manifest for libgcc-initial which does not exist without the compile sstate steps
python remove_gcc_initial () {
    import os

    gcc_manifest="%s/manifest-%s-libgcc.populate_sysroot" % (d.getVar('SSTATE_MANIFESTS', True), d.getVar('TUNE_PKGARCH', True))
    gcc_initial_manifest="%s/manifest-%s-libgcc-initial.populate_sysroot" % (d.getVar('SSTATE_MANIFESTS', True), d.getVar('TUNE_PKGARCH', True))

    if os.path.exists(gcc_manifest) and os.path.exists(gcc_initial_manifest):
        bb.warn("Deleting initial manifest")
        os.unlink(gcc_initial_manifest)
}
do_prepare_recipe_sysroot[prefuncs] += " remove_gcc_initial "

# Add required build dependencies for do_assemble_fitimage_setscene and do_assemble_fitimage_initramfs_setscene.
python () {
    kerneltypes = d.getVar('KERNEL_IMAGETYPES') or ""
    if 'fitImage' in kerneltypes:
        d.appendVarFlag('do_assemble_fitimage', 'depends', ' virtual/${TARGET_PREFIX}binutils:do_populate_sysroot')
        image = d.getVar('INITRAMFS_IMAGE') or ""
        if image:
            d.appendVarFlag('do_assemble_fitimage_initramfs', 'depends', ' virtual/${TARGET_PREFIX}binutils:do_populate_sysroot')
}
