USERNAME=gor
# Check if it is really UEFI, the output should lists the UEFI variables
efivar -l

# Check for connection

output=$(./ping_test.sh | tail -1)

if [ $output == "ip is up" ] then
	continue
else
	dhcpcd
fi

# Partitioning. Use gdisk: it's an fdisk equilevant for GPT (GUID partition Table) which you need for UEFI boot.
gdisk /dev/sda

# create new GUID partition table and destroy everything on disk
o

# New partition
n

# Create the following ones. Not making a swap because I have plenty of ram. You can make one if you really want it.

sda1
1024M
EF00
/boot

sda2
15G
8300
/

sda3
~G #Rest of disk space
8300
/home

# Show the partition table as it is now
p

# Write the changes and quit
w

# Create filesystems
mkfs.ext4 /dev/sda2
mkfs.ext4 /dev/sda3
mkfs.fat -F32 /dev/sda1

# Mount the filesystems
mount /dev/sda2 /mnt
mkdir /mnt/boot
mkdir /mnt/home
mount /dev/sda1 /mnt/boot
mount /dev/sda3 /mnt/home

# And install the system
pacstrap /mnt base base-devel

# Set up fstab
genfstab -U -p /mnt >> /mnt/etc/fstab

# Configuring the system
arch-chroot /mnt

# Create locale file
# Remove the "#" in front of the locale(s) you need, en_US.UTF-8 in my case
nano /etc/locale.gen

# Save the file and generate the locales
locale-gen

# locale.conf
echo LANG=en_US.UTF-8 > /etc/locale.conf
export LANG=en_US.UTF-8

# Set up the hostname (aeonius in my case)
echo $USERNAME> /etc/hostname

# Install the bootloader
# The mount command will most likely result in an error due to it being loaded already
mount -t efivarfs efivarfs /sys/firmware/efi/efivars
pacman -S gummiboot
gummiboot install

# Create a configuration file to add an entry for Arch Linux to the gummiboot manager
nano /boot/loader/entries/arch.conf

# Contents of arch.conf file should be:
title  Arch Linux
linux  /vmlinuz-linux
initrd  /initramfs-linux.img
options  root=/dev/sda2 rw

# Make sure we have a network connection after we reboot
systemctl enable dhcpcd.service

# Set root password
passwd

# Create a user (edit the first line)
useradd -m -g users -G wheel -s /bin/bash $USERNAME

# Create a password for user
passwd $USERNAME

# Add user to the sudoers group
echo '$USERNAME ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

# Exit out of the chroot, unmount and reboot
exit
umount -R /mnt
reboot
