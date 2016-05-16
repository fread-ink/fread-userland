#!/bin/bash

if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" >&2
   exit 1
fi

set -e
apt-get install qemu binfmt-support qemu-user-static
dpkg --add-architecture armhf
apt-get update
apt-get install libc6:armhf

qemu-debootstrap --no-check-gpg --arch=armhf jessie ./debian_root ftp://ftp.debian.org/debian/

set +e
