#!/bin/bash

if [ -z "$1" ]; then
    echo "Please pass a version $0 1.0.9.4"
    exit 1
fi

tmpdir=$(mktemp -d)

PACKAGES_TO_EXTRACT="iotedge/edgelet:iotedge:aziot-edge iot-identity-service:aziotd:azure-identity-service"
VERSION="$1"

git clone https://github.com/azure/iotedge -b "$VERSION" "$tmpdir"/iotedge
# Extract version / hash of iot-identity-service
identity_commit=$(grep -m1 -o "https://github.com/Azure/iot-identity-service.*#.*" "$tmpdir"/iotedge/edgelet/Cargo.lock | sed -e 's/.*#\(.*\)"/\1/')
git clone https://github.com/Azure/iot-identity-service "$tmpdir"/iot-identity-service
cd "$tmpdir"/iot-identity-service || exit 1
git checkout "$identity_commit"
cd - || exit 1

cat << EOF > "$tmpdir"/exec.sh
#!/bin/bash
    # YQ is needed to parse TOML
    apt update
    apt install -y python3-pip jq
    pip3 install yq

    cargo install --locked --git https://github.com/meta-rust/cargo-bitbake --tag v0.3.16
    for tmp_package in $PACKAGES_TO_EXTRACT; do
        dir=\$(echo "\$tmp_package" | cut -d ':' -f1)
        package=\$(echo "\$tmp_package" | cut -d ':' -f2)
        sed -i -e 's@\(^edition = .*\)@\1\nrepository = "https://github.com/azure/iotedge"@' /iotedge/"\$dir"/"\$package"/Cargo.toml
	if [ ! -e "/iotedge/"\$dir"/rust-toolchain.toml" ]; then
            echo "1.58.0" > /iotedge/"\$dir"/rust-toolchain
        fi
        cd /iotedge/"\$dir"/"\$package" || exit 1
        cargo bitbake

	[ -e "\${package}_${VERSION}.bb" ] && config_to_check="\${package}_${VERSION}.bb" || config_to_check="\${package}_0.1.0.bb"
	srcrevs_to_check=\$(cat "\${config_to_check}" | grep "^SRCREV_" | grep -v "^SRCREV_FORMAT" | tr -d ' ')
	echo "Checking following SRCREV: '\$srcrevs_to_check'"
	for rev in \$srcrevs_to_check; do
		echo "rev '\$rev'"
		cargo_name=\$(echo "\$rev" | cut -d '=' -f1 | cut -d '_' -f2-)
		cargo_rev=\$(echo "\$rev" | cut -d '=' -f2 | grep -o '".*"' | sed 's/"//g')
		echo "Checking cargo '\$cargo_name' with revision '\$cargo_rev"

		# If cargo_rev is not a sha256, extract the hash from Cargo.lock
		if [[ \$cargo_rev =~ ^[A-Fa-f0-9]{64}$ ]]; then
			echo "SRCREV for '\$cargo_name' is already a git hash '\$cargo_rev', skipping"
		else
			[ -e "../Cargo.lock" ] && CARGO_LOCK="../Cargo.lock" || CARGO_LOCK="Cargo.lock"
			# Extract hash from cargo.lock
			cargo_src=\$(tomlq '.package[]  | select(.name == "'\$cargo_name'") | .source' "\$CARGO_LOCK")
			old_cargo_rev="\$cargo_rev"
			cargo_rev=\$(echo "\$cargo_src" | grep "\$old_cargo_rev" | tr -d '"' | cut -d '#' -f2)
			if [[ \$cargo_rev =~ ^[A-Fa-f0-9]{64}$ ]]; then
				echo "Unable to find SRCREV for package '\$cargo_name'"
				exit 1
			else
				echo "Replacing SRCREV '\$old_cargo_rev' with '\$cargo_rev' for package '\$cargo_name'"
				sed -i -e "s@SRCREV_\$cargo_name[ =].*@SRCREV_\$cargo_name = \"\$cargo_rev\"@g" "\${config_to_check}"
			fi
		fi
	done
    done
EOF

chmod +x "$tmpdir"/exec.sh
docker run -it --rm -v "$tmpdir":/iotedge rust:1.62 /iotedge/exec.sh

# Prepare recipe and patch it according to our build
for tmp_package in $PACKAGES_TO_EXTRACT; do
    dir=$(echo "$tmp_package" | cut -d ':' -f1)
    package=$(echo "$tmp_package" | cut -d ':' -f2)
    recipename=$(echo "$tmp_package" | cut -d ':' -f3)

    cd "$tmpdir"/"$dir" || exit 1
    version=$(git tag --points-at HEAD)
    [ -z "$version" ] && version="git"
    cd - || exit 1

    mv "$tmpdir"/"$dir"/"$package"/"$package"_*.bb recipes-iot/iotedge/"${recipename}"_"$version".bb

    # We need to use the edgelet subdirectory when building
    if echo "$dir"  | grep '/'; then
        basepath=$(basename "$dir")
        sed -i -e "s@^S = .*@S = \"\${WORKDIR}/git/$basepath\"@" recipes-iot/iotedge/"${recipename}"_"$version".bb
    fi

    # Strip generated bogus license and summary stuff
    sed -i -e '/^# FIXME:/,$d' recipes-iot/iotedge/"${recipename}"_"$version".bb

    # Use main directory for cargo
    sed -i -e 's@CARGO_SRC_DIR.*@CARGO_SRC_DIR = "."@g' recipes-iot/iotedge/"${recipename}"_"$version".bb

    # Add require of our base stuff
    echo "require $recipename.inc" >> recipes-iot/iotedge/"${recipename}"_"$version".bb

    # NOTE: License checksum is not updated. If it changes, the license must be re-checked, as it might have changed
done

rm -rf "$tmpdir"

