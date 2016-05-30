
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
dquilt new my-patch-name.patch
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
dch -i
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
sudo apt-get install debsign
```

ToDo how to use debsign


# Setting up an apt repository

This is farily simple. All you need is a web server and the right directory structure with a few index files which is all created and updated automatically by the tool reprepro whenever you run it.

Here is a (guide)[http://wiki.wreiner.at/Main/OwnDebianRepository].

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

ToDo adding binary packages.

# Packages modified/added for fread

## glibc linux pre-2.6.32 support

Since some supported devices use 2.6.31 kernels and the Debian Jessie glibc needs minimum 2.6.32 and since forward-porting board-specific support is beyond the measly skills of this author, the Debian glibc package was modified to compile with support for older kernels, which required only changes to configuration/compilation options. 

## Xorg driver for electronic paper display controller

These sources were modified to not rely on non-free/non-open binaries and a debian package was created.

ToDo complete this section.

## Awesome with extended Awful for electronic paper displays

The GPL source release from Lab126 included a version of the Awesome window manager that had its lua API (named Awful) extended to support XDamage events. This allows lua scripts to receive XDamage events, make decisions about display updates and send commands to the display controller telling it to update parts of the display or the whole display using various update methods.

ToDo complete this section.