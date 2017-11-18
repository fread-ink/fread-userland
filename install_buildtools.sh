#!/bin/bash

if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" >&2
   exit 1
fi

set -e

apt-get update

echo "Installing basic build dependencies"

apt-get install -y locales dialog build-essential git pkg-config autoconf automake ca-certificates packaging-dev dpkg-dev fakeroot
apt-get build-dep -y glibc xserver-xorg-video-fbdev

echo "Downloading and installing fread k4 kernel headers"

rm -rf /usr/src/linux
git clone --depth=1 https://github.com/fread-ink/fread-kernel-k4
mv fread-kernel-k4/linux-2.6.31 /usr/src/linux
rm -rf fread-kernel-k4

echo ""
echo "Your arm chroot cross-compile environment is now ready!"
echo ""

set +e
