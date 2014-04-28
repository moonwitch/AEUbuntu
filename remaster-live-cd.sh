#!/bin/bash

######################################
# File:        remaster-live-cd.sh
# Description:
#     Remastering Ubuntu done easy
# Updated:     04/27/2014
# Author:      KellyCrabbé
# Tabsize:     3
#####################################

# Let's make sure we have the tools for the job
sudo apt-get install squashfs-tools genisoimage

if ![-e ~/ubuntu.iso]
then echo "Please rename your ISO to ubuntu.iso and place it in your homedir" && exit
else
   # Proper preparation is key
   cd ~ #always return home
   mkdir /tmp/livecd && mkdir ~/livecd && mkdir ~/livecd/cd

   # Mount the masses
   echo "Mounting your cd"
   sudo mount -o loop ~/ubuntu.iso /tmp/livecd
   # Teh copy
   rsync --exclude=/casper/filesystem.squashfs -a /tmp/livecd ~/livecd/cd

   # Mounting filesystem
   mkdir ~/livecd/squashfs && mkdir ~/livecd/custom
   sudo modprobe squashfs #For the love of god, use the same kernel in both
   sudo mount -t squashfs -o loop /tmp/livecd/casper/filesystem.squashfs ~/livecd/squashfs/
   sudo cp -a ~/livecd/squashfs/* ~/livecd/custom

   # Network access Oh baby
   sudo cp /etc/resolv.conf /etc/hosts ~/livecd/custom/etc/

   # chroot
   echo Welcome to CHROOT! More info https://wiki.archlinux.org/index.php/Change_Root
   sudo chroot ~/livecd/custom

fi