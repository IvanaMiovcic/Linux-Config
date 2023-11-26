#!/bin/bash

if [ $# -ne  4 ]
then 
echo "Missing positional arguments" 
exit 1
fi

echo $1 #installation disk 
echo $2 #root password
echo $3 #username
echo $4 #user password

#partitioning disk 
(
echo o # Create a new empty DOS partition table
echo n # Add a new partition
echo p # Primary partition
echo   # Partition number (Accept default: 1)
echo   # First sector (Accept default: 1)
echo   # Last sector (Accept default: varies)
echo Y # Removes signature 
echo w # Write changes
) | fdisk /dev/$1

#formatting partitions
#does sda have different naming conventions than nvme???
mkfs.ext4 /dev/"$1"p1

#mount partitions
 
mkdir -p /mnt/gentoo
mount /dev/"$1"p1 /mnt/gentoo
cp chroot_install.sh /mnt/gentoo 
#stage3 tar

cd /mnt/gentoo
curl -o stage3-tar https://distfiles.gentoo.org/releases/amd64/autobuilds/current-stage3-amd64-openrc/stage3-amd64-openrc-20231119T164701Z.tar.xz 
tar xpf stage3-tar

#chroot

cd /mnt/gentoo
mount --types proc /proc /mnt/gentoo/proc
mount --rbind /sys /mnt/gentoo/sys
mount --make-rslave /mnt/gentoo/sys
mount --rbind /dev /mnt/gentoo/dev
mount --make-rslave /mnt/gentoo/dev
mount --bind /run /mnt/gentoo/run
mount --make-slave /mnt/gentoo/run
cp /etc/resolv.conf etc
chroot . /chroot_install.sh "$1" "$2" "$3" "$4" 
