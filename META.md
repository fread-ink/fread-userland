
This document contains notes related to fread development that should not concern most fread developers but might be interesting for the curious. This include notes on how the fread-specific .deb packages where created, how the relevant debian packages were compiled specifically for fread and how the apt repository was set up. 

# Naming

The official name of this distribution is `fread.ink`, pronounced "freed ink". The shortened form `fread` may be used in speech and in writing but only with caution on the web. To make it easy to find information related to fread.ink the full name should be used at lost once per web page such that it can be differented from people talking about the fread() system call.

The name fread is an obvious fusion of the words free and read. It is at the same time a nod to the `fread()` or `file read` system call from the standard C library. 

The first release of fread is named after Enheduanna who may be the earliest known author. There is no established naming scheme but names should be in some way associated with writing.

# Patching packages

Patching is done using quilt which needs to be configured for use with debian packages. See this [guide on modifying debian packages](https://www.debian.org/doc/manuals/maint-guide/modify.en.html).

The basics are that you configure the dquilt command according the previously mentioned guide, download the source package you want using:

```
apt-get source package-name
```

`cd` into the package-name directory and create a new patch:

```
cd package-name-dir/
dquilt new my-patch-name.diff
```

Tell quilt about the files you're about to modify:

```
dquilt add src/important_file.c
dquilt add another_file
```

Make the changes to the files and save them, then create the patch:

```
dquilt refresh
dquilt header -e
```

The last command will ask you for a description for the patch which you _must_ supply. Your patch will now be located in debian/patches/my-patch-name.patch

Now add a change to the changelog and increment the version:

```
dch -i --distribution enheduana
```

Manually edit debian/changelog afterwards if needed. 

Finally change any other files in the `debian` directory manually as these should not be part of your patch.

Now your new source and binary packages are ready to be built.

# Building debian packages

If you want to build both source and binary packages then use:

```
dpkg-buildpackage -us -uc
```

The -us and -uc arguments means that we're not signing the packages. We'll use debsign for that later.

To build just the source package:

```
dpkg-buildpackage -us -S
````

To build just the binary package:

```
dpkg-buildpackage -uc -b
````

# Signing debian packages

Ensure that you have a reasonably secure gpg key that you want to use for signing.

Install debsign:

```
sudo apt-get install devscripts
```

List your current keys with `gpg --list-keys` to get entries like:

```
pub   4096R/430BEF18 2016-05-28 [expires: 2019-05-28]
uid                  Marc Juul <juul@fread.ink>
sub   4096R/0D88279E 2016-05-28 [expires: 2019-05-28]
```

Pick the subkey from the correct entry and use the key id which in this example is `0D88279E`.

Now for the source package sign the .dsc file:

```
debsign -k0D88279E my-package.dsc
```

and for the binary package(s) sign the .changes file:

```
debsign -k0D88279E my-package.changes
```

# Setting up an apt repository

This is farily simple. All you need is a web server and the right directory structure with a few index files which is all created and updated automatically by the tool reprepro whenever you run it.

Here is a (guide)[http://wiki.wreiner.at/Main/OwnDebianRepository].

Here is my conf/distributions file:

```
Origin: fread.ink
Label: fread.ink
Codename: enheduanna
Architectures: armhf source
Components: main
UDebComponents: main
Description: Apt repository for fread.ink
SignWith: 0D88279E
```

and my conf/options file:

```
verbose
basedir /var/www/fread.ink/public/apt       
ask-passphrase
```

Here is my apache config:

```
<VirtualHost *:443>
        ServerAdmin     fread@juul.io
        ServerName      fread.ink
        ServerAlias     www.fread.ink
        DocumentRoot    /var/www/fread.ink/public
        ErrorLog        /var/www/fread.ink/logs/error.log
        CustomLog       /var/www/fread.ink/logs/access.log combined
        LogLevel warn

        <Directory />
                Options FollowSymLinks
                AllowOverride None
        </Directory>
        <Directory /var/www/fread.ink/public>
                Options Indexes FollowSymLinks MultiViews
                AllowOverride FileInfo
                Order allow,deny
                allow from all
        </Directory>

        # apt-specific directories below

        <Directory /var/www/fread.ink/public/apt/ >
                # We want the user to be able to browse the directory manually
                Options Indexes FollowSymLinks Multiviews
                Order allow,deny
                Allow from all
        </Directory>

        <Directory "/var/www/fread.ink/public/apt/db/">
                Order deny,allow
                Deny from all
        </Directory>

        <Directory "/var/www/fread.ink/public/apt/conf/">
                Order deny,allow
               Deny from all
        </Directory>

        <Directory "/var/www/fread.ink/public/apt/conf/">
                Order deny,allow
                Deny from all
        </Directory>

        <Directory "/var/www/fread.ink/public/apt/incoming/">
                Order allow,deny
                Deny from all
        </Directory>


        # SSL options omitted
</VirtualHost>
```

## Adding package to the repostiory

For source packages do something like

```
reprepro -S main -P required -b /var/www/fread.ink/public/apt includedsc enheduanna package.dsc
```

Adding a binary package:

To add a whole set of .deb and .udeb files that are part of the same package, add the .changes file using:

```
reprepro -S main -P required -b /var/www/fread.ink/public/apt include enheduanna package.changes
```

To include just a single .deb or .udeb use the commands includedeb or includeudeb instead.

## Removing a package

To list packages:

```
reprepro -b /var/www/fread.ink/public/apt list enheduanna
```

To remove a package use the base name without any version info, e.g. for glibc_2.19-18+deb8u99 use:

```
reprepro -b /var/www/fread.ink/public/apt remove enheduanna glibc
```

# Packages modified/added for fread

## glibc linux pre-2.6.32 support

Since some supported devices use 2.6.31 kernels and the Debian Jessie glibc needs minimum 2.6.32 and since forward-porting board-specific support is beyond the measly skills of this author, the Debian glibc package was modified to compile with support for older kernels, which required only changes to configuration/compilation options. 


Debian Jessie uses glibc 2.19 which was released on 2014-02-08. This version of glibc can be compiled to be compatible with 2.6.32 minimum or to support older kernels. The Debian Jessie package disables support for kernels 2.6.32 so we need to make a slightly modified source package and recompile.

Discussions about changing min kernel to 2.6.32:

* https://sourceware.org/ml/libc-alpha/2014-01/threads.html#00511

* https://sourceware.org/ml/libc-alpha/2014-03/msg00881.html

The following was changed in the debian source package:

In the file `debian/debhelper.in/libc.preinst` there is a check that looks like this:

```
# The GNU libc requires a >= 2.6.32 kernel, found in squeeze/lucid/RHEL6
        if linux_compare_versions "$kernel_ver" lt 2.6.32
        then
            echo WARNING: this version of the GNU libc requires kernel version
            echo 2.6.32 or later.  Please upgrade your kernel before installing
            echo glibc.
            kernel26_help

            exit 1
        fi
```

All mentions of 2.6.32 were simply changed to 2.6.31

In the file `debian/sysdeps/linux.mk` the line:

```
MIN_KERNEL_SUPPORTED := 2.6.32
```

Was changed to:

```
MIN_KERNEL_SUPPORTED := 2.6.31
```

Then a patch was generated using quilt and included in the new source package which modifies the files configure.ac and configure changing the line:

```
arch_minimum_kernel=2.6.32
```

To:

```
arch_minimum_kernel=2.6.31
```

## Debian Jessie glibc package compatibility

Since Debian Jessie assumes a minimum kernel of 2.6.32 and a glibc compiled with that assumption, it's possible that there are some packages that won't work at all on a 2.6.31 kernel and a glibc compiled with 2.6.31 support, and it's possible that there are some packages that would work if they were recompiled against the 2.6.31-compatible glibc.

This sections tries to enumerate differences that might cause problems and estimate if there is cause for recompiling the entire Debian Jessie package repository against the modified glibc.

Only the following symbols are undefined in glibc 2.19 if kernel < 2.6.32:

* __ASSUME_PSELECT
* __ASSUME_PPOLL
* __ASSUME_F_GETOWN_EX: fcntl F_SETOWN_EX and F_GETOWN_EX

The first two correspond to the pselect and ppoll calls. 

Looking at the glibc 2.19 source code it appears that glibc implements its own versions of pselect and ppoll.

Here's the relevant glibc code:

In `sysdeps/unix/sysv/linux/pselect.c` if __ASSUME_PSELECT is not defined then it cincludes glibc's own pselect function from the file `misc/pselect.c`. For ppoll the files are `sysdeps/unix/sysv/linux/ppoll.c` and `io/ppoll.c`.

There is a note in one of the glibc makefiles saying that epoll_pwait is also not present in kernels < 2.6.32 but that's simply not true. I've checked and it's there both in the kindle-k4 kernel and vanilla 2.6.31 kernel and the documentation says that it was added back in 2.6.19.

If the kernel doesn't support F_SETOWN_EX and/or F_GETOWN_EX then glibc appears to have no fallback. It would have been possible to fall back to F_GETOWN and F_SETOWN under any circumstances not involving threads but that hasn't been implemented. The result is that _if_ there are programs out there that decide between using the _EX versions and plain versions of those calls at compile time then they'd have to be recompiled. 

For now I'm just going to assume that few if any programs will have any problems with the lack of the _EX versions. If it turns out to be a problem in the future then patching the _EX versions into the kernel would probably not be a big deal.

## Xorg driver for electronic paper display controller

These sources were modified to not rely on non-free/non-open binaries and a debian package was created.

ToDo complete this section.

## Awesome with extended Awful for electronic paper displays

The GPL source release from Lab126 included a version of the Awesome window manager that had its lua API (named Awful) extended to support XDamage events. This allows lua scripts to receive XDamage events, make decisions about display updates and send commands to the display controller telling it to update parts of the display or the whole display using various update methods.

ToDo complete this section.