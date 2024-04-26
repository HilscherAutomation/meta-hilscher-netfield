#!/bin/sh

ZERO_TOUCH_BASE="/mnt/backup/nvd/zero-touch"

mkdir -p "$ZERO_TOUCH_BASE"

copy_onboarding_data() {
    rm -rf "$ZERO_TOUCH_BASE"/*

    for f in /etc/aziot/*; do
        if [ -f "$f" ]; then
            if ! echo "$f" | grep -q ".template"; then
                mkdir -p "$ZERO_TOUCH_BASE"$(dirname "$f")
                cp "$f" "$ZERO_TOUCH_BASE""$f"
            fi
        fi
    done

    identitypk=$(toml get --raw /etc/aziot/config.toml provisioning.authentication.identity_pk)

    if [ -z "$identitypk" ]; then
        echo "Unable to extract identity PK, maybe device was onboarding without x509"
    elif echo "$identitypk" | grep -q "file://"; then
        f=$(echo "$identitypk" | sed -e 's@file://@@')
        mkdir -p "$ZERO_TOUCH_BASE"$(dirname "$f")
        cp "$f" "$ZERO_TOUCH_BASE"/"$f"
    else
        # Copy pkcs11 database
        mkdir -p "$ZERO_TOUCH_BASE"/.tpm2_pkcs11
        cp -r /var/lib/aziot/keyd/.tpm2_pkcs11/* "$ZERO_TOUCH_BASE"/.tpm2_pkcs11/
    fi

    echo "manual" > "$ZERO_TOUCH_BASE"/override
}

hostname=$(toml get --raw /etc/aziot/config.toml hostname)
if [ "$hostname" == "null" ]; then
    echo "Device not onboarded"
    exit 1
fi

method=$(toml get --raw /etc/aziot/config.toml provisioning.source)
case $method in
    manual)
        copy_onboarding_data
        ;;
    *)
        echo "Unsupported onboarding method '$method'"
        exit 1
        ;;
esac
