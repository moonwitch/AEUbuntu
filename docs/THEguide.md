#Creating a customized Live Ubuntu 12.04 LTS CD.

The following packages NEED to go on the cd 
- vmware-view-client
- clamav
- clamtk
- openssl (heartbleed!)
- flashplugin-installer

Package to remove
- ubuntuone-installer

##1. Prepping the environment 

For the sake of this guide; $ denotes normal shell, # is a root shell. Lean with it, rock with it.

1. Download the current Ubuntu Precise Pangolin 12.04 LTS Live CD image. Mine was saved to my Desktop just as ubuntu.iso.


2. Using terminal add squashfs-tools to be able to rebuild the custom squashfs.

	```bash
	$ sudo apt-get install squashfs-tools
	```


3. Mount the .iso under /tmp/livecd:
	```
	$ mkdir /tmp/livecd
	$ sudo mount -o loop ~/Desktop/ubuntu.iso /tmp/livecd
	```
	
	*When it tells you it is mounted as read only, don't freak out. Just continue on and smile.*


4. Create a directory for the future CD in ~/livecd and copy the CD content excluding casper/filesystem.squashfs in our ~/livecd/cd directory:
	```
	$ mkdir ~/livecd
	$ mkdir ~/livecd/cd
	$ rsync --exclude=/casper/filesystem.squashfs -a /tmp/livecd/ ~/livecd/cd
	```
	This copies all but the squashfs file, which is the compressed file containing our live CD filesystem.


5. Next mount casper/filesystem.squashfs into a directory called ~/livecd/squashfs in order to copy its content into a directory where our live CD filesystem will be customized ~/livecd/custom
	```
	$ mkdir ~/livecd/squashfs
	$ mkdir ~/livecd/custom
	$ sudo modprobe squashfs
	$ sudo mount -t squashfs -o loop /tmp/livecd/casper/filesystem.squashfs ~/livecd/squashfs/
	$ sudo cp -a ~/livecd/squashfs/* ~/livecd/custom
	```
	

6. Copy /etc/resolv.conf and /etc/hosts to our ~/livecd/custom/etc to enable access to the network from within the image being customized as chroot
	```
	$ sudo cp /etc/resolv.conf /etc/hosts ~/livecd/custom/etc/
	```
	

##2. chroot into image being created:
To customize the image, chroot into ~/livecd/custom directory, mount the necessary pseudo-filesystems (/proc and /sys). Then, customize the Live CD.
```
$ sudo chroot ~/livecd/custom
# mount -t proc none /proc/
# mount -t sysfs none /sys/
# export HOME=/root
```


##3. Customizing our future live CD

1. Remove unwanted packages. To see a list of all packages:

	```
	# dpkg-query -W --showformat='${Package}\n' | less
	```

2. I removed ubuntuone-installer.
	```
	# apt-get remove --purge ubuntuone-installer
	```

3. Next, update the existing image.

	Update the /etc/apt/sources.list in order to enable universe and multiverse repos along with precise-updates, partner repos and the precise-security repos.

	Open and edit /etc/apt/sources.list and add repos.
	```
	# sudo nano /etc/apt/sources.list
	```
> deb http://archive.ubuntu.com/ubuntu precise main restricted universe multiverse
> deb-src http://archive.ubuntu.com/ubuntu precise main restricted universe multiverse
> deb http://archive.ubuntu.com/ubuntu precise-updates main restricted universe multiverse
> deb-src http://archive.ubuntu.com/ubuntu precise-updates main restricted universe multiverse
> deb http://security.ubuntu.com/ubuntu precise-security main restricted universe multiverse
> deb-src http://security.ubuntu.com/ubuntu precise-security main restricted universe multiverse
> deb http://archive.canonical.com/ubuntu precise partner
> deb-src http://archive.canonical.com/ubuntu precise partner

4. Now update the image by running
```
# apt-get update
# apt-get upgrade
# apt-get dist-upgrade
```

	*If you have kernel issue warnings, you may also have to sudo rm /etc/kernel/*/zz-update-grub and then apt-get dist-upgrade again.
This happened to me and drove me mad.*

5. Install any wanted new packages
	```
# apt-get install vmware-view-client clamav clamtk openssl flashplugin-installer
```

##4. Cleaning up the chroot
When we install packages, apt caches them, we will need to remove them in order to save some space
```
# sudo apt-get clean&&sudo apt-get autoremove
```
Also, there still are some files in /tmp that need to be removed:
```
# rm -rf /tmp/*
```
Before chrooting, we added these files: /etc/hosts and /etc/resolv.conf, remove them:
```
# rm -f /etc/hosts /etc/resolv.conf
```
Clean the older non-used kernels to save space:
```
# dpkg -l 'linux-*' | sed '/^ii/!d;/'"$(uname -r | sed "s/\(.*\)-\([^0-9]\+\)/\1/")"'/d;s/^[^ ]* [^ ]* \([^ ]*\).*/\1/;/[0-9]/!d' | xargs sudo apt-get -y purge
```

Unmount /proc and /sys
```
# umount /proc || umount -lf /proc
# umount /sys || umount -lf /sys
```
Exit chroot
```
# exit
```

##5. Finally, Repack the CD.

1. Recreate the manifest files.

	```
$ sudo chmod +w ~/livecd/cd/casper/filesystem.manifest
$ sudo chroot ~/livecd/custom dpkg-query -W --showformat='${Package} ${Version}\n' > ~/livecd/cd/casper/filesystem.manifest
$ sudo cp ~/livecd/cd/casper/filesystem.manifest ~/livecd/cd/casper/filesystem.manifest-desktop
```

2. Regenerate the squashfs file.
```
$ sudo mksquashfs ~/livecd/custom ~/livecd/cd/casper/filesystem.squashfs
$ sudo rm ~/livecd/cd/md5sum.txt
$ sudo -s
# (cd ~/livecd/cd && find . -type f -print0 | xargs -0 md5sum > md5sum.txt)
```

3. Create the ISO with the following commands
```
$ cd ~/livecd/cd
sudo mkisofs -D -r -V "$IMAGE_NAME" -cache-inodes -J -l -b isolinux/isolinux.bin -c isolinux/boot.cat -no-emul-boot -boot-load-size 4 -boot-info-table -o ../ubuntu-custom.iso . 
```