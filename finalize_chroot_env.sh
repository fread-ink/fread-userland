#!/bin/bash

if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" >&2
   exit 1
fi

set -e

# non-interactive apt mode
export DEBIAN_FRONTEND=noninteractive

# Set default root password to fread
echo "root:fread" | chpasswd

echo "Creating /mnt dirs"
mkdir -p /mnt/kindle

# TODO we should be pulling the firmware from the official linux-firmware repo
echo "Creating symlink to wifi binary blob firmware"
ln -s /mnt/kindle/opt/ar6k /opt/ar6k

echo "Pre-seeding package configurations"
debconf-set-selections ./apt_preseed

echo "Trusting fread apt public key"
apt-key add /tmp/fread-apt-key.pub

echo "Updating package lists"
apt-get update

echo "Installing fread glibc"
apt-get install -y libc-bin libc-dev-bin libc6 libc6-dev

echo "Installing basic packages"
apt-get -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" install sudo kmod iproute2 wireless-tools wpasupplicant connman isc-dhcp-client dnsmasq dropbear iputils-ping less nano openssh-client
# TODO debians dropbear is missing the scp command
#      which is why we're stuck install openssh-client.
#      We should build a proper dropbear package with scp.


echo "Installing graphics subsystem"
apt-get install -y xserver-xorg-video-imx xinit

echo "Switching to bash as default shell"
dpkg-reconfigure -f noninteractive dash # yes this switches _away_ from dash

echo "Disabling auto-start for some services"
update-rc.d dropbear disable
update-rc.d dnsmasq disable

echo "Enabling fread startup script"
update-rc.d fread_startup defaults

echo "Cleanup"
rm -rf /tmp/*
rm -rf /var/lib/apt/lists/*
rm -rf /var/cache/apt/archives/*
rm -rf /usr/share/locale/*
rm -rf /usr/share/man/*
rm -rf /usr/share/info/*
# delete everything except copyright notices in doc dir
find /usr/share/doc/ \! -path "/usr/share/doc/*/copyright" -delete 2> /dev/null
# compress copyright notices
find /usr/share/doc/ -path "/usr/share/doc/*/copyright" -exec gzip '{}' \;


set +e
