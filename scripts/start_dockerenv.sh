#!/bin/bash

SCRIPTDIR=$(readlink -f ${0})
SCRIPTDIR=$(dirname ${SCRIPTDIR})

if [ -d build ]; then
  echo "Using uid of build directory"
  BUILD_UID=`ls -dn build/ | cut -f3 -d " "`:`id -g`
else
  echo "Using uid of logged in user"
  BUILD_UID=`id -u`:`id -g`
fi

docker build -t yocto-buildenv:22.04.1 $SCRIPTDIR/docker/.
docker run --rm -it --add-host bitbucket.hilscher.com:192.168.99.18 --add-host nxybuilder01.hilscher.local:192.168.100.52 --add-host subversion01.hilscher.local:192.168.100.17 --add-host subversion01:192.168.100.17 -v $(pwd):/build -u $BUILD_UID yocto-buildenv:22.04.1
