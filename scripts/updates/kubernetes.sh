#!/bin/bash -e

SCRIPTDIR=$(readlink -f "${0}")
SCRIPTDIR=$(dirname "${SCRIPTDIR}")

err_report() {
    echo "Error on line $1"
}

cleanup() {
    rm -rf "$TMPDIR"
}

trap 'err_report $LINENO; cleanup' ERR
trap 'cleanup' EXIT
trap 'cleanup' INT

TMPDIR=$(mktemp -d)

VERSION="$1"
if [ -z "$VERSION" ]; then
    echo "No version specified"
    exit 1
fi

cp "${SCRIPTDIR}"/create_go_relocations "$TMPDIR"/
git clone -b "v${VERSION}" https://github.com/kubernetes/kubernetes "$TMPDIR"/kubernetes
HASH=$(git -C "$TMPDIR"/kubernetes rev-parse HEAD)

git -C "$TMPDIR"/kubernetes am "${SCRIPTDIR}"/../../recipes-containers/kubernetes/files/*.patch
docker run -it --rm -v "$TMPDIR":/build --workdir /build/kubernetes golang:1.21 ../create_go_relocations

cp "$TMPDIR"/kubernetes/relocations.inc "$TMPDIR"/kubernetes/src_uri.inc \
    "${SCRIPTDIR}"/../../recipes-containers/kubernetes/
cp "$TMPDIR"/kubernetes/modules.txt \
    "${SCRIPTDIR}"/../../recipes-containers/kubernetes/files

CURRENT_RECIPE=$(ls -1 "${SCRIPTDIR}"/../../recipes-containers/kubernetes/*.bb | head -n1)
NEW_RECIPE="${SCRIPTDIR}/../../recipes-containers/kubernetes/kubernetes_${VERSION}.bb"
if [ "$CURRENT_RECIPE" != "$NEW_RECIPE" ]; then
    mv "$CURRENT_RECIPE" "$NEW_RECIPE"
fi
sed -e "s@SRCREV=.*@SRCREV=\"${HASH}\"@g" \
    -i "$NEW_RECIPE"
