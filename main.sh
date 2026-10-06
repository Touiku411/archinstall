#!/bin/bash
#main
set -Eeuo pipefail
trap 'printf "失敗：%s:%s：%s\n" "${BASH_SOURCE[0]}" "$LINENO" "$BASH_COMMAND" >&2' ERR

#LOG_FILE="arch_install_$(date +%Y%m%d_%H%M%S).log"
#exec > >(tee -a "$LOG_FILE") 2>&1

export USERNAME="touiku"
export HOSTNAME="archlinux"

echo "=== Arch Linux Toukiu Script ==="

if ! command -v mkfs.fat &> /dev/null; then
    pacman -Sy --noconfirm dosfstools
fi
if ! command -v pacstrap &> /dev/null; then
    pacman -Sy --noconfirm arch-install-scripts
fi

if (( EUID != 0 )); then
    echo "請使用 root 執行安裝腳本。" >&2
    exit 1
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

SWAP_UUID=$(blkid -s UUID -o value "$SWAP_PART")
[[ -n "$SWAP_UUID" ]] || {
    echo "無法取得目標 swap UUID。" >&2
    exit 1
}

cp ./03-chroot.sh /mnt/03-chroot.sh
chmod +x /mnt/03-chroot.sh

arch-chroot /mnt /03-chroot.sh \
    "$USERNAME" "$HOSTNAME" "$HAS_NVIDIA" "$CPU_VENDOR" "$SWAP_UUID"

rm /mnt/03-chroot.sh


swapoff -a
umount -R /mnt || umount -l -R /mnt

read -p "install complete reboot now？ [Y/n]: " REBOOT_CONFIRM
REBOOT_LOWER="${REBOOT_CONFIRM,,}"
if [[ "$REBOOT_LOWER" == "y" || "$REBOOT_LOWER" == "yes" || -z "$REBOOT_CONFIRM" ]]; then
    echo "reboot now..."
    reboot
fi



