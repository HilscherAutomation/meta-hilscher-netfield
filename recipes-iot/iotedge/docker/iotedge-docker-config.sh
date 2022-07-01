#!/bin/sh

parent_cgroup=$(cat /etc/docker/iotedge.json | jq '."cgroup-parent" // empty')
if [ -n "$parent_cgroup" ]; then
    if ! echo "$parent_cgroup" | grep -q ".slice"; then
        jq '."cgroup-parent" = "iotedge.slice"' /etc/docker/iotedge.json > /tmp/iotedge.json
        mv /tmp/iotedge.json /etc/docker/iotedge.json
        sync
    fi
fi
