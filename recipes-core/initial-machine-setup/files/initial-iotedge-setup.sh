#!/bin/sh

# Check for requested basic settings
if [ -z "$(cat /etc/gateway/settings.json 2>/dev/null)" ]; then
    if [ -e "/var/platform/device_data/product_number" ]; then
        # Pad up product_number to 12 characters
        product_number=$(cat /var/platform/device_data/product_number | tr -d '\n')
        product_number=$(printf "%12s" "$product_number" | sed "s/ /0/g")
    else
        product_number="000000000000"
    fi

    # Read and pad serial number to 12 characters
    serial_number=$(cat /var/platform/device_data/serial_number | tr -d '\n')
    serial_number=$(echo $serial_number | rev | cut -c1-12 | rev)
    serial_number=$(printf "%12s" "$serial_number" | sed "s/ /0/g")

    hardware_id="${product_number}-${serial_number}"

    mkdir -p /etc/gateway/

    # Add remote-access option from device-label if existing, defaulting to off
    remoteaccess="off"
    if [ -e "/var/platform/device_data/oem_data/branding/deviceManager/remoteAccess" ]; then
        remoteaccess=$(cat /var/platform/device_data/oem_data/branding/deviceManager/remoteAccess)
    fi

    cat <<EOF>/etc/gateway/settings.json
{
  "schemaVersion": 1,
  "gatewayPrefix": "$hardware_id",
  "remote-access": "$remoteaccess"
}
EOF
    chown -R root:netadmin /etc/gateway/
    chmod 0664 /etc/gateway/settings.json
    sync
fi

do_tpm_onboarding() {
    if [ -e "/var/platform/device_data/oem_data/iotedge/tpm/device" ]; then
        tpm_device=$(cat /var/platform/device_data/oem_data/iotedge/tpm/device)
    else
        tpm_device="device:/dev/tpmrm0"
    fi

    cat <<EOF>/etc/aziot/config.toml
# DPS TPM provisioning configuration
[provisioning]
source = "dps"
global_endpoint = "$global_endpoint"
id_scope = "$scope_id"

[provisioning.attestation]
method = "tpm"
registration_id = "$registration_id"

[tpm]
tcti = "$tpm_device"

EOF

    tpm_authorization=""

    if [ -e "/var/platform/device_data/oem_data/iotedge/tpm/endorsement_auth" ]; then
        tpm_authorization="${tpm_authorization}endorsement = \"$(cat /var/platform/device_data/oem_data/iotedge/tpm/endorsement_auth)\"\n"
    fi

    if [ -e "/var/platform/device_data/oem_data/iotedge/tpm/owner_auth" ]; then
        tpm_authorization="${tpm_authorization}owner = \"$(cat /var/platform/device_data/oem_data/iotedge/tpm/owner_auth)\"\n"
    fi

    if [ -n "$tpm_authorization" ]; then
        echo "[tpm.hierarchy_authorization]" >> /etc/aziot/config.toml
        echo "$tpm_authorization" >> /etc/aziot/config.toml
    fi
}

do_symmetric_key_onboarding() {
    if [ ! -e "/var/platform/device_data/oem_data/iotedge/symmetric_key" ]; then
        echo "<4>Missing symmetric_key for zero-touch onboarding"
        exit 1
    fi

    symmetric_key=$(cat /var/platform/device_data/oem_data/iotedge/symmetric_key)

    cat <<EOF>/etc/aziot/config.toml
# DPS symmetric key provisioning configuration
[provisioning]
source = "dps"
global_endpoint = "$global_endpoint"
id_scope ="$scope_id"

[provisioning.attestation]
method = "symmetric_key"
registration_id = "$registration_id"
symmetric_key = { value = "$symmetric_key" }
EOF
}

do_x509_onboarding() {
    device_crt_file="/var/platform/device_data/oem_data/iotedge/device_crt"
    device_key_uri_file="/var/platform/device_data/oem_data/iotedge/device_key_uri"
    device_key_file="/var/platform/device_data/oem_data/iotedge/device_key"
    pkcs11_db_file="/var/platform/device_data/oem_data/iotedge/pkcs11_db"

    if [ ! -e "$device_crt_file" ]; then
        echo "<4>Missing device_crt for zero-touch onboarding"
        exit 1
    fi
    if [ ! -e "$device_key_file" ] && [ ! -e "$device_key_uri_file" ]; then
        echo "<4>Provide device_key or device_key_uri for zero-touch onboarding"
        exit 1
    fi

    if [ -e "$device_key_uri_file" ] && [ ! -e "$pkcs11_db_file" ]; then
        echo "<4>Missing PKCS11 database for x509/TPM onboarding"
        exit 1
    fi

    base64 -d "$device_crt_file" > /etc/aziot/device.crt
    chown aziotks:aziotks /etc/aziot/device.crt

    if [ -e "$device_key_file" ]; then
        cat "$device_key_file" | base64 -d | sudo tee /etc/aziot/device.key
        chown aziotks:aziotks /etc/aziot/device.key
        identity_pk="file:///etc/aziot/device.key"
    else
        identity_pk=$(cat "$device_key_uri_file")
        mkdir -p /var/lib/aziot/keyd/.tpm2_pkcs11/
        base64 -d "$pkcs11_db_file" | gunzip > /var/lib/aziot/keyd/.tpm2_pkcs11/tpm2_pkcs11.sqlite3
        chown aziotks:aziotks -R /var/lib/aziot/keyd/.tpm2_pkcs11
    fi

# DPS x509 provisioning configuration
    cat <<EOF>/etc/aziot/config.toml
[provisioning]
source = "dps"
global_endpoint = "$global_endpoint"
id_scope ="$scope_id"

[provisioning.attestation]
method = "x509"
registration_id = "$registration_id"
identity_pk = "$identity_pk"
identity_cert = "file:///etc/aziot/device.crt"

[aziot_keys]
pkcs11_lib_path = "/usr/lib/pkcs11/libtpm2_pkcs11.so.0.0.0"
EOF
}

do_general_settings() {
    upstreamprotocol="Amqp"

    if [ -e "/var/platform/device_data/oem_data/branding/netFieldCloud/upstreamProtocol" ]; then
        prot=$(cat /var/platform/device_data/oem_data/branding/netFieldCloud/upstreamProtocol)
        case "$prot" in
            AMQP)   upstreamprotocol="Amqp" ;;
            MQTT)   upstreamprotocol="Mqtt" ;;
            AMQPWS) upstreamprotocol="AmqpWs" ;;
            MQTTWS) upstreamprotocol="MqttWs" ;;
            *)      echo "Unknown protocol $prot defaulting to $upstreamprotocol" ;;
        esac
    fi

    cat <<EOF>>/etc/aziot/config.toml

hostname = "$(hostname)"

[agent]
name = "edgeAgent"
type = "docker"

[agent.config]
image = "mcr.microsoft.com/azureiotedge-agent:1.5"
createOptions = { HostConfig = { Binds = ["/var/lib/aziot/storage:/iotedge/storage"] } }

[agent.env]
"storageFolder" = "/iotedge/storage"
"UpstreamProtocol" = "$upstreamprotocol"

[moby_runtime]
uri = "unix:///run/iotedge-docker.sock"
network = "azure-iot-edge"
EOF
    sync
}

ZERO_TOUCH_BASE="/mnt/backup/nvd/zero-touch"

# Check for zero-touch onboarding data
iotedge_status=$(systemctl is-enabled aziot-edged)
if [ "$iotedge_status" != "enabled" ]; then
    if [ -e "$ZERO_TOUCH_BASE/override" ]; then
        override=$(cat "$ZERO_TOUCH_BASE"/override)
        case "$override" in
            disabled)
                echo "Skipping automatic/zero-touch onboarding"
                exit 0
                ;;
            manual)
                echo "Overriding onboarding with stored data"
                cp "$ZERO_TOUCH_BASE"/etc/aziot/* /etc/aziot/
                if [ -d "$ZERO_TOUCH_BASE/.tpm2_pkcs11/" ]; then
                    # Copy pkcs11 database
                    mkdir -p /var/lib/aziot/keyd/.tpm2_pkcs11/
                    chown aziotks:aziotks /var/lib/aziot/keyd/.tpm2_pkcs11/
                    chmod 0750 /var/lib/aziot/keyd/.tpm2_pkcs11/
                    cp -r "$ZERO_TOUCH_BASE"/.tpm2_pkcs11/ /var/lib/aziot/keyd/.tpm2_pkcs11/
                    chown aziotks:aziotks /var/lib/aziot/keyd/.tpm2_pkcs11/*
                    chmod 0644 -R /var/lib/aziot/keyd/.tpm2_pkcs11/*
                fi
                if [ -d "/mnt/backup/nvd/swtpm" ]; then
                    systemctl enable --now --no-block swtpm
                fi
                iotedge config apply
                systemctl enable --no-block aziot-edged
                ;;
            *)
                echo "Unknown override option '$override', continueing normal zero-touch process"
                ;;
        esac
    elif [ -d "/var/platform/device_data/oem_data/iotedge" ]; then
        if [ -e "/var/platform/device_data/oem_data/iotedge/method" ]; then
            method=$(cat /var/platform/device_data/oem_data/iotedge/method)
        else
            method="symmetric_key"
        fi

        if [ ! -e "/var/platform/device_data/oem_data/iotedge/scope_id" ]; then
            echo "<4>Missing scope_id for zero-touch onboarding"
            exit 1
        fi

        if [ ! -e "/var/platform/device_data/oem_data/iotedge/registration_id" ]; then
            echo "<4>Missing registration_id for zero-touch onboarding"
            exit 1
        fi

        scope_id=$(cat /var/platform/device_data/oem_data/iotedge/scope_id)
        registration_id=$(cat /var/platform/device_data/oem_data/iotedge/registration_id)

        if [ -e "/var/platform/device_data/oem_data/iotedge/global_endpoint" ]; then
            global_endpoint=$(cat /var/platform/device_data/oem_data/iotedge/global_endpoint)
        else
            global_endpoint="https://global.azure-devices-provisioning.net"
        fi

        case "$method" in
            "symmetric_key")
                do_symmetric_key_onboarding
                do_general_settings
                iotedge config apply
                systemctl enable --no-block aziot-edged
                ;;
            "x509")
                do_x509_onboarding
                do_general_settings
                iotedge config apply
                systemctl enable --no-block aziot-edged
                ;;
            "tpm")
                do_tpm_onboarding
                do_general_settings
                iotedge config apply
                systemctl enable --no-block aziot-edged
                ;;
            *)
                echo "<4>Invalid zero-touch onboarding method ($method)"
                exit 1
                ;;
        esac
    fi
fi
