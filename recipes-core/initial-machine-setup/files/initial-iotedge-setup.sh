#!/bin/sh

# Check for requested basic settings
if [ -z "$(cat /etc/gateway/settings.json 2>/dev/null)" ]; then
    if [ -e "/var/platform/device_data/product_number" ]; then
        # Pad up product_number to 12 characters
        product_number=$(cat /var/platform/device_data/product_number | tr -d '$\n')
        product_number=$(printf "%12s" "$product_number" | sed "s/ /0/g")
    else
        product_number="000000000000"
    fi

    # Read and pad serial number to 12 characters
    serial_number=$(cat /var/platform/device_data/serial_number | tr -d '$\n')
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
    sync
fi

do_tpm_onboarding() {
    cat <<EOF>/etc/iotedge/config.yaml
# DPS TPM provisioning configuration
provisioning:
  source: "dps"
  global_endpoint: "${global_endpoint}"
  scope_id: "${scope_id}"
  attestation:
    method: "tpm"
    registration_id: "${registration_id}"

EOF
}

do_symmetric_key_onboarding() {
    if [ ! -e "/var/platform/device_data/oem_data/iotedge/symmetric_key" ]; then
        echo "<4>Missing symmetric_key for zero-touch onboarding"
        exit 1
    fi

    symmetric_key=$(cat /var/platform/device_data/oem_data/iotedge/symmetric_key)

    cat <<EOF>/etc/iotedge/config.yaml
# DPS symmetric key provisioning configuration
provisioning:
  source: "dps"
  global_endpoint: "${global_endpoint}"
  scope_id: "${scope_id}"
  attestation:
    method: "symmetric_key"
    registration_id: "${registration_id}"
    symmetric_key: "${symmetric_key}"

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

    cat <<EOF>>/etc/iotedge/config.yaml
agent:
  name: "edgeAgent"
  type: "docker"
  env:
    UpstreamProtocol: "$upstreamprotocol"
  config:
    image: "mcr.microsoft.com/azureiotedge-agent:1.0"
    auth: {}

hostname: "$(hostname)"

connect:
  management_uri: "unix:///var/run/iotedge/mgmt.sock"
  workload_uri: "unix:///var/run/iotedge/workload.sock"

listen:
  management_uri: "fd://iotedge.mgmt.socket"
  workload_uri: "fd://iotedge.socket"

homedir: "/var/lib/iotedge"

moby_runtime:
  uri: "unix:///var/run/iotedge-docker.sock"
EOF
    sync
}

# Check for zero-touch onboarding data
iotedge_status=$(systemctl is-enabled iotedge)
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
                systemctl enable --now --no-block iotedge
                ;;
            "tpm")
                do_tpm_onboarding
                do_general_settings
                systemctl enable --now --no-block iotedge
                ;;
            *)
                echo "<4>Invalid zero-touch onboarding method ($method)"
                exit 1
                ;;
        esac
    fi
fi
