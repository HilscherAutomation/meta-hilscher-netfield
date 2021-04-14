#!/bin/sh

if [ -z "$1" ]; then
    echo "Please pass a version $0 1.0.9.4"
    exit 1
fi

tmpdir=$(mktemp -d)

git clone https://github.com/azure/iotedge -b $1 $tmpdir

cat << EOF > $tmpdir/exec.sh
#!/bin/sh

    cargo install cargo-bitbake
    sed -i -e 's@\(^edition = .*\)@\1\nhomepage = "https://github.com/azure/iotedge"@' /iotedge/edgelet/iotedged/Cargo.toml
    cd /iotedge/edgelet/iotedged
    cargo bitbake
EOF
chmod +x $tmpdir/exec.sh
docker run -it --rm -v $tmpdir:/iotedge rust:1.42.0 /iotedge/exec.sh

# Prepare recipe and patch it according to our build
mv $tmpdir/edgelet/iotedged/*.bb recipes-iot/iotedge/iotedge_$1.bb

# We need to use the edgelet subdirectory when building
sed -i -e 's@^S = .*@S = "${WORKDIR}/git/edgelet"@' recipes-iot/iotedge/iotedge_$1.bb

# Strip generated bogus license and summary stuff
sed -i -e '/^# FIXME:/,$d' recipes-iot/iotedge/iotedge_$1.bb

# Add require of our base stuff
echo "require iotedge.inc" >> recipes-iot/iotedge/iotedge_$1.bb

# NOTE: License checksum is not updated. If it changes, the license must be re-checked, as it might have changed

rm -rf $tmpdir
