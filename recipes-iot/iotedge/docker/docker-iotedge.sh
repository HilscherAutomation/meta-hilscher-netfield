#!/bin/sh

if [ ! -e "/run/iotedge-docker.sock" ]; then
	echo "IoT-Edge instance of docker not found."
	echo "Make sure on-boarding succeeded and service has been started."
	exit 1
fi

docker -H unix:///run/iotedge-docker.sock "$@"
