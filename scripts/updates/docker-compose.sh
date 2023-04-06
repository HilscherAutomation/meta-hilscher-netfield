#!/bin/bash -e

SCRIPTDIR=$(readlink -f ${0})
SCRIPTDIR=$(dirname ${SCRIPTDIR})

err_report() {
    echo "Error on line $1"
    if [ -n "$tmpdir" ]; then
        rm -rf "$tmpdir"
    fi
}

trap 'err_report $LINENO' ERR

tmpdir=$(mktemp -d)
VERSION="$1"

cp "${SCRIPTDIR}"/create_go_relocations "$tmpdir"/
git clone -b v"${VERSION}" https://github.com/docker/compose "$tmpdir"/compose
hash=$(git -C "$tmpdir"/compose rev-parse HEAD)

docker run -it --rm -v "$tmpdir":/build --workdir /build/compose golang:1.20 ../create_go_relocations

cp "$tmpdir"/compose/relocations.inc "$tmpdir"/compose/src_uri.inc \
   "${SCRIPTDIR}"/../../recipes-containers/docker-compose/
cp "$tmpdir"/compose/modules.txt \
   "${SCRIPTDIR}"/../../recipes-containers/docker-compose/files
current_compose=$(ls -1 "${SCRIPTDIR}"/../../recipes-containers/docker-compose/*.bb | head -n1)
new_compose=""${SCRIPTDIR}"/../../recipes-containers/docker-compose/docker-compose_${VERSION}.bb"
if [ "$current_compose" != "$new_compose" ]; then
    mv "$current_compose" "$new_compose"
fi
sed -e "s@SRCREV=.*@SRCREV=\"${hash}\"@g" \
    -i "$new_compose"

rm -rf "$tmpdir"
