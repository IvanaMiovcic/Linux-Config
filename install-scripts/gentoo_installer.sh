#!/bin/bash

if [ $# -ne 2 ]
then 
	echo "Missing positional arguments" 
	exit 1
fi

if [ "$2" != "BIOS/MBR" ] && [ "$2" != "BIOS/GPT" ] && [ "$2" != "UEFI/GPT" ]
then 
	echo "Incorrect partitioning option. Exiting."
	exit 1
fi

#getting passwords 
read -sp "Root password: " root1
echo
read -sp "Re-enter root password: " root2
if [ "$root1" != "$root2" ]
then
        echo -e "\nPasswords do not match. Exiting."
        exit 1
elif [ -z $root1 ]
then
        echo -e "\nPassword cannot be empty. Exiting."
        exit 1
fi
echo
read -p "Username: " username
read -sp "Password for $username: " user1
echo
read -sp "Re-enter password for $username: " user2
if [ "$user1" != "$user2" ]
then
        echo -e "\nPasswords do not match. Exiting."
        exit 1
elif [ -z $user1 ]
then
        echo -e "\nPassword cannot be empty. Exiting."
        exit 1
fi

#partitioning disk 
if [ "$2" == "BIOS/MBR" ]
then 
	(
	echo o
	echo n
	echo p
	echo  
	echo  
	echo +128M  
	echo Y
	echo n
	echo p
	echo 
	echo 
	echo +1024M
	echo Y
	echo n
	echo p
	echo 
	echo 
	echo 
	echo Y
	echo t
	echo 2
	echo 82
	echo w
	) | fdisk /dev/$1
else
	(
	echo o
	echo y
	echo n
	echo 1
	echo  
	echo +128M
	echo 
	echo n
	echo 2
	echo 
	if [ "$2" == "BIOS/GPT" ]
	then
        	echo +2M
        	echo EF02
	else
        	echo +128MB
        	echo EF00
	fi
	echo n
	echo 3
	echo  
	echo +1024M
	echo 8200
	echo n
	echo 4
	echo  
	echo  
	echo  
	echo w
	echo y
	) | gdisk /dev/"$1"
fi

#formatting partitions
if [ ${1::4} == "nvme" ]
then 
	part=p
else 
	part=
fi 
mkfs.ext4 /dev/"$1""$part"1
if [ "$2" == "BIOS/MBR" ]
then 
	mkfs.ext4 /dev/"$1""$part"3
	mkswap /dev/"$1""$part"2 && swapon /dev/"$1""$part"2
else	
	mkfs.ext4 /dev/"$1""$part"4
	mkswap /dev/"$1""$part"3 && swapon /dev/"$1""$part"3
fi
if [ "$2" == "UEFI/GPT" ]
then 
	mkfs.vfat -F 32 /dev/"$1""$part"2
fi

#mount partitions
 
mkdir -p /mnt/gentoo
mkdir /mnt/gentoo/boot
mount /dev/"$1""$part"1 /mnt/gentoo/boot
if [ "$2" == "BIOS/MBR" ] 
then 
	mount /dev/"$1""$part"3 /mnt/gentoo
else
	mount /dev/"$1""$part"4 /mnt/gentoo
fi 
if [ "$2" == "UEFI/GPT" ]
then 
	mkdir /mnt/gentoo/boot/efi
	mount /dev/"$1""$part"2 /mnt/gentoo/boot/efi
fi	
cp chroot_install.sh /mnt/gentoo
 
#stage3 tar
cd /mnt/gentoo
curl -o stage3-tar https://mirror.csclub.uwaterloo.ca/gentoo-distfiles/releases/amd64/autobuilds/current-stage3-amd64-openrc/stage3-amd64-openrc-20231126T163200Z.tar.xz 
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
chroot . /chroot_install.sh "$1" "$2" $root1 $username $user1  
