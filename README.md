
WORK IN PROGRESS. Probably nothing works yet.

This is a set of scripts for building the fread userland. The fread userland is a modified very minimal Debian Jessie. 

# Setting up a cross-compile environment

Instead of using a traditional cross-compile toolchain we'll simply start with a minimal ARM Debian Jessie running using a so-called qemu-user-static chroot. A qemu-user-static chroot allows you to chroot into an ARM system on a normal x86 with QEMU transparently handling emulation. This makes it easy to cross-compile Debian packages using the existing and familiar apt tools.

# Compiling glibc

In order to support kernels older than 2.6.32 a slightly modified version of glibc is required. Since changes in the available glibc API will affect other packages the safe bet is to first compile glibc, install it instead of the existing glibc, and then recompile all necessary packages against the modified glibc. This has the advantage of ensuring that all packages are optimized for the exact processor feature set available on your ebook reader which might lead to a few performance improvements.

Unfortunately qemu isn't quite a perfect enough emulator to compile glibc. All other packages compile just fine but glibc compilation just dies with a horrible error. For now you'll have to compile this package on an actual arm system, or 

If you have an ARM system e.g. a Beagle Bone Black or Raspberry Pi then you can simply copy the debootstrapped directory over to that system, remove the QEMU binary, chroot into the directory, compile glibc and then copy the resulting binary glibc .deb package back to the QEMU dir on your primary machine and install it. Of course you could also just download the pre-built glibc, but where's the fun in that? 

It goes something like this:

```
rsync -HPSavx debian_root user@my_beagle_bone:
ssh user@my_beagle_bone
# now on the beagle bone
rm debian_root/usr/bin/qemu-arm-static
chroot debian_root
cd /home/user/glibc-xxx # ToDo
# ToDo compiling
exit # exit chroot
exit # log out of beagle bone
scp user@my_beagle_bone:debian_root/home/user/glibc-xxx.deb ./debian_root/home/user/ # ToDo
chroot debian_root
sudo dpkg -i glibc-xxx.deb
```

# Compiling everything else

ToDo