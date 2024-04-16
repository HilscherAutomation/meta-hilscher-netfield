#!/bin/bash

usage() {
	echo
	echo "Usage: $0 [-u user] cmd"
	echo
	exit 1;
}

while getopts ":u:" o; do
	case "${o}" in
		u)
			user=${OPTARG}
			;;
		*)
			usage
			;;
	esac
done
shift $((OPTIND-1))

[ $# -lt 1 ] && {
	echo "Error: Invalid or missing docker command to run (e.g./bin/bash)!"
	exit 1
}

[ ! $user ] && user=$(whoami)
BUILD_UID=$(grep ^$user: /etc/passwd | cut -d":" -f3,4)
[ -z "$BUILD_UID" ] && {
	echo "Error: Invalid or missing user \"$user\"!"
	exit 1
}

SCRIPTDIR=$(readlink -f ${0})
SCRIPTDIR=$(dirname ${SCRIPTDIR})

docker build -t sphinxdoc:netfieldos $SCRIPTDIR
docker run --rm -it -h sphinxdoc -v $(pwd):/docs -v "$(pwd)/..":/src -u $BUILD_UID sphinxdoc:netfieldos $@
