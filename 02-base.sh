#!/bin/bash
#02-base
set -Eeuo pipefail
trap 'printf "失敗：%s:%s：%s\n" "${BASH_SOURCE[0]}" "$LINENO" "$BASH_COMMAND" >&2' ERR
echo ""
echo "---FORMATING PARTITIONS---"

mkfs.fat -F 32 "$EFI_PART"
mkfs.ext4 -F -L "ROOT" "$ROOT_PART"
mkswap -L "SWAP" "$SWAP_PART"

echo ""
echo "---MOUNTING PARTITIONS---"

mount "$ROOT_PART" /mnt
mkdir -p /mnt/boot/efi
mount "$EFI_PART" /mnt/boot/efi
swapon "$SWAP_PART"

echo "---配置鏡像源---"
pacman -Sy --noconfirm reflector
# -a : age, -c : country, -f : fast, --v : verbose show process
reflector -a 12 -c tw -f 10 --sort rate --v --save /etc/pacman.d/mirrorlist

pacstrap -K /mnt \
    base linux linux-firmware mkinitcpio \
    vim grub efibootmgr --noconfirm

genfstab -U /mnt >> /mnt/etc/fstab
