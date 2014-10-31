USERNAME=gor
HOSTNAME=myarch
# Check if it is really UEFI, the output should lists the UEFI variables
efivar -l

# Check for connection

output=$(./ping_test.sh | tail -1)

if [ "$output" == "ip is up" ]; then
	echo -e "connection is up"
else
	echo -e "connection is down. trying to acquire IP....."
	dhcpcd
fi

# Partitioning. Use gdisk: it's an fdisk equilevant for GPT (GUID partition Table) which you need for UEFI boot.
##gdisk /dev/sda < partition.txt

# Create filesystems
mkfs.ext4 /dev/sda2
##mkfs.ext4 /dev/sda3
mkfs.fat -F32 /dev/sda1

# Mount the filesystems
mount /dev/sda2 /mnt
mkdir /mnt/boot
##mkdir /mnt/home
mount /dev/sda1 /mnt/boot
##mount /dev/sda3 /mnt/home

# And install the system
pacstrap /mnt base base-devel

##pacman-key --init && pacman-key --populate archlinux
##pacman -Sy

# Set up fstab
genfstab -U -p /mnt >> /mnt/etc/fstab

# Configuring the system
arch-chroot /mnt /bin/bash

# Create locale file
# Remove the "#" in front of the locale(s) you need, en_US.UTF-8 in my case
nano /etc/locale.gen

# Save the file and generate the locales
locale-gen

# locale.conf
echo LANG=en_US.UTF-8 > /etc/locale.conf
export LANG=en_US.UTF-8

# Set up the hostname (edit 2nd line to customize)
echo "setting hostname as $HOSTNAME"
echo $HOSTNAME> /etc/hostname

#install bootloader

#pacman -S grub-efi-x86_64
#mkdir -p /boot/efi
#mount -t vfat /dev/sda1 /boot/efi

#modprobe dm-mod
#grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=arch_grub --boot-directory=/boot/efi/EFI --recheck --debug
#mkdir -p /boot/efi/EFI/grub/locale
#cp /usr/share/locale/en\@quot/LC_MESSAGES/grub.mo /boot/efi/EFI/grub/locale/en.mo
#grub-mkconfig -o /boot/efi/EFI/grub/grub.cfg

# Install the bootloader
# The mount command will most likely result in an error due to it being loaded already
mount -t efivarfs efivarfs /sys/firmware/efi/efivars
pacman -S gummiboot
gummiboot install

# Copy configuration file to add an entry for Arch Linux to the gummiboot manager
cp arch.conf /boot/loader/entries/

# Make sure we have a network connection after we reboot
systemctl enable dhcpcd.service

# Set root password
echo "set root password"
passwd

# Create a user (edit the first line)
useradd -m -g users -G wheel -s /bin/bash $USERNAME

# Create a password for user
echo "set password for $USERNAME"
passwd $USERNAME

# Add user to the sudoers group
echo '$USERNAME ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

# Exit out of the chroot, unmount and reboot
exit
#umount -R /mnt
#reboot
