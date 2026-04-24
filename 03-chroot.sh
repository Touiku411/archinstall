#!/bin/bash
#03-chroot

USERNAME=$1
HOSTNAME=$2
HAS_NVIDIA=$3
CPU_VENDOR=$4

PKGS_PACMAN=(
    "networkmanager" "sudo" "pipewire" "wireplumber" "pipewire-pulse" 
    "nvtop" "vim" "firefox" "noto-fonts-cjk" "noto-fonts-emoji" 
    "git" "base-devel" "fcitx5-im" "fcitx5-chewing" "fcitx5-qt" 
    "fcitx5-gtk" "fcitx5-chinese-addons" "nautilus" "kitty" "os-prober" "pavucontrol" "fish"
)
if [[ "$HAS_NVIDIA" == "YES" ]]; then
    PKGS_PACMAN+=("nvidia-utils" "nvidia-open-dkms" "nvidia-settings")
fi
if [[ "$CPU_VENDOR" == "INTEL" ]]; then
    PKGS_PACMAN+=("intel-ucode")
elif [[ "$CPU_VENDOR" == "AMD" ]]; then
    PKGS_PACMAN+=("amd-ucode")
fi
pacman -Syu --noconfirm
pacman -S --noconfirm "${PKGS_PACMAN[@]}" 

# swap
swapoff /swapfile 2>/dev/null || true
rm -f /swapfile
fallocate -l 16G /swapfile
chmod 600 /swapfile
mkswap /swapfile
swapon /swapfile
echo "/swapfile none swap defaults 0 0" >> /etc/fstab

ln -sf /usr/share/zoneinfo/Asia/Taipei /etc/localtime
hwclock --systohc

# echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
tee -a /etc/locale.gen > /dev/null <<EOF
en_US.UTF-8 UTF-8
zh_TW.UTF-8 UTF-8
EOF

locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf
echo "KEYMAP=us" > /etc/vconsole.conf
echo "$HOSTNAME" > /etc/hostname
tee -a /etc/hosts > /dev/null <<EOF
127.0.0.1 localhost
::1 localhost
127.0.1.1 $HOSTNAME.localdomain $HOSTNAME
EOF

echo "PLEASE ENTER ROOT PASSWORD: "
passwd
useradd -m -g users -G wheel,audio,video,storage -s /bin/bash $USERNAME
echo "PLEASE ENTER $USERNAME PASSWORD: "
passwd $USERNAME
echo "%wheel ALL=(ALL:ALL) ALL" >> /etc/sudoers

# bootloader grub
grub-install --target=x86_64-efi --bootloader-id=GRUB --efi-directory=/boot/efi
grub-mkconfig -o /boot/grub/grub.cfg

systemctl enable NetworkManager.service

if [[ "$HAS_NVIDIA" == "YES" ]]; then
    sed -i 's/^MODULES=.*/MODULES=(nvidia nvidia_modeset nvidia_uvm nvidia_drm)/' /etc/mkinitcpio.conf
    pacman -S --noconfirm linux-headers
    mkinitcpio -P
    # \( .* \) .*表全部
    if ! grep -q "nvidia_drm.modeset=1" /etc/default/grub; then
        sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="\(.*\)"/GRUB_CMDLINE_LINUX_DEFAULT="\1 nvidia_drm.modeset=1"/' /etc/default/grub
    fi
    # 判斷是不是筆電
    if ls /sys/class/power_supply/ | grep -iq "^BAT"; then
        if ! grep -q "acpi_backlight=native" /etc/default/grub; then
            sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="\(.*\)"/GRUB_CMDLINE_LINUX_DEFAULT="\1 acpi_backlight=native"/' /etc/default/grub
        fi
    fi
    echo "GRUB_DISABLE_OS_PROBER=false" >> /etc/default/grub
    grub-mkconfig -o /boot/grub/grub.cfg
fi

read -p "install hyprland dotfiles ? [Y/n]" CONFIRM
CONFIRM="${CONFIRM,,}"
if [[ "$CONFIRM" == "y" || "$CONFIRM" == "yes" || -z "$CONFIRM" ]]; then
    cd "/home/$USERNAME"
    sudo -H -u "$USERNAME" bash <<'EOF'
    git clone https://github.com/Touiku411/arch-hyprland.git "$HOME/arch-hyprland"
    cd "$HOME/arch-hyprland" && chmod +x setup.sh
    ./setup.sh
EOF
fi


