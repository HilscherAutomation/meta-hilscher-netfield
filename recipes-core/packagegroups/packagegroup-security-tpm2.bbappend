# Make sure openssl tpm2 engine is included
RDEPENDS:packagegroup-security-tpm2:append = " tpm2-tss-engine tpm2-pkcs11 tpm2-pkcs11-tools"
