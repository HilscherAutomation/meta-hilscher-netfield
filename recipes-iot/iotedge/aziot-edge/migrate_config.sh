#!/bin/sh

migrate_dps_provisioning() {
    global_endpoint=$(yq eval ".provisioning.global_endpoint" $CONFIG_YAML)
    scope_id=$(yq eval ".provisioning.scope_id" $CONFIG_YAML)
    method=$(yq eval ".provisioning.attestation.method" $CONFIG_YAML)
    registration_id=$(yq eval ".provisioning.attestation.registration_id" $CONFIG_YAML)
    cat <<EOF >>$CONFIG_TOML
# ==============================================================================
# Provisioning
# ==============================================================================
[provisioning]
source = "dps"
global_endpoint = "$global_endpoint"
id_scope ="$scope_id"

[provisioning.attestation]
method = "$method"
registration_id = "$registration_id"
EOF

    case $method in
        symmetric_key)
            symmetric_key=$(yq eval ".provisioning.attestation.symmetric_key" $CONFIG_YAML)
            echo "symmetric_key = { value = \"$symmetric_key\" }" >>$CONFIG_TOML
        ;;

        tpm)
        ;;
        *)
            echo "Unknown DPS method $method"
        ;;
    esac
    echo "" >>$CONFIG_TOML
}

migrate_manual_provisioning() {
    connection_string=$(yq eval ".provisioning.device_connection_string" $CONFIG_YAML)
    cat <<EOF >>$CONFIG_TOML
# ==============================================================================
# Provisioning
# ==============================================================================
[provisioning]
source = "manual"
connection_string = "$connection_string"

EOF
}

migrate_iotedge() {
    hostname=$(yq eval ".hostname" $CONFIG_YAML)
    cat <<EOF>$CONFIG_TOML
# ==============================================================================
# Hostname
# ==============================================================================
hostname = "$hostname"
EOF

    prov_source=$(yq eval ".provisioning.source" $CONFIG_YAML)

    case $prov_source in
        manual)
            migrate_manual_provisioning
            ;;
        dps)
            migrate_dps_provisioning
            ;;
    esac

    upstream_prot=$(yq eval ".agent.env.UpstreamProtocol" $CONFIG_YAML)
    cat <<EOF>>$CONFIG_TOML
[moby_runtime]
uri = "unix:///run/iotedge-docker.sock"
network = "azure-iot-edge"

[agent]
name = "edgeAgent"
type = "docker"

[agent.config]
image = "mcr.microsoft.com/azureiotedge-agent:1.2"
createOptions = { HostConfig = { Binds = ["/var/lib/aziot/storage/edgeagent:/iotedge/storage"] } }

[agent.env]
"storageFolder" = "/iotedge/storage"
"UpstreamProtocol" = "$upstream_prot"
EOF

    https_proxy=$(yq eval ".agent.env.https_proxy" $CONFIG_YAML)
    [ "$https_proxy" != "null" ] && echo "\"https_proxy\" = \"$https_proxy\"" >> $CONFIG_TOML
}


CONFIG_YAML="/etc/iotedge/config.yaml"
CONFIG_TOML="/etc/aziot/config.toml"

[ -n "$1" ] && CONFIG_YAML="$1"
[ -n "$2" ] && CONFIG_YAML="$2"

if [ -e "$CONFIG_YAML" ]; then
    migrate_iotedge
fi
