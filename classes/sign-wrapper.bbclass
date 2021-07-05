#
#
# Description:
# ******************************************************************************************************
# The class enables the use of a software TPM, by abstracting OpenSSL and TPM2 tools. It provides signing
# and public key extraction. The correct methods/tools will be automatically chosen by the given key.
# The class will update the inheriting recipe's DEPENDS accordingly.
#
# Usage: Inherit class. $PLATFORM_SIGN!=0 enables signing/public key extraction. By default the public key
#        of $PLATFORM_KEYNAME is populated under $SIGN_WRAPPER_KEY_DST after the configure step. To enable
#        the software TPM support set $SIGN_WRAPPER_SWTPM != 0.
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
#        SIGN_WRAPPER_KEY_SRC could be as well parameter to software TPM 
#        e.g.:
#        SIGN_WRAPPER_KEY_SRC="swtpm:host=127.0.0.1,port=2321"
#        SIGN_WRAPPER_KEY="0x80000005"
#
# NOTE: If $PLATFORM_SIGN is disabled class will result to void. To use the functions anyway use $FORCE_SIGNGING.
#
# ******************************************************************************************************
# Required parameter: ([default value])
# ******************************************************************************************************
# PLATFORM_SIGN       = [-] : By default if $PLATFORM_SIGN is disabled the class results to void.
#                             To use the class's functions anyway use $FORCE_SIGNING locally.
# SIGN_WRAPPER_SWTPM  = [0] : Enables support of signing via software TPM. If enabled set at least
#                             $TPMSERVER_IP accordingly ($TPMSERVER_PORT, $TPM2TSSENGINE_TCTI and
#                             $TPM2TOOLS_TCTI is optional).
#
# ******************************************************************************************************
# Optional parameter: ([default value])
# ******************************************************************************************************
# SIGN_WRAPPER_KEY     = [${PLATFORM_KEYNAME}] : Name of the private key of which the public key will be derived.
# SIGN_WRAPPER_KEY_SRC = [${PLATFORM_KEYDIR}] : Source path of the referenced private key.
# SIGN_WRAPPER_KEY_DST = [${DEPLOY_DIR_IMAGE}/key_store/[$key_name]/$key_name.pub] : Target path where to install public key.
#
# FORCE_SIGNING       = [$PLATFORM_SIGN] : In case $PLATFORM_SIGN is disabled, set this to use functions anyway.
# TPMSERVER_IP         = [""] : Set to IP of SWTPM server.
# TPMSERVER_PORT       = ["2321] : Set to port of SWTPM server.
# TPM2TSSENGINE_TCTI   = [swtpm:host=${TPMSERVER},port=${TPMSERVER_PORT}] : Normally no modfication required.
# TPM2TOOLS_TCTI       = [swtpm:host=${TPMSERVER},port=${TPMSERVER_PORT}] : Normally no modfication required.
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
SIGN_WRAPPER_KEY     ?= "${PLATFORM_KEYNAME}"
SIGN_WRAPPER_KEY_SRC ?= "${PLATFORM_KEYDIR}"
SIGN_WRAPPER_KEY_DST ?= "${DEPLOY_DIR_IMAGE}/key_store/"

# SWTPM
# if $SIGN_WRAPPER_TPMSERVER_IP is not set build should fail!
SIGN_WRAPPER_TPMSERVER_IP       ?= ""
SIGN_WRAPPER_TPMSERVER_PORT     ?= "2321"
SIGN_WRAPPER_TPM2TSSENGINE_TCTI ?= "swtpm:host=${SIGN_WRAPPER_TPMSERVER},port=${SIGN_WRAPPER_TPMSERVER_PORT}"
SIGN_WRAPPER_TPM2TOOLS_TCTI     ?= "swtpm:host=${SIGN_WRAPPER_TPMSERVER},port=${SIGN_WRAPPER_TPMSERVER_PORT}"
SIGN_WRAPPER_OPENSSL_PARAMS     ?= ""
SIGN_WRAPPER_ENGINE             ?= "tpm2tss"
swtpm_params                     = "-engine ${SIGN_WRAPPER_ENGINE} -keyform engine"
#priv_key_ref                  = ""

# package depends
#tpm2-tss
SIGN_DEPENDS_   = "${@bb.utils.contains('SWTPM_SUPPORT', '1', 'tpm2-tools tpm2-tools-native openssl-native tpm2-tss-engine-native openssl', 'openssl', d)}"
SIGN_DEPENDS    = "${@bb.utils.contains('FORCE_SIGNING', '1', "${SIGN_DEPENDS_}", '', d)}"
SIGN_DEPENDS   += "${@bb.utils.contains('PLATFORM_SIGN', '1', "${SIGN_DEPENDS_}", '', d)}"
DEPENDS_append += "${SIGN_DEPENDS}"

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
	if [ "${SIGN_DEPENDS}" != "" ]; then
		key_name=$1
		hash=$2
		sign_file=$3
		if [ $# -gt "3" ]; then
			merge=$4
		fi

		setup_swtpm_env "${key_name}"

		priv_key_ref="${SIGN_WRAPPER_KEY_SRC}/${key_name}.key"
		priv_key_ref=$(setup_swtpm_env "${key_name}")

		if [ "${SIGN_WRAPPER_USES_SWTPM}" = "1" ]; then
			if [ "${@bb.utils.contains('SIGN_WRAPPER_OPENSSL_PARAMS', '', '', '0', d)}" = "0" ]; then
				SIGN_WRAPPER_OPENSSL_PARAMS_="${swtpm_params}"
			fi
		fi

		# sign the given file
		openssl dgst ${SIGN_WRAPPER_OPENSSL_PARAMS_} "-${hash}" -sign "${priv_key_ref}" ${sign_file} > ${sign_file}.sig

		# create a file with appended signature
		if [ "${merge:=0}" != "0" ]; then
			merge_signature ${sign_file}
		fi
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
	if [ "${SIGN_DEPENDS}" != "" ]; then
		key_name=$1

		# we have to call it twice: 1. to setup the variables 2. to get the key reference
		# the 2. call with the assignment does not set the variables correctly to be accessbile
		setup_swtpm_env "${key_name}"

		pub_key_ref="${SIGN_WRAPPER_KEY_DST}/${key_name}/${key_name}.pub"
		priv_key_ref=$(setup_swtpm_env "${key_name}")

		# if public key is already populated we have nothing to do
		if [ ! -e "${pub_key_ref}" ]; then
			# if public key is not populated retrieve it from private key
			mkdir -p "${SIGN_WRAPPER_KEY_DST}/${key_name}"

			if [ "${SIGN_WRAPPER_USES_SWTPM}" = "1" ]; then
				tpm2_readpublic -c $priv_key_ref -o "${pub_key_ref}" -f PEM
			else
				openssl rsa -in $priv_key_ref -pubout > "${pub_key_ref}"
			fi
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
# If in case a handle to to a software TPM is used, $SIGN_WRAPPER_KEY_SRC can be used to set the
# servers parameter (see TPM2TSSENGINE_TCTI/TPM2TOOLS_TCTI).
#
# Parameter:
# key [-] = name of private key
# 
################################################################################################
setup_swtpm_env() {
	# maybe return handle (function could be used to extract handle from file names)
	local key=$1
	local keypath="${SIGN_WRAPPER_KEY_SRC}/${key}.key"

	if [ ! -e "$keypath" ]; then
		if [ "${@bb.utils.contains('SWTPM_SUPPORT', '1', '1', '', d)}" = "1" ]; then

			# set this to allow recipes to check if swtpm is used (e.g. what engine is used).
			export SIGN_WRAPPER_USES_SWTPM="1"

			# variable is required, that libsl is able to find the software TPM
			# engine tpm2tss. Since the path lookup is strange we have to set it
			# here explicitely.
			export OPENSSL_ENGINES="${RECIPE_SYSROOT_NATIVE}/usr/lib/engines-1.1/"

			keypath="${key}"
			if [ ! -z "${SIGN_WRAPPER_KEY_SRC}" ]; then
				export TPM2TSSENGINE_TCTI="${SIGN_WRAPPER_KEY_SRC}"
				export TPM2TOOLS_TCTI="${SIGN_WRAPPER_KEY_SRC}"
			fi
		else
			bbfatal "Signing key ${keypath} not found"
		fi
	fi
	export priv_key_ref="${keypath}"
	echo "${priv_key_ref}"
}

################################################################################################
# Function sets prepares environment to use swtpm
################################################################################################
do_install_prepend() {
	# in case swtpm is used we need to setup the engine path via environment variable here to be able to sign the modules in the install step
	setup_swtpm_env ${PLATFORM_KEYNAME}
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
