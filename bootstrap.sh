#!/usr/bin/env bash

apt-get update
apt-get install -y qemu binfmt-support qemu-user-static debian-archive-keyring debootstrap nfs-common portmap apt-transport-https
dpkg --add-architecture armhf

apt-get update
apt-get install -y libc6:armhf

