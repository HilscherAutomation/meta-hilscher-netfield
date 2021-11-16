do_check_module_signature() {
    if [ -e "${IMAGE_ROOTFS}/lib/modules" ]; then
        module_list=$(find ${IMAGE_ROOTFS}/lib/modules/ -name '*.ko')
        for module in $module_list; do
            if ! grep -q "~Module signature appended~" "$module"; then
                bbfatal "Found unsigned module $module. This module cannot be loaded by the kernel, aborting build!"
            fi
       done
    fi
}

ROOTFS_POSTPROCESS_COMMAND_append += "${@bb.utils.contains('PLATFORM_SIGN', '1', 'do_check_module_signature ;', '', d)}"
