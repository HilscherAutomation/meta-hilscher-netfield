#!/bin/sh

get_value() {
  file=$1
  if [ -r "$file" ]; then
    cat $file
  else
    echo ""
  fi
}

check_services() {
  if [ -d "/var/platform/device_data/oem_data/branding/services/deviceManager" ]; then

    https_port=$(get_value "/var/platform/device_data/oem_data/branding/services/deviceManager/httpsPort")
    if [ -n "$https_port" ]; then
      sed -i -e "s@:443@:$https_port@g" /etc/nginx/nginx.conf
    fi

    http_port=$(get_value "/var/platform/device_data/oem_data/branding/services/deviceManager/httpPort")
    if [ -n "$http_port" ]; then
      sed -i -e "s@:80@:$http_port@g" /etc/nginx/nginx.conf
    fi
    systemctl restart --no-block nginx
  fi

  if [ -d "/var/platform/device_data/oem_data/branding/services/ssh" ]; then

    ssh_port=$(get_value "/var/platform/device_data/oem_data/branding/services/ssh/port")
    if [ -n "$ssh_port" ]; then
      mkdir -p /etc/systemd/system/sshd.socket.d
      cat <<EOF> /etc/systemd/system/sshd.socket.d/port.conf
[Socket]
ListenStream=
ListenStream=$ssh_port
EOF
      systemctl daemon-reload --no-block
      systemctl stop --no-block sshd.socket
    fi

    ssh_enabled=$(get_value "/var/platform/device_data/oem_data/branding/services/ssh/enabled")
    if [ "$ssh_enabled" = "false" ]; then
      systemctl disable --now --no-block sshd.socket
    else
      systemctl enable --now --no-block sshd.socket
    fi
  fi

  docker_enabled=$(get_value "/var/platform/device_data/oem_data/branding/services/docker/enabled")
  if [ "$docker_enabled" = "false" ]; then
    systemctl disable --now --no-block docker
  else
    systemctl enable --now --no-block docker
  fi

  docker_dns=""
  if [ -d "/var/platform/device_data/oem_data/branding/services/docker/dns" ]; then
    for new_dns in /var/platform/device_data/oem_data/branding/services/docker/dns/*; do
      ip=$(get_value "$new_dns")
      [ -z "$ip" ] && continue
      [ -z "$docker_dns" ] && docker_dns="\"$ip\"" || docker_dns="$docker_dns \"$ip\""
    done
  fi

  if [ -n "$docker_dns" ]; then
      docker_dns="[$(echo "$docker_dns" | tr ' ' ',')]"
      for f in /etc/docker/daemon.json /etc/docker/iotedge.json; do
          cat "$f" | jq -M ".dns=$docker_dns" | tee "$f" > /dev/null
      done

      if [ "$docker_enabled" = "true" ]; then
          systemctl restart --no-block docker
      fi
      systemctl restart --no-block iotedge-docker
  fi

}

check_interfaces() {
  if [ -d "/var/platform/device_data/oem_data/branding/interfaces" ]; then
    for interface in /var/platform/device_data/oem_data/branding/interfaces/*; do
      name=$(get_value "$interface/name")
      if [ ! -e "/etc/NetworkManager/system-connections/$name" ]; then
        echo "!Unable to find connection '$name' to brand. Skipping!"
        continue
      fi
      mode=$(get_value "$interface/mode")
      case $mode in
        auto)
          nmcli connection modify "$name" "ipv4.method" "auto" "ipv4.addresses" "" "ipv4.gateway" "" "ipv4.dns" ""
          post_step="restart"
          ;;
        manual)
          address=$(get_value "$interface/address")
          if [ -z "$address" ]; then
            echo "!Invalid address '$address' for connection '$name' in mode '$mode' to brand. Skipping!"
            continue
          fi
          nmcli connection modify "$name" "ipv4.method" "manual" "ipv4.addresses" "$address" "ipv4.gateway" "" "ipv4.dns" ""
          post_step="restart"
          ;;
        disabled)
          nmcli connection modify "$name" "ipv4.method" "disabled" "ipv4.addresses" "" "ipv4.gateway" "" "ipv4.dns" ""
          post_step="down"
          ;;
        *)
          echo "!Unknown mode '$mode' for connection '$name' to brand. Skipping!"
          continue
          ;;
      esac

      gateway=$(get_value "$interface/gateway")
      if [ -n "$gateway" ]; then
          nmcli connection modify "$name" "ipv4.gateway" "$gateway"
      fi

      default_metric=$(get_value "$interface/metric")
      if [ -n "$gateway" ]; then
           nmcli connection modify "$name" "ipv4.route-metric" "$default_metric"
      fi

      if [ -d "$interface/dns" ]; then
        for new_dns in $interface/dns/*; do
          ip=$(get_value "$new_dns")
          if [ -z "$ip" ]; then
            echo "!Invalid DNS entry '$ip' found for connection '$name' to brand. Ignoring DNS entry!"
          else
            nmcli connection modify "$name" "+ipv4.dns" "$ip"
          fi
        done
      fi

      if [ -d "$interface/routes" ]; then
        for new_route in $interface/routes/*; do
          address=$(get_value $new_route/address)
          gateway=$(get_value $new_route/gateway)
          metric=$(get_value $new_route/metric)
          if [ -z "$address" -o -z "$gateway" ]; then
            echo "!Invalid route found. Address:'$address', gateway:'$gateway', metric:'$metric' for connection '$name' to brand. Ignoring route!"
          else
            nmcli connection modify "$name" "+ipv4.routes" "$address $gateway $metric"
          fi
        done
      fi

      case "$post_step" in
        restart)
          nmcli c down "$name"
          nmcli c up "$name"
          ;;
        down)
          nmcli c down "$name"
          ;;
      esac

    done
  fi
}

check_ntp() {
  if [ -d "/var/platform/device_data/oem_data/branding/ntp" ]; then
    enabled=$(get_value "/var/platform/device_data/oem_data/branding/ntp/enabled")
    timezone=$(get_value "/var/platform/device_data/oem_data/branding/ntp/timezone")

    if [ -n "$timezone" ]; then
      timedatectl set-timezone "$timezone"
    fi

    if [ -d "/var/platform/device_data/oem_data/branding/ntp/servers" ]; then
      serverlist=""
      for server in /var/platform/device_data/oem_data/branding/ntp/servers/*; do
        server=$(cat $server)
        [ -z "$serverlist" ] && serverlist="$server" || serverlist="$serverlist $server"
      done
      mkdir -p /etc/systemd/timesyncd.conf.d
      echo "[Time]" > /etc/systemd/timesyncd.conf.d/50-cockpit.conf
      echo "NTP=$serverlist" >> /etc/systemd/timesyncd.conf.d/50-cockpit.conf
      chown root:timeadmin /etc/systemd/timesyncd.conf.d /etc/systemd/timesyncd.conf.d/50-cockpit.conf
      chmod 0775 /etc/systemd/timesyncd.conf.d
      chmod 0664 /etc/systemd/timesyncd.conf.d/50-cockpit.conf
      systemctl restart --no-block systemd-timesyncd
    fi

    if [ "$enabled" = "true" ]; then
      timedatectl set-ntp true
    else
      timedatectl set-ntp false
    fi
  fi
}

_check_and_add_group() {
  # Add user group if not existing
  if ! getent group "$1" > /dev/null; then
    groupadd "$1"
  fi
}

check_users() {
  if [ -d "/var/platform/device_data/oem_data/branding/users" ]; then
    for user in /var/platform/device_data/oem_data/branding/users/*; do
      username=$(get_value "$user/name")
      if [ -z "$username" ]; then
        echo "Missing username in $user, !SKIPPING!"
        continue
      fi
      mode=$(get_value "$user/mode")
      [ -z "$mode" ] && mode="add"
      shell=$(get_value "$user/shell")
      home=$(get_value "$user/home")
      group=$(get_value "$user/group")
      password=$(get_value "$user/password")
      force_pw_change=$(get_value "$user/forcePasswordChange")

      add_groups=""
      if [ -d "$user/additionalGroups" ]; then
        for tmpgroup in $user/additionalGroups/*; do
          tmpgroup=$(cat "$tmpgroup")
          _check_and_add_group "$tmpgroup"
          [ -z "$add_groups" ] && add_groups="$tmpgroup" || add_groups="$add_groups,$tmpgroup"
        done
      fi

      options=""
      case "$mode" in
        delete)
          userdel -r "$username"
          ;;
        add)
          if [ -z "$password" ]; then
            echo "Unable to add user $username without a password. !SKIPPING!"
          else
            [ -n "$home" ] && options="$options -d $home -m"
            if [ -n "$group" ]; then
              options="$options -N -g $group"
              _check_and_add_group "$group"
            fi
            [ -n "$add_groups" ] && options="$options -G $add_groups"

            [ -z "$shell" ] && shell="/bin/sh"
            useradd -s "$shell" -p "$password" $options "$username"
            [ "$force_pw_change" = "true" ] && passwd -e "$username" || chage -d $(date '+%Y-%m-%d') "$username"
          fi
          ;;
        change)
            [ -n "$home" ] && options="$options -d $home -m"
            if [ -n "$group" ]; then
              options="$options -g $group"
              _check_and_add_group "$group"
            fi
            [ -n "$add_groups" ] && options="$options -G $add_groups"
            [ -n "$shell" ] && options="$options -s $shell"
            [ -n "$password" ] && options="$options -p $password"

            usermod $options "$username"
            [ "$force_pw_change" = "true" ] && passwd -e "$username" || chage -d $(date '+%Y-%m-%d') "$username"
          ;;
        *)
          echo "Unknown mode $mode for user $username. !SKIPPING!"
          ;;
      esac
    done
  fi
}

# Check if branding was already done
if [ ! -e "/etc/.branding_done" ]; then
  # Adapt brandings
  check_services
  check_interfaces
  check_ntp
  check_users
  # TODO: IMHO proxy settings don't make sense in branding options, as proxy depends on device location and not device type
  # check_proxy

  # Remember that we've branded
  touch /etc/.branding_done
  sync
fi

if grep -q ".debug" /fw_version; then
  # Always start sshd on debug images
  systemctl start --no-block sshd.socket
fi

exit 0
