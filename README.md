
WORK IN PROGRESS. Probably nothing works yet.

This is a set of scripts and instructions for building the fread userland. The fread userland is a modified very minimal Debian Jessie. 

# The virtual machine

Note: This guide uses a different virtual machine environment from the one referenced in the [fread-vagrant](https://github.com/fread-ink/fread-vagrant) readme file.  If you don't want to use a virtual machine and you're already running Debian Jessie then you could just run the commands from bootstrap.sh directly on your system.

## Installing Vagrant

First you'll need Vagrant. The version of Vagrant in Ubuntu 14.04 is a bit old and probably won't work for our purposes. If you have a newer Ubuntu system then you may be able to just do:

```
sudo apt-get install vagrant
```

If you get errors when running `vagrant up` then install the newest version instead:

```
sudo bash -c 'echo deb http://vagrant-deb.linestarve.com/ any main > /etc/apt/sources.list.d/wolfgang42-vagrant.list'
sudo apt-key adv --keyserver pgp.mit.edu --recv-key AD319E0F7CFFA38B4D9F6E55CE3F3DE92099F7A4
sudo apt-get update
sudo apt-get install vagrant
```

## Installing the virtual machine

If you want a synced folder between the vm and your host then first install nfs:

```
sudo apt-get install nfs-kernel-server nfs-common
```

If you don't need/want synced folders then edit Vagrantfile and comment out the line starting with `config.vm.synced_folder`

Then install the virtual machine:

```
# in the same dir as this README.md file
vagrant up
```

The first time you run `vagrant up` the virtual machine will be downloaded and bootstrapped. This will take a while. If you're using synced folders then it will ask you for your password.

To get a shell on the virtual machine just ensure that you're in the fread-userland dir and run:

```
vagrant ssh
```

If you need to get back into the machine after rebooting just:

```
cd /where/you/put/fread-userland/
vagrant up 
vagrant ssh
```

The rest of this guide assumes that you're working inside of this virtual machine.

For the rest of this guide make sure you're NEVER working in the vagrant dir (/vagrant) since that directory does not support hard links.

# Setting up a cross-compile environment

Instead of using a traditional cross-compile toolchain we'll simply start with a minimal ARM Debian Jessie running using a so-called qemu-user-static chroot. A qemu-user-static chroot allows you to chroot into an ARM system on a normal x86 system with QEMU transparently handling emulation. This makes it easy to cross-compile Debian packages using the existing and familiar apt tools.

To download and install the chroot environment run:

```
cd /vagrant/
sudo ./setup_chroot_env.sh
```

This will take a while.

Then enter the chroot environment and finalize the setup:

```
sudo ./chroot.sh
./finalize_chroot_env.sh
```

# Compiling packages

Note that a bunch of extra build flags related to architecture are added by dpkg-buildflags via /etc/dpkg/buildflags.conf whenever dpkg-buildpackage is called.

# Compiling glibc

The latest kernel available for some Kindles is 2.6.31. In order to support kernels older than 2.6.32 a slightly modified version of glibc is required. 

Unfortunately qemu isn't quite a perfect enough emulator to compile glibc. Other packages compile just fine but glibc compilation just dies with a horrible error. For now you'll have to compile this package on an actual arm system or download the precompiled binary. To install the binary:

Add the following lines to /etc/apt/sources.list

```
deb https://fread.ink/apt enheduanna main
deb-src https://fread.ink/apt enheduanna main
```

Add the fread.ink apt gpg key:

```
wget -qO - https://fread.ink/fread-apt-key.pub | apt-key add -
```

Update package list and install patched glibc:

```
apt-get update
apt-get install libc-bin libc-dev-bin libc6 libc6-dev
```

If you have an ARM system e.g. a Beagle Bone Black or something already running fread and want to compile the glibc source package then you can simply copy the debootstrapped directory over to that system, remove the QEMU binary, chroot into the directory, compile glibc and then copy the resulting binary glibc .deb packages back to the QEMU dir on your primary machine and install it.

It goes something like this:

```
# assuming you are within the emulated qemu chroot
cd ~/
apt-get source glibc-2.19
logout # exit the chroot
# now copy the chroot environment to your arm system
rsync -HPSavx qemu_chroot root@my_arm_system:
ssh root@my_arm_system
# now on the arm system
rm qemu_chroot/usr/bin/qemu-arm-static # we don't want to emulate
mount -o bind /dev qemu_chroot/dev
mount -o bind /proc qemu_chroot/proc
mount -o bind /sys qemu_chroot/sys
chroot qemu_chroot /root/init_env.sh
cd /root/glibc-2.19/ 
dpkg-buildpackage -b -us # build binary only and do not sign
# wait for a long time
```
When it is done you can copy all of the resulting .deb and .udeb files back to the chroot inside your vagrant box and then use dpkg -i to install them, replacing the existing glibc.

# Compiling everything else

ToDo

