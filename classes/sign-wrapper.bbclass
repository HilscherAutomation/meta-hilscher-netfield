#
#
# Description:
# ******************************************************************************************************
# The class enables the use of a software TPM, by abstracting OpenSSL and TPM2 tools, as well as HSM
# modules via OpenSSL and pcks11 engine. It provides signing
# and public key extraction. The correct methods/tools will be automatically chosen by the given key.
# The class will update the inheriting recipe's DEPENDS accordingly.
#
# Usage: Inherit class. $PLATFORM_SIGN!=0 enables signing/public key extraction. By default the public key
#        of $PLATFORM_KEYNAME is populated under $SIGN_WRAPPER_KEY_DST after the configure step.
#        To use one of the abstractions set SIGN_WRAPPER_MODE as follows:
#          * file   : Local files are present
#          * pkcs11 : Use a HSM oder softHSM
#
#        Use openssl_sign_wrapper() for signing. For custom usage see the following lines.
#        merge_signature() will merge a given file with its signature including a section header.
#
#        The following key/signature file references are expected and will be appended by the calling function
#        to the given file reference. Therefore pass (file) references without suffix.
#          Private key file      : ${key_name}.key
#          Public key file       : ${key_name}.pub
#          Signature file        : ${file_name}.sig
#          Signature + data file : ${file_name}.signed
#        In case of a handle to a software TPM set: e.g. key_name=0x81000005 and $PLATFORM_KEYDIR($SIGN_WRAPPER_KEY_SRC) to empty string ""
#        or use the the following:
#
# NOTE: If $PLATFORM_SIGN is disabled class will result to void. To use the functions anyway use $FORCE_SIGNING.
#
# ******************************************************************************************************
# Required parameter: ([default value])
# ******************************************************************************************************
# PLATFORM_SIGN       = [-]    : By default if $PLATFORM_SIGN is disabled the class results to void.
#                                To use the class's functions anyway use $FORCE_SIGNING locally.
# SIGN_WRAPPER_MODE   = [file] : Enables support of signing via software TPM / HSM.
#                                 file   : Local/unprotected key files must be available
#                                 pkcs11 : Optional $TPMSERVER_IP for remote signing via libpkcs11-proxy
#
# ******************************************************************************************************
# Optional parameter: ([default value])
# ******************************************************************************************************
# SIGN_WRAPPER_KEY     = [${PLATFORM_KEYNAME}] : Name of the private key of which the public key will be derived.
# SIGN_WRAPPER_KEY_SRC = [${PLATFORM_KEYDIR}] : Source path of the referenced private key.
# SIGN_WRAPPER_KEY_DST = [${DEPLOY_DIR_IMAGE}/key_store/[$key_name]/$key_name.pub] : Target path where to install public key.
#
# FORCE_SIGNING       = [$PLATFORM_SIGN] : In case $PLATFORM_SIGN is disabled, set this to use functions anyway.
#
#
# ******************************************************************************************************
# Functions:
# ******************************************************************************************************
# openssl_sign_wrapper = Signs the given file.
# populate_public_key  = Extracts a public key from the given private key and populates it in $DEPLOY_IMAGE_DIR.
# merge_signature      = Merges given file with its signature.
#
#
########################################################################################################

#
# default parameter setup

# key parameter
SIGN_WRAPPER_KEY     ??= "${PLATFORM_KEYNAME}"
SIGN_WRAPPER_KEY_SRC ??= "${PLATFORM_KEYDIR}"
SIGN_WRAPPER_KEY_DST ??= "${DEPLOY_DIR_IMAGE}/key_store/"

SIGN_WRAPPER_MODE    ??= "file"
SIGN_WRAPPER_OPENSSL_PARAMS     ??= ""

# PKCS11
SIGN_WRAPPER_PKCS11_REMOTE      ??= ""
SIGN_WRAPPER_PKCS11_PIN         ??= ""

python () {
    mode = d.getVar('SIGN_WRAPPER_MODE', True)

    if mode not in ['file', 'pkcs11']:
        bb.fatal("Invalid signing mode %r selected" % mode)

    signing_required = d.getVar('PLATFORM_SIGN', True) == '1' or d.getVar('FORCE_SIGNING', True) == '1'

    if signing_required:
        if mode == 'pkcs11':
            d.appendVar('DEPENDS', ' gnutls-native libp11-native openssl-native')
            d.appendVarFlag('do_shared_workdir', 'depends', ' gnutls-native:do_populate_sysroot')
            d.appendVarFlag('do_kernel_configme', 'depends', ' gnutls-native:do_populate_sysroot')
            if d.getVar('SIGN_WRAPPER_PKCS11_REMOTE', True) != "":
                d.appendVar('DEPENDS', ' pkcs11-proxy-native')
                d.appendVarFlag('do_kernel_configme', 'depends', ' pkcs11-proxy-native:do_populate_sysroot')
        else:
            d.appendVar('DEPENDS', ' openssl-native')
}

################################################################################################
#
# Function provides signing via openssl or software TPM.
# In case software TPM support is enabled and given key ($key_name) is not a valid reference to
# to a file, the function assumes $key_name is a handle of a key within the software TPM.
# The resulting signature file will be named $sign_file.sig.
#
# openssl_sign_wrapper $key_name $hash $sign_file
#
# Parameter:
# key_name  = [-] : Name of the private key (without suffix). By default ${PLATFORM_KEYDIR} will be
#                   searched otherwise set $SIGN_WRAPPER_KEY_SRC.
# hash      = [-] : Hash to be used e.g. sha256.
# sign_file = [-] : File to be signed.
# merge     = [0] : optional: If != 0 function will create merged file (see merge_signature()).
#
################################################################################################
openssl_sign_wrapper() {
	key_name=$1
	hash=$2
	sign_file=$3
	if [ $# -gt "3" ]; then
		merge=$4
	fi
	if [ "${PLATFORM_SIGN}" = "1" ] || [ "${FORCE_SIGNING}" = "1" ]; then

		setup_sign_wrapper_env "${key_name}"

		priv_key_ref="${SIGN_WRAPPER_KEY_SRC}/${key_name}.key"
		priv_key_ref=$(setup_sign_wrapper_env "${key_name}")

		case "${SIGN_WRAPPER_MODE}" in
		file)
			openssl dgst "-${hash}" -sign "${priv_key_ref}" ${OPENSSL_SIGN_WRAPPER_ADD_OPTIONS} ${sign_file} > ${sign_file}.sig
		;;

		pkcs11)
			openssl dgst -engine pkcs11 -keyform engine "-${hash}" -sign "${priv_key_ref}" ${OPENSSL_SIGN_WRAPPER_ADD_OPTIONS} ${sign_file} > ${sign_file}.sig
		;;
		esac
	else
		echo "Using sha256sum"
		sha256sum ${sign_file} | cut -d' ' -f1 | tr -d '\n' > ${sign_file}.sig
	fi

	# create a file with appended signature
	if [ "${merge:=0}" != "0" ]; then
		merge_signature ${sign_file}
	fi
}


################################################################################################
#
# Function extracts public key from given private key and populates it under $SIGN_WRAPPER_KEY_DST/$key_name/.
# By default the private key is expected under $PLATFORM_KEYDIR otherwise set $SIGN_WRAPPER_KEY_SRC.
#
# NOTE: This function is automatically called before configure step. To modify reference private key
#       set $SIGN_WRAPPER_KEY.
#
# populate_public_key $key_name
#
# Parameter:
# key_name = [$SIGN_WRAPPER_KEY] : Private key name (without suffix).
#
################################################################################################
populate_public_key () {
	if [ "${PLATFORM_SIGN}" = "1" ] || [ "${FORCE_SIGNING}" = "1" ]; then
		key_name=$1

		# we have to call it twice: 1. to setup the variables 2. to get the key reference
		# the 2. call with the assignment does not set the variables correctly to be accessbile
		setup_sign_wrapper_env "${key_name}"

		pub_key_ref="${SIGN_WRAPPER_KEY_DST}/${key_name}/${key_name}.pub"
		priv_key_ref=$(setup_sign_wrapper_env "${key_name}")

		# if public key is already populated we have nothing to do
		if [ ! -e "${pub_key_ref}" ]; then
			mkdir -p "${SIGN_WRAPPER_KEY_DST}/${key_name}"

			case "${SIGN_WRAPPER_MODE}" in
				file)
					# if public key is not populated retrieve it from private key
					openssl rsa -in $priv_key_ref -pubout > "${pub_key_ref}"
				;;

				pkcs11)
					if [ -n "${SIGN_WRAPPER_PKCS11_REMOTE}" ]; then
						proxy_options="--provider=${STAGING_LIBDIR_NATIVE}/libpkcs11-proxy.so"
					fi
					p11tool --login --export-pubkey "${priv_key_ref};type=private" --outfile "${pub_key_ref}" --set-pin "${SIGN_WRAPPER_PKCS11_PIN}" "$proxy_options"
				;;
			esac
		fi
	fi
}


################################################################################################
# Function merges a given file with its signature and add section headers.
# The function expects the given file's signature under $file_name.sig. The merged file will be
# $file_name.signed.
#
# merge_signature $file_name
#
# Parameter:
# file_name [-] = Name of the signed file.
#
################################################################################################
merge_signature() {
	file=$1
	# Create monolithic signed file with signature included.
	echo "== SIGNATURE START ==" > ${file}.work
	cat ${file}.sig >> ${file}.work
	echo "" >> ${file}.work
	echo "== SIGNATURE END ==" >> ${file}.work
	echo "== DATA START ==" >> ${file}.work
	cat ${file} >> ${file}.work
	mv ${file}.work ${file}.signed
}


################################################################################################
# Function returns the correct name reference of a given key -> either the name (complete path)
# of a private key file or the handle and sets the required environment variables accordingly.
# 
# If in case a handle to to a keyengine is used, $SIGN_WRAPPER_KEY_SRC can be used to set the
# servers parameter.
#
# Parameter:
# key [-] = name of private key
# 
################################################################################################
setup_sign_wrapper_env() {
	if [ "${PLATFORM_SIGN}" = "1" ] || [ "${FORCE_SIGNING}" = "1" ]; then
		local key=$1
		local keypath=""
		case "${SIGN_WRAPPER_MODE}" in
			file)
				keypath="${SIGN_WRAPPER_KEY_SRC}/${key}.key"
				if [ ! -e ${keypath} ]; then
					bbfatal "Signing key ${keypath} not found"
				fi
			;;

			pkcs11)
				export OPENSSL_ENGINES="${RECIPE_SYSROOT_NATIVE}/usr/lib/engines-1.1/"

				if [ -n "${SIGN_WRAPPER_PKCS11_REMOTE}" ]; then
					export PKCS11_PROXY_SOCKET="${SIGN_WRAPPER_PKCS11_REMOTE}"
					export PKCS11_MODULE_PATH="${STAGING_LIBDIR_NATIVE}/libpkcs11-proxy.so"
				fi

				keypath="${SIGN_WRAPPER_KEY_SRC};type=private;pin-value=${SIGN_WRAPPER_PKCS11_PIN}"
			;;
		esac

		export priv_key_ref="${keypath}"
		echo "${priv_key_ref}"
	fi
}

################################################################################################
# Function to provide an existing certficate
################################################################################################
sign_wrapper_copy_certificate() {
	if [ "${PLATFORM_SIGN}" = "1" ] || [ "${FORCE_SIGNING}" = "1" ]; then

		local dst="$1"
		local fmt="${2:-der}"

		setup_sign_wrapper_env "${PLATFORM_KEYNAME}"

		case "${SIGN_WRAPPER_MODE}" in
		file)
			if [ "$fmt" = "der" ]; then
				cp "${KEYS_IMAGE_SIGN_CERT_DER}" "$dst"
			else
				cp "${KEYS_IMAGE_SIGN_CERT}" "$dst"
			fi
		;;

		pkcs11)
			if [ -n "${SIGN_WRAPPER_PKCS11_REMOTE}" ]; then
				proxy_options="--provider=${STAGING_LIBDIR_NATIVE}/libpkcs11-proxy.so"
			fi
			if [ "$fmt" = "der" ]; then
				add_fmt="--outder"
			fi
			p11tool --login --export-stapled $add_fmt "${priv_key_ref};type=cert" --outfile "$dst" --set-pin "${SIGN_WRAPPER_PKCS11_PIN}" "$proxy_options"
		;;
		esac
	fi
}

################################################################################################
# Function sets prepares environment to use keyengine
################################################################################################
do_install_prepend() {
	# in case keyengine is used we need to setup the engine path via environment variable here to be able to sign the modules in the install step
	setup_sign_wrapper_env "${PLATFORM_KEYNAME}"
}
do_install[vardeps] += "PLATFORM_SIGN SIGN_WRAPPER_KEY SIGN_WRAPPER_KEY_SRC SIGN_WRAPPER_KEY_DST"

################################################################################################
# If not disabled extract and populate public key automatically.
################################################################################################
do_populate_public_key () {
	populate_public_key "${SIGN_WRAPPER_KEY}"
}
do_populate_public_key[vardeps] ?= "PLATFORM_SIGN SIGN_WRAPPER_KEY SIGN_WRAPPER_KEY_SRC SIGN_WRAPPER_KEY_DST"
addtask populate_public_key before do_configure after do_prepare_recipe_sysroot
