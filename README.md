
WORK IN PROGRESS.

This is a set of scripts and instructions for building the minimal fread userland and optionally extending that userland to enable easy cross-compilation. The fread userland is a modified very minimal Debian Jessie. We would like to switch to Debian Stretch but the kernel versions currently available for 1st to 5th generation kindles are too old for the glibc included in Debian Stretch.

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

The `/vagrant` dir is shared between the VM and your actual system such that any changes to `/vagrant/` happens in the `fread-vagrant/` dir.

For the rest of this guide make sure you're NEVER actually compiling anything directly in the `/vagrant` dir since that directory does not support hard links.

For the rest of this guide make sure you're NEVER working in the vagrant dir (/vagrant) since that directory does not support hardlinks.

# Setting up the fread userland

This guide uses the qemu-user-static chroot which allows you to chroot into an ARM system on a normal x86 system with QEMU transparently handling emulation. This makes it easy to work on the userland as if you were on an ARM system.

To download and install the minimal userland run:

```
cd ~/
cp -a /vagrant ./fread-userland
cd fread-userland/
sudo ./setup_chroot_env.sh
```

This will take a while.

You will need the tar.gz file containing the kernel modules and the modules.dep file that were in the `OUTPUT/` directory after compiling the kernel. From outside the VM simply copy the entire `OUTPUT/` dir into the `fread-userland/` dir to make it appear in `/vagrant/`.

Copy the modules and modules.dep to the userland:

```
cd ~/fread-userland/
sudo cp /vagrant/OUTPUT/linux-2.6.31-rt11-lab126.tar.gz qemu_chroot/
sudo cp /vagrant/OUTPUT/modules.dep qemu_chroot/
```

Now enter the userland using chroot:

```
sudo ./chroot.sh
```

Put kernel modules files where they need to be:

```
cd /
tar -xvzf linux-2.6.31-rt11-lab126.tar.gz --exclude='boot'
rm linux-2.6.31-rt11-lab126.tar.gz
mv /modules.dep /lib/modules/2.6.31-rt11-lab126/
```

Finalize installation of the userland:

```
cd
./finalize_chroot_env.sh
```

again this will take a while.

# Creating the ext4 file

Log out of the chroot environment, then create an ext4 file:

```
du -ch qemu_chroot # find the size of the userland
# For count= you should use the size of the userland + maybe 120 MB (for some free space)
dd if=/dev/zero of=fread.ext4 bs=1M count=<size in MB> # create a blank file
sudo mkfs.ext4 -T small fread.ext4 # create an ext4 filesystem in the blank file
sudo tune2fs -c 0 -i 0 ./fread.ext4 # disable automatic fsck on mount (since it doesn't yet work)
sudo mount -o loop fread.ext4 /mnt # loop-mount the file
sudo cp -a qemu_chroot/* /mnt/ # copy the userland into the loop-mounted ext4 file
sudo rm /mnt/usr/bin/qemu-arm-static # delete the emulatorc
sudo umount /mnt #unmount
```

Now you should have a usable root filesystem. Copy `fread.ext4` to `/vagrant/OUTPUT` to make it accessible from outside the VM:

```
mkdir -p /vagrant/OUTPUT
cp ~/fread-userland/fread.ext4 /vagrant/OUTPUT/
```

Note: We are using ext4 with the intention of loop-mounting it from the existing kindle filesystem. Note that ext4 does not have wear-leveling so it is a bad idea to use it directly on a flash chip. Look into JFFS2 if you intend to use this directly on your e-reader's flash chip.

# Booting fread

See the [fread-vagrant](https://github.com/fread-ink/fread-vagrant) readme file. The section "Booting into fread". 

# Compiling packages

This section and those following are only relevant for people wishing to compile packages or create/modify debian packages.

Make sure you are inside of the qemu_chroot environment, then install build tools using:

```
./install_buildtools.sh
```

## A note on dpkg-buildpackage (and similar)

A bunch of extra build flags related to architecture are added by dpkg-buildflags via /etc/dpkg/buildflags.conf whenever dpkg-buildpackage is called.

# Compiling glibc

The latest kernel available for some Kindles is 2.6.31. In order to support kernels older than 2.6.32 a slightly modified version of glibc is required. 

Unfortunately qemu isn't quite a perfect enough emulator to compile glibc. Other packages compile just fine but glibc compilation just dies with a horrible error. For now you'll have to compile this package on an actual arm system or download the precompiled binary (available via [https://fread.ink/apt](the fread.ink apt repository)).

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

# Building the xorg driver

You don't have to build this yourself. If you already added the fread.ink repo to your apt sources.list (see previos sections) and ran `apt update` then you can simply install using:

```
apt install xserver-xorg-video-imx
```

Inside of the qemu environment, inside of this VM:

```
cd ~/
git clone https://github.com/fread-ink/xserver-xorg-video-imx
cd xserver-xorg-video-imx/
```

Then follow instructions in the README.md file to build the package. It is recommended not to actually install the driver in this form, since it does not have a proper debian package control file, meaning that the package manager won't understand its verison nor dependencies. It is better to simply install the pre-built package from the fread apt repository. If you really want to generate a proper package from scratch then see the following sub-section.


## Generating a proper debian package and source file

You probably don't need to do this, since the package and source package have already been created and you can simply download, compile and install those, but if you really want to do this from scratch:

```
apt install checkinstall dh-make devscripts
rm -rf xserver-xorg-video-imx/ # we need to start from scratch
git clone https://github.com/fread-ink/xserver-xorg-video-imx
cd xserver-xorg-video-imx/
rm -rf bin .git* # don't include binaries or git files in the debian source package
./autogen.sh --prefix=/usr
# create the package
DEBFULLNAME="You Name" dh_make -p xserver-xorg-video-imx_0.0.1 --createorig --single --email you@yourhost.org
```

Now edit the generated `debian/control` file. You can use the control file from the source package of the similar package `xserver-xorg-video-fbdev` as a basis:

```
apt-get source xserver-xorg-video-fbdev
less xserver-xorg-video-fbdev-0.4.4/debian/control
```

Delete all of the `debian/*.ex` and `debian/*.EX` files.

You can look at [this guide](https://blog.packagecloud.io/eng/2016/12/15/howto-build-debian-package-containing-simple-shell-scripts/) for more info.

When you are happy with the control file then build:

```
debuild -us -uc
```


# ToDo

# apt package indexes take up too much space

After each `apt-get update` the package indexes take up ~90 MB. How do we deal with this? Compressed ram filesystem? Just a ram filesystem and then automatically delete this after e.g. 10 minutes of no `apt-get` commands?

Apparently new versions of apt support an option to gzip the indexes:

```
Acquire::GzipIndexes "true";
Acquire::CompressionTypes::Order:: "gz";
```
