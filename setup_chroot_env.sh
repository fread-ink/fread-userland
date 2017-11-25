#!/bin/bash

if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" >&2
   exit 1
fi

set -e

START_DIR=$(pwd)
VAGRANT_DIR="/vagrant"
CHROOT="./qemu_chroot"

echo "Running debootstrap"
qemu-debootstrap --arch=armhf --variant=minbase --include=sysvinit-core,sysvinit-utils --exclude=systemd jessie $CHROOT http://ftp.debian.org/debian/

# qemu-debootstrap copies this automatically
#echo "Setting up qemu"
#cp /usr/bin/qemu-arm-static ${CHROOT}/usr/bin/

echo "Copying configuration"

cp -r ${VAGRANT_DIR}/config/* ${CHROOT}/

cp -a /etc/resolv.conf ${CHROOT}/etc/
cp -a /etc/apt/sources.list ${CHROOT}/etc/apt/

# TODO why should just include a sane hosts file
echo cp /etc/hosts ${CHROOT}/etc/

echo "Populating /dev"
cp ${VAGRANT_DIR}/makenodes.sh ${CHROOT}/
cd ${CHROOT}/
./makenodes.sh
rm makenodes.sh
cd $START_DIR

echo "Copying scripts"
cp ${VAGRANT_DIR}/apt_preseed ${CHROOT}/root/
cp ${VAGRANT_DIR}/finalize_chroot_env.sh ${CHROOT}/root/
cp ${VAGRANT_DIR}/init_env.sh ${CHROOT}/root/
#cp ${VAGRANT_DIR}/chroot.sh ${CHROOT}/../

# Downloading fread apt public key
wget -qO - https://fread.ink/fread-apt-key.pub > ${CHROOT}/tmp/fread-apt-key.pub

echo "This is a magic file for scripts to check to know they're in the right chroot env" > ${CHROOT}/etc/fread_qemu_cross_compile_chroot

echo ""
echo "First stage completed!"
echo "To complete second (and final) stage:"
echo "  sudo ./chroot.sh"
echo "  ./finalize_chroot_env.sh" 
echo ""

set +e
