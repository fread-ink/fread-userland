
WORK IN PROGRESS. Probably nothing works yet.

This is a set of scripts and instructions for building the fread userland. The fread userland is a modified very minimal Debian Jessie. 

# The virtual machine

Note: This guide uses a different virtual machine environment from the one referenced in the (fread-vagrant)[https://github.com/fread-ink/fread-vagrant] readme file.  If you don't want to use a virtual machine and you're already running Debian Jessie then you could just run the commands from bootstrap.sh directly on your system.

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
sudo /vagrant/setup_chroot_env.sh
```

This will take a while.

Then enter the chroot environment and finalize the setup:

```
sudo chroot ./arm_chroot /bin/su -
./finalize_chroot_env.sh
```

# Kernel headers

You'll need the kernel headers for the system you're targeting, e.g:

```
rm -rf /usr/src/linux
git clone --depth=1 https://github.com/fread-ink/fread-kernel-k4
mv fread-kernel-k4/linux-2.6.31 /usr/src/linux
rm -rf fread-kernel-k4
```

# Compiling packages

To set gcc opts for dpkg-buildpackage (e.g. `-march=armv7-a -mthumb -mfpu=vfpv3-d16 -mfloat-abi=softfp`) look at `dpkg-buildflags` and `/etc/dpkg/buildflags.conf`

```
mkdir ~/cortex
cat > ~/cortex/gcc << EOF
#! /bin/sh

exec gcc-4.3 -mcpu=cortex-a8 -mfpu=vfp -mfloat-abi=softfp "$@"
EOF
chmod 755 ~/cortex/gcc
ln -s gcc ~/cortex/cc
ln -s gcc ~/cortex/gcc-4.3
ln -s gcc ~/cortex/arm-linux-gnueabi-gcc
```

Then:

```
PATH=~/cortex:$PATH dpkg-buildpackage -rfakeroot -B
```

# Compiling glibc

In order to support kernels older than 2.6.32 a slightly modified version of glibc is required. Since changes in the available glibc API will affect other packages the safe bet is to first compile glibc, install it instead of the existing glibc, and then recompile all necessary packages against the modified glibc. This has the advantage of ensuring that all packages are optimized for the exact processor feature set available on your ebook reader which might lead to a few performance improvements.

Unfortunately qemu isn't quite a perfect enough emulator to compile glibc. All other packages compile just fine but glibc compilation just dies with a horrible error. For now you'll have to compile this package on an actual arm system, or 

If you have an ARM system e.g. a Beagle Bone Black or Raspberry Pi then you can simply copy the debootstrapped directory over to that system, remove the QEMU binary, chroot into the directory, compile glibc and then copy the resulting binary glibc .deb package back to the QEMU dir on your primary machine and install it. Of course you could also just download the pre-built glibc, but where's the fun in that? 

It goes something like this:

```
rsync -HPSavx debian_root user@my_arm_system:
ssh user@my_arm_system
# now on the arm system
rm debian_root/usr/bin/qemu-arm-static
chroot debian_root /bin/su -
cd /home/user/glibc-xxx # ToDo

# ToDo compiling

exit # exit chroot
exit # log out of arm system
scp user@my_arm_system:debian_root/home/user/glibc-xxx.deb ./ # copy built .deb
```

# Compiling everything else

ToDo