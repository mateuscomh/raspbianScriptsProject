#!/bin/bash
ponto_montagem="/mnt/Orico01S"
#docker stop $(docker ps -a -q) && sleep 5
if grep -qs "$ponto_montagem" /proc/mounts; then
    exit 0
else
    mount -a
    exit 0
fi