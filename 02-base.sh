#!/bin/bash
#02-base
echo ""
echo "---FORMATING PARTITIONS---"

mkfs.fat -F 32 "$EFI_PART"
mkfs.ext4 -F "$ROOT_PART"

echo ""
echo "---MOUNTING PARTITIONS---"

mount "$ROOT_PART" /mnt
mkdir -p /mnt/boot/efi
mount "$EFI_PART" /mnt/boot/efi

echo "---配置鏡像源---"
pacman -Sy --noconfirm reflector
# -a : age, -c : country, -f : fast, --v : verbose show process
reflector -a 12 -c tw -f 10 --sort rate --v --save /etc/pacman.d/mirrorlist

pacstrap -i /mnt base linux linux-firmware vim grub efibootmgr --noconfirm
genfstab -U /mnt >> /mnt/etc/fstab
