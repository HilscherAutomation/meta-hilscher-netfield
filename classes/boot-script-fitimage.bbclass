inherit kernel-uboot uboot-sign kernel-arch

python __anonymous () {
    kerneltypes = d.getVar('KERNEL_IMAGETYPES', True) or ""
    if 'fitImage' in kerneltypes.split():
        depends = d.getVar("DEPENDS", True)
        depends = "%s u-boot-mkimage-native dtc-native" % depends
        d.setVar("DEPENDS", depends)

        # Verified boot will sign the fitImage and append the public key to
        # U-boot dtb. We ensure the U-Boot dtb is deployed before assembling
        # the fitImage:
        if d.getVar('UBOOT_SIGN_ENABLE', True):
            uboot_pn = d.getVar('PREFERRED_PROVIDER_u-boot', True) or 'u-boot'
            d.appendVarFlag('do_assemble_fitimage', 'depends', ' %s:do_deploy' % uboot_pn)
}

# Options for the device tree compiler passed to mkimage '-D' feature:
UBOOT_MKIMAGE_DTCOPTS ??= ""

#
# Emit the fitImage ITS header
#
# $1 ... .its filename
fitimage_emit_fit_header() {
	cat << EOF >> ${1}
/dts-v1/;

/ {
        description = "U-Boot shell script fitImage for ${DISTRO_NAME}/${PV}/${MACHINE}";
        #address-cells = <1>;
EOF
}

#
# Emit the fitImage section bits
#
# $1 ... .its filename
# $2 ... Section bit type: imagestart - image section start
#                          confstart  - configuration section start
#                          sectend    - section end
#                          fitend     - fitimage end
#
fitimage_emit_section_maint() {
	case $2 in
	imagestart)
		cat << EOF >> ${1}

        images {
EOF
	;;
	confstart)
		cat << EOF >> ${1}

        configurations {
EOF
	;;
	sectend)
		cat << EOF >> ${1}
	};
EOF
	;;
	fitend)
		cat << EOF >> ${1}
};
EOF
	;;
	esac
}

#
# Emit the fitImage ITS kernel section
#
# $1 ... .its filename
# $2 ... Image counter
# $3 ... Path to kernel image
# $4 ... Compression type
fitimage_emit_section_kernel() {
	kernel_csum="sha256"

	cat << EOF >> ${1}
                kernel@${2} {
                        description = "Linux kernel";
                        data = /incbin/("${3}");
                        type = "kernel";
                        arch = "${ARCH}";
                        os = "linux";
                        compression = "${4}";
                        load = <0>;
                        entry = <0>;
                        hash@1 {
                                algo = "${kernel_csum}";
                        };
                };
EOF
}

fitimage_emit_section_script() {

	kernel_csum="sha256"

	cat << EOF >> ${1}
                script@${2} {
                        description = "Boot script";
                        data = /incbin/("${3}");
                        type = "script";
                        arch = "${ARCH}";
                        os = "linux";
                        compression = "none";
                        load = <0x02000000>;
                        entry = <0x02000000>;
                        hash@1 {
                                algo = "${kernel_csum}";
                        };
                };
EOF
}

#
# Emit the fitImage ITS configuration section
#
# $1 ... .its filename
# $2 ... Linux kernel ID
# $3 ... DTB image ID
# $4 ... ramdisk ID
# $5 ... config ID
fitimage_emit_section_config() {
	conf_csum="sha1"
	conf_csum="sha256"
	if [ -n "${UBOOT_SIGN_ENABLE}" ] ; then
		conf_sign_keyname="${UBOOT_SIGN_KEYNAME}"
	fi

	# Test if we have any DTBs at all
	conf_desc="Linux kernel"
	kernel_line="kernel = \"kernel@1\";"
	boot_line=""

	if [ -n "${2}" ]; then
		conf_desc="${conf_desc}, script"
		boot_line="script = \"script@${2}\";"
	fi

	cat << EOF >> ${1}
                default = "conf@1";
                conf@1 {
                        description = "${conf_desc}";
			${kernel_line}
			${boot_line}
                        hash@1 {
                                algo = "${conf_csum}";
                        };
EOF

	if [ ! -z "${conf_sign_keyname}" ] ; then

		sign_line="sign-images = \"kernel\""

		if [ -n "${2}" ]; then
			sign_line="${sign_line}, \"script\""
		fi

		sign_line="${sign_line};"

		cat << EOF >> ${1}
                        signature@1 {
                                algo = "${conf_csum},rsa4096";
                                key-name-hint = "${conf_sign_keyname}";
				${sign_line}
                        };
EOF
	fi

	cat << EOF >> ${1}
                };
EOF
}

#
# Assemble fitImage
#
# $1 ... .its filename
# $2 ... fitImage name
# $3 ... include ramdisk
script_fitimage_assemble() {
	rm -f ${1} arch/${ARCH}/boot/${2}

	fitimage_emit_fit_header ${1}

	#
	# Step 1: Prepare a kernel image section.
	#
	fitimage_emit_section_maint ${1} imagestart

	#uboot_prep_kimage
	#NOTE: we do not have a kernel but mkimage requires it for FIT image creation
	echo dummy-kernel > boot-kern
	fitimage_emit_section_kernel ${1} 1 boot-kern "none"

	#
	# Step 2: Prepare a boot script section
	#
	fitimage_emit_section_script ${1} 1 ${2}

	fitimage_emit_section_maint ${1} sectend

	#
	# Step 3: Prepare a configuration section
	#
	fitimage_emit_section_maint ${1} confstart

	bootscript=1
	fitimage_emit_section_config ${1} "${bootscript}"

	fitimage_emit_section_maint ${1} sectend

	fitimage_emit_section_maint ${1} fitend

	#
	# Step 4: Assemble the image
	#
	uboot-mkimage \
		${@'-D "${UBOOT_MKIMAGE_DTCOPTS}"' if len('${UBOOT_MKIMAGE_DTCOPTS}') else ''} \
		-f ${1} \
		${3}

	#
	# Step 5: Sign the image
	#
	if [ "x${UBOOT_SIGN_ENABLE}" = "x1" ] ; then
		uboot-mkimage \
			${@'-D "${UBOOT_MKIMAGE_DTCOPTS}"' if len('${UBOOT_MKIMAGE_DTCOPTS}') else ''} \
			-F \
			${UBOOT_MKIMAGE_PARAMS} \
			-r ${3}
	fi
}

do_assemble_boot_script_fitimage() {
	for BOOT_SCRIPT in ${BOOT_SCRIPTS}; do
		cd ${B}
		script_fitimage_assemble boot.its ../${BOOT_SCRIPT} $(basename "${BOOT_SCRIPT%.cmd}.scr")
	done
}

addtask assemble_boot_script_fitimage before do_install after do_compile
