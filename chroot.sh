#!/bin/bash

if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" >&2
   exit 1
fi

set -e

CHROOT="./qemu_chroot"

echo "Bind-mounting /dev/pts"
mount -o bind /dev/pts ${CHROOT}/dev/pts

echo "Changing root into ${chroot}..."
chroot ${CHROOT} /root/init_env.sh

set +e
