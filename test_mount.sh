#!/bin/bash

#export DISPLAY=:0.0

if grep -qs $1 /proc/mounts; then
    echo "It's mounted."
else
    sshfs -o allow_other,umask=111,idmap=user data-user@192.168.169.108:$2 $1
fi
