#!/bin/bash

if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" >&2
   exit 1
fi

if [[ ! -f "/etc/fread_qemu_cross_compile_chroot" ]]; then
  echo "This script must be run in the fread QEMU cross compile chroot" >&2
  exit 1
fi

set -e

export distro=jessie
export LANG=C

echo "Installing basic build dependencies"
apt-get update
apt-get install -y locales dialog build-essential git pkg-config autoconf automake
apt-get build-dep -y glibc xserver-xorg-video-fbdev

echo ""
echo "Your arm chroot cross-compile environment is now ready!"
echo ""

set +e
