source /etc/profile

#Portage

emerge-webrsync
emerge -vuDN @world

#user accounts
(
echo "$2"
echo "$2"
) | passwd

useradd -g users -G wheel,portage,audio,video,usb,cdrom -m "$3"
(
echo "$4"
echo "$4"
) | passwd "$3"

#install vim 
emerge -v vim 

#locale

(
echo LANG=\"en_US.UTF-8\"
echo LC_COLLATE=\"C\"
) >> /etc/env.d/02locale

(
echo en_US.UTF-8 UTF-8
echo C.UTF8 UTF-8
) >> /etc/locale.gen

locale-gen 

echo hostname=\"pc\" >> /etc/conf.d/hostname

ln -sf /usr/share/zoneinfo/Canada/Eastern /etc/localtime

#kernel 

echo sys-kernel/linux-firmware linux-fw-redistributable >> /etc/portage/package.license

emerge -v sys-kernel/gentoo-sources sys-kernel/linux-firmware
cd /usr/src/linux*

make localyesconfig
make

#install

make modules_install
make install

#bootloader 

echo GRUB_PLATFORMS=\"pc\" >> /etc/portage/make.conf
emerge sys-boot/grub
grub-install /dev/"$1" --target=i386-pc
grub-mkconfig -o /boot/grub/grub.cfg

#network 
emerge net-misc/dhcpcd
rc-update add dhcpcd default
rc-service dhcpcd start
