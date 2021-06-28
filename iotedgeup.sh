#!/bin/sh

if [ -z "$1" ]; then
    echo "Please pass a version $0 1.0.9.4"
    exit 1
fi

tmpdir=$(mktemp -d)

PACKAGES_TO_EXTRACT="iotedge/edgelet:iotedge:aziot-edge iot-identity-service:iotedged:azure-identity-service"

git clone https://github.com/azure/iotedge -b $1 $tmpdir/iotedge
# Extract version / hash of iot-identity-service
identity_commit=$(grep -m1 -o "https://github.com/Azure/iot-identity-service.*#.*" $tmpdir/iotedge/edgelet/Cargo.lock | sed -e 's/.*#\(.*\)"/\1/')
git clone https://github.com/Azure/iot-identity-service $tmpdir/iot-identity-service
cd $tmpdir/iot-identity-service
git checkout $identity_commit
cd -

cat << EOF > $tmpdir/exec.sh
#!/bin/sh
    cargo install cargo-generate --locked cargo-bitbake
    for tmp_package in $PACKAGES_TO_EXTRACT; do
        dir=\$(echo \$tmp_package | cut -d ':' -f1)
        package=\$(echo \$tmp_package | cut -d ':' -f2)
        sed -i -e 's@\(^edition = .*\)@\1\nhomepage = "https://github.com/azure/iotedge"@' /iotedge/\$dir/\$package/Cargo.toml
        sed -i -e 's@\(^edition = .*\)@\1\nrepository = "https://github.com/azure/iotedge"@' /iotedge/\$dir/\$package/Cargo.toml
        echo "1.47.0" > /iotedge/\$dir/rust-toolchain
        cd /iotedge/\$dir/\$package
        cargo bitbake
    done
EOF

chmod +x $tmpdir/exec.sh
docker run -it --rm -v $tmpdir:/iotedge rust:1.51 /iotedge/exec.sh

# Prepare recipe and patch it according to our build
for tmp_package in $PACKAGES_TO_EXTRACT; do
    dir=$(echo $tmp_package | cut -d ':' -f1)
    package=$(echo $tmp_package | cut -d ':' -f2)
    recipename=$(echo $tmp_package | cut -d ':' -f3)
    mv $tmpdir/$dir/$package/*.bb recipes-iot/iotedge/${recipename}_$1.bb

    # We need to use the edgelet subdirectory when building
    if echo $dir  | grep '/'; then
        basepath=$(basename $dir)
        sed -i -e "s@^S = .*@S = \"\${WORKDIR}/git/$basepath\"@" recipes-iot/iotedge/${recipename}_$1.bb
    fi

    # Strip generated bogus license and summary stuff
    sed -i -e '/^# FIXME:/,$d' recipes-iot/iotedge/${recipename}_$1.bb

    # Use main directory for cargo
    sed -i -e 's@CARGO_SRC_DIR.*@CARGO_SRC_DIR = "."@g' recipes-iot/iotedge/${recipename}_$1.bb

    # Add require of our base stuff
    echo "require $recipename.inc" >> recipes-iot/iotedge/${recipename}_$1.bb

    # NOTE: License checksum is not updated. If it changes, the license must be re-checked, as it might have changed
done

rm -rf $tmpdir

