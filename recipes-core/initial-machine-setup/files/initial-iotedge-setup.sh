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
    if [ ! -e "/var/platform/device_data/oem_data/iotedge/crt" ]; then
        echo "<4>Missing crt for zero-touch onboarding"
        exit 1
    fi
    if [ ! -e "/var/platform/device_data/oem_data/iotedge/key" ]; then
        echo "<4>Missing key for zero-touch onboarding"
        exit 1
    fi
    if [ ! -e "/var/platform/device_data/oem_data/iotedge/scope_id" ]; then
        echo "<4>Missing scope_id for zero-touch onboarding"
        exit 1
    fi

    if [ ! -e "/var/platform/device_data/oem_data/iotedge/registration_id" ]; then
        echo "<4>Missing registration_id for zero-touch onboarding"
        exit 1
    fi
    if [ -e "/var/platform/device_data/oem_data/iotedge/global_endpoint" ]; then
        global_endpoint=$(cat /var/platform/device_data/oem_data/iotedge/global_endpoint)
    else
        global_endpoint="https://global.azure-devices-provisioning.net"
    fi

    scope_id=$(cat /var/platform/device_data/oem_data/iotedge/scope_id)
    registration_id=$(cat /var/platform/device_data/oem_data/iotedge/registration_id)

    cat /var/platform/device_data/oem_data/iotedge/crt | base64 -d > /etc/aziot/device.crt
    cat /var/platform/device_data/oem_data/iotedge/key | base64 -d > /etc/aziot/device.key
    sudo chown aziotks:aziotks /etc/aziot/device.key
    sudo chown aziotks:aziotks /etc/aziot/device.crt    

    # determine if TPM exists using tpm2_getrandom 10 --hex 2>&1
    hasTpm=$(tpm2_getrandom 10 --hex 2>&1)

    # If TPM exists
    if [ "$?" -eq 0 ]; then
        # Unlock TPM if locked
        tpm2_dictionarylockout --setup-parameters --max-tries=4294967295 --clear-lockout

        # Ensure basic tpm slot setup
        slotdata=$(sudo -Hu aziotks pkcs11-tool --module /usr/lib/pkcs11/libtpm2_pkcs11.so.0.0.0 --list-slots 2>/dev/null)

        if [[ $slotdata != *"azureiothub"* ]]; then # todo test
            nextFreeSlot=$(sudo -Hu aziotks pkcs11-tool --module /usr/lib/pkcs11/libtpm2_pkcs11.so.0.0.0 --list-slots 2>/dev/null | awk '/Slot/ {slot=$0} /uninitialized/ {print slot; exit}' | awk -F' ' '{print $2}' | tr -d '()')
            nextFreeSlotId=$((nextFreeSlot + 1))
            sudo -Hu aziotks pkcs11-tool --module /usr/lib/pkcs11/libtpm2_pkcs11.so.0.0.0 --slot $nextFreeSlotId --init-token --label "azureiothub" --so-pin "hilscher4ever"
            sudo -Hu aziotks pkcs11-tool --module /usr/lib/pkcs11/libtpm2_pkcs11.so.0.0.0 --slot $nextFreeSlotId --init-pin --login --so-pin "hilscher4ever" --new-pin "hilscher"
        fi

        # Delete existing keypair (if any)
        sudo -Hu aziotks pkcs11-tool --module /usr/lib/pkcs11/libtpm2_pkcs11.so.0.0.0 --token azureiothub --pin hilscher --delete-object --label device --type pubkey 2>/dev/null
        sudo -Hu aziotks pkcs11-tool --module /usr/lib/pkcs11/libtpm2_pkcs11.so.0.0.0 --token azureiothub --pin hilscher --delete-object --label device --type privkey 2>/dev/null

        # Convert key to RSA format
        sudo -Hu aziotks openssl rsa -in /etc/aziot/device.key -out /etc/aziot/device_rsa.key

        #!!!!!!! Attention: Here we need to switch from pkcs11-tool to tpm2_ptool because pkcs11-tool is not able to import a keypair into the TPM!
        # sudo -Hu aziotks tpm2_ptool listtokens --pid 1
        # sudo -Hu aziotks tpm2_ptool listobjects --label=azureiothub
        sudo -Hu aziotks tpm2_ptool import --label=azureiothub --key-label device --privkey /etc/aziot/device_rsa.key --algorithm=rsa --userpin='hilscher'

        # Import new keypair into TPM
        sudo -Hu aziotks pkcs11-tool --module /usr/lib/pkcs11/libtpm2_pkcs11.so.0.0.0 --token azureiothub --pin hilscher --write-object /etc/aziot/device_rsa.key --type privkey --label device

        # Delete key file
        sudo rm /etc/aziot/device.key
        sudo rm /etc/aziot/device_rsa.key

        identity_pk="pkcs11:token=azureiothub;object=device?pin-value=hilscher"

    # If TPM does not exist
    else
        identity_pk="file:///etc/aziot/device.key"
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
image = "mcr.microsoft.com/azureiotedge-agent:1.2"
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

# Check for zero-touch onboarding data
iotedge_status=$(systemctl is-enabled aziot-edged)
if [ "$iotedge_status" != "enabled" ]; then
    if [ -d "/var/platform/device_data/oem_data/iotedge" ]; then
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
