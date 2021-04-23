#!/bin/sh -e

CONFIG_FILE="/etc/swupdate.conf"

update_identification() {
    key=$1
    value=$2

    count=$(ls-config -f ${CONFIG_FILE} -g "identify" -qc)
    if [ $? -ne 0 ]; then
        ls-config -f ${CONFIG_FILE} -s "identify" -p list -d empty -q
        count=0
    fi

    found="0"

    for idx in $(seq $count); do
        idx=$((idx - 1))
        found_key=$(ls-config -f ${CONFIG_FILE} -g "identify.[$idx].name" -qv)
        found_value=$(ls-config -f ${CONFIG_FILE} -g "identify.[$idx].value" -qv)
        if [ "$found_key" = "$key" ]; then
            found="1"
            if [ "$found_value" != "$value" ]; then
                ls-config -f ${CONFIG_FILE} -s "identify.[$idx].value" -d "$value"
            fi
            break
        fi
    done

    if [ "$found" = "0" ]; then
        new_idx=$(ls-config -f ${CONFIG_FILE} -s "identify" -p group -d empty -q)
        ls-config -f ${CONFIG_FILE} -s "identify.[$new_idx].name" -p string -d "$key"
        ls-config -f ${CONFIG_FILE} -s "identify.[$new_idx].value" -p string -d "$value"
    fi
}

if [ -e "/etc/swupdate/hawkbit.json" ]; then
    enable=$(jq -r -M '.enable' /etc/swupdate/hawkbit.json)
    tenant=$(jq -r -M '.tenant' /etc/swupdate/hawkbit.json)
    url=$(jq -r -M '.url' /etc/swupdate/hawkbit.json)
    id=$(jq -r -M '.id' /etc/swupdate/hawkbit.json)
    if [ "$enable" != "true" ]; then
        echo "<7>Hawkbit is disabled"
    elif [ "$tenant" = "null" ]; then
        echo "<3>Missing tenantID for hawkbit communication"
    elif [ "$url" = "null" ]; then
        echo "<3>Missing URL for hawkbit communication"
    elif [ "$id" = null ]; then
        echo "<3>Missing deviceID for hawkbit communication"
    else
        SWUPDATE_SURICATTA_ARGS="$SWUPDATE_SURICATTA_ARGS --tenant $tenant --url $url --id $id"

        security_token=$(jq -r -M '.security_token' /etc/swupdate/hawkbit.json)
        [ -n "$security_token" ] && SWUPDATE_SURICATTA_ARGS="$SWUPDATE_SURICATTA_ARGS --targettoken $security_token"

        curr_fw=$(cat /firmware.version)

        if [ -e "/etc/swupdate/firmware.image_name" ]; then
            if [ "$(cat /firmware.image_name)" = "$(cat /etc/swupdate/firmware.image_name)" ]; then
                SWUPDATE_SURICATTA_ARGS="$SWUPDATE_SURICATTA_ARGS --confirm 2" # success
            else
                SWUPDATE_SURICATTA_ARGS="$SWUPDATE_SURICATTA_ARGS --confirm 3" # failed
            fi
            rm /etc/swupdate/firmware.image_name
        fi


        [ ! -e "${CONFIG_FILE}" ] && touch ${CONFIG_FILE}
        # globals section is always needed, at least it must be empty
        if ! ls-config -f ${CONFIG_FILE} -g globals -q >/dev/null; then
            ls-config -f ${CONFIG_FILE} -s globals -d empty -p group
        fi

        # Update identification data
        product_name="$(cat /var/platform/device_data/product_name)"
        product_number="$(cat /var/platform/device_data/product_number)"
        serial_number="$(cat /var/platform/device_data/serial_number)"
        update_identification "productName" "${product_name:="unknown"}"
        update_identification "productNumber" "${product_number:="unknown"}"
        update_identification "serialNumber" "${serial_number:="unknown"}"
        update_identification "firmwareVersion" "${curr_fw:="unkown"}"

        SWUPDATE_ARGS="${SWUPDATE_ARGS} -f ${CONFIG_FILE}"
    fi
fi
