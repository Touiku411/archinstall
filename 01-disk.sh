#!/bin/bash
#01-disk
set -e
set -o pipefail

echo ""
echo "---detected disks---"
lsblk -d -n -o NAME,SIZE,MODEL | grep -v "loop"
echo ""

read -p "SELECT DISK: " DISK_NAME
# echo "$DISK_NAME"
TARGET_DISK="/dev/$DISK_NAME"

echo ""
read -p "Make sure selected disk is correct: ${TARGET_DISK} [Y/n] : "  CONFIRM
CONFIRM_LOWER="${CONFIRM,,}"
# if [[ ! "$CONFIRM" =~ ^([Yy][Yy][Ee][Ss])$ ]];
if [[ "$CONFIRM_LOWER" != "y" && "$CONFIRM_LOWER" != "yes" ]]; then
    echo "END PROCESS..."
    exit 1
fi

if [ ! -b "$TARGET_DISK" ]; then
    echo "FAILED! CAN NOT FIND $TARGET_DISK, SCRIPT END..."
    exit 1
fi
echo ""
echo "ALL DATA ON $TARGET_DISK WILL BE DELETED SOON!"
read -p "SURE CONTINUE[Y/n]? " CONFIRM
echo ""
CONFIRM_LOWER="${CONFIRM,,}"
if [[ "$CONFIRM_LOWER" != "y" && "$CONFIRM_LOWER" != "yes" ]]; then
    echo "END PROCESS..."
    exit 1
fi


if [[ "$TARGET_DISK" == *"nvme"* || "$TARGET_DISK" == *"mmcblk"* ]]; then
    EFI_PART="${TARGET_DISK}p1"
    ROOT_PART="${TARGET_DISK}p2"
else
    EFI_PART="${TARGET_DISK}1"
    ROOT_PART="${TARGET_DISK}2"
fi

echo "---START PROCESSING THE DISK---"
echo ""
echo "---BUILDING PARTITIONS---"
parted -s "$TARGET_DISK" mklabel gpt
parted -s "$TARGET_DISK" mkpart "EFI" fat32 1MiB 513MiB
parted -s "$TARGET_DISK" set 1 esp on
parted -s "$TARGET_DISK" mkpart "Root" ext4 513MiB 100%

