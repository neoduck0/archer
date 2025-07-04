#!/bin/bash
set -euo pipefail

function fnc_init_vars() {
    local disk_pass_confirm
    local user_pass_confirm
    local root_pass_confirm
    local confirm

    lsblk
    echo
    while true; do
        read -p "Disk (eg. sda): " disk
        read -p "Confirm? (y/n): " confirm
        if [[ $confirm =~ ^[Yy]$ ]]; then
            break
        fi
    done
    clear

    while true; do
        read -s -p "Disk pass: " disk_pass
        echo
        read -s -p "Confirm disk pass: " disk_pass_confirm
        echo
        if [[ "$disk_pass" == "$disk_pass_confirm" ]]; then
            break
        else
            echo "Passwords do not match."
        fi
    done
    clear

    while true; do
        read -p "Username (eg. alex): " user
        read -p "Confirm? (y/n): " confirm
        if [[ $confirm =~ ^[Yy]$ ]]; then
            break
        fi
    done
    clear

    while true; do
        read -s -p "User password: " user_pass
        echo
        read -s -p "Confirm user password: " user_pass_confirm
        echo
        if [ "$user_pass" = "$user_pass_confirm" ]; then
            break
        else
            echo "Passwords do not match."
        fi
    done
    clear

    while true; do
        read -s -p "Root password: " root_pass
        echo
        read -s -p "Confirm root password: " root_pass_confirm
        echo
        if [ "$root_pass" = "$root_pass_confirm" ]; then
            break
        else
            echo "Passwords do not match."
        fi
    done
    clear

    while true; do
        read -p "Timezone (empty for UTC): " timezone
        if [ -z "$timezone" ]; then
            timezone="UTC"
        elif [ ! -f "/usr/share/zoneinfo/$timezone" ]; then
            echo "Invalid timezone."
            continue
        fi
        read -p "Confirm? (y/n): " confirm
        if [[ $confirm =~ ^[Yy]$ ]]; then
            break
        fi
    done
    clear

    if [ -d "/sys/firmware/efi" ]; then
        disk_label="gpt"
    else
        disk_label="mbr"
    fi

    if [ $disk_label = gpt ]; then
        if [ $disk = nvme0n1 ]; then
            efi_part=$disk'p1'
            root_part=$disk'p2'
        else
            efi_part=$disk'1'
            root_part=$disk'2'
        fi
    elif [ $disk_label = mbr ]; then
        if [ $disk = nvme0n1 ]; then
            root_part=$disk'p1'
        else
            root_part=$disk'1'
        fi
    fi
}
fnc_init_vars

function fnc_disk() {
    if [ $disk_label = gpt ]; then
        sgdisk --zap-all /dev/$disk
        sgdisk --new=1:0:+1G /dev/$disk
        sgdisk --new=2:0:0 /dev/$disk
    elif [ $disk_label = mbr ]; then
        wipefs -a /dev/$disk
        parted /dev/$disk mklabel msdos --script
        parted /dev/$disk mkpart primary ext4 0% 100% --script
    fi

    echo -n "$disk_pass" | cryptsetup luksFormat --batch-mode /dev/$root_part
    echo -n "$disk_pass" | cryptsetup luksOpen --batch-mode /dev/$root_part root
    unset disk_pass
    mkfs.ext4 /dev/mapper/root -F
    mount /dev/mapper/root /mnt

    if [ $disk_label = gpt ]; then
        mkfs.fat -F32 /dev/$efi_part
        mount --mkdir /dev/$efi_part /mnt/boot
    fi
}
fnc_disk

function fnc_install_linux() {
    set +e
    local exit_code
    pacman -Syy
    for i in {1..10}; do
        pacstrap -K /mnt base linux linux-firmware efibootmgr grub

        exit_code=$?
        if [ $exit_code -eq 0 ]; then
            break
        fi
    done
    if [ $exit_code -ne 0 ]; then
        clear
        echo "Error during packages installation."
        exit 1
    fi
    set -e
}
fnc_install_linux

function fnc_gen_fstab() {
    genfstab -U /mnt >/mnt/etc/fstab
}
fnc_gen_fstab

function fnc_config_users() {
    echo "root:$root_pass" | chpasswd --root /mnt
    useradd -mG wheel $user --root /mnt
    echo "$user:$user_pass" | chpasswd --root /mnt
    sed -i 's|# %wheel ALL=(ALL:ALL) ALL|%wheel ALL=(ALL:ALL) ALL|' /mnt/etc/sudoers
    unset root_pass user_pass
}
fnc_config_users

function fnc_support_encryption() {
    sed -i 's|block filesystems|block sd-encrypt filesystems|' /mnt/etc/mkinitcpio.conf
    sed -i "s|quiet|quiet rd.luks.name=$(blkid -s UUID -o value /dev/$root_part)=root root=/dev/mapper/root|" /mnt/etc/default/grub
    touch /mnt/etc/vconsole.conf
}
fnc_support_encryption

function fnc_config_faillock() {
    sed -i 's|# deny = 3|deny = 5|' /mnt/etc/security/faillock.conf
}
fnc_config_faillock

function fnc_run_mkinitcpio() {
    arch-chroot /mnt mkinitcpio -p linux
}
fnc_run_mkinitcpio

function fnc_set_locales() {
    arch-chroot /mnt bash -c "
		sed -i 's|#en_US.UTF-8|en_US.UTF-8|' /etc/locale.gen
		locale-gen
		echo 'LANG=en_US.UTF-8' >/etc/locale.conf
		echo 'arch' >/etc/hostname
		ln -sf /usr/share/zoneinfo/$timezone /etc/localtime
		hwclock --systohc
	"
}
fnc_set_locales

function fnc_install_grub() {
    if [ $disk_label = gpt ]; then
        arch-chroot /mnt grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
    else
        arch-chroot /mnt grub-install --target=i386-pc /dev/$disk
    fi
    arch-chroot /mnt grub-mkconfig -o /boot/grub/grub.cfg
}
fnc_install_grub

clear
echo "Installation complete."
exit 0
