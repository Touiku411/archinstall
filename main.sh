#!/bin/bash
#main
set -e

LOG_FILE="arch_install_$(date +%Y%m%d_%H%M%S).log"
exec > >(tee -a "$LOG_FILE") 2>&1

export USERNAME="touiku"
export HOSTNAME="archlinux"

echo "=== Arch Linux Toukiu Script ==="

if ! command -v mkfs.fat &> /dev/null; then
    sudo pacman -Sy --noconfirm dosfstools
fi
if ! command -v pacstrap &> /dev/null; then
    sudo pacman -Sy --noconfirm arch-install-scripts
fi

source ./01-disk.sh
source ./02-base.sh

echo "SCANNING NVIDIA GPU"
if lspci | grep -i -E "VGA|3D" | grep -iq  nvidia; then
    export HAS_NVIDIA="YES"
else
    export HAS_NVIDIA="NO"
fi

echo "SCANNING CPU"
if grep -iq "amd" /proc/cpuinfo; then
    export CPU_VENDOR="AMD"
elif grep -iq "intel" /proc/cpuinfo; then
    export CPU_VENDOR="INTEL"
else
    export CPU_VENDOR="UNKNOWN"
fi



cp ./03-chroot.sh /mnt
chmod +x /mnt/03-chroot.sh
arch-chroot /mnt /03-chroot.sh "$USERNAME" "$HOSTNAME" "$HAS_NVIDIA" "$CPU_VENDOR"
rm /mnt/03-chroot.sh

swapoff /mnt/swapfile 2>/dev/null || true
umount -R /mnt || umount -l -R /mnt


read -p "install complete reboot now？ [Y/n]: " REBOOT_CONFIRM
REBOOT_LOWER="${REBOOT_CONFIRM,,}"
if [[ "$REBOOT_LOWER" == "y" || "$REBOOT_LOWER" == "yes" || -z "$REBOOT_CONFIRM" ]]; then
    echo "reboot now..."
    reboot
fi

