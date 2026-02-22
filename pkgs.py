#!/bin/python3

import os
import sys
import difflib
import subprocess

PROFILE = "hyprland"


def main():
    if len(sys.argv) == 1:
        print("Error: provide arguments.")
        sys.exit(1)

    match " ".join(sys.argv[1:]):
        case "diff":
            diff()
        case "installable":
            print(get_installable(PROFILE, ""))
        case "installable aur":
            print(get_installable(PROFILE, "aur"))
        case "installable flatpak":
            print(get_installable(PROFILE, "flatpak"))
        case _:
            print("Error: arguments invalid.")


def diff():
    selected = PROFILES[PROFILE] + AUR
    selected.sort()
    selected += FLATPAKS

    installed = (
        subprocess.run(
            ["pacman", "-Qeq"], capture_output=True, text=True
        ).stdout.split()
        + subprocess.run(
            ["flatpak", "list", "--app", "--columns=application"],
            capture_output=True,
            text=True,
        ).stdout.split()
    )

    diff = list(difflib.ndiff(selected, installed))
    for line in diff:
        if line.startswith(("+", "-")):
            print(line)


def get_installable(profile, type):
    return_str = ""

    if type == "":
        for pkg in PROFILES.get(profile, []):
            return_str += " " + pkg

    if type == "aur":
        for pkg in AUR:
            return_str += " " + pkg

    if type == "flatpak":
        for pkg in FLATPAKS:
            return_str += " " + pkg

    return return_str


FLATPAKS = [
    "com.obsproject.Studio",
    "com.usebottles.bottles",
    "dev.vencord.Vesktop",
    "org.libreoffice.LibreOffice",
    "org.shotcut.Shotcut",
]

AUR = ["helium-browser-bin", "yay", "code-marketplace"]

BASIC = [
    "ascii",
    "base",
    "base-devel",
    "bash-language-server",
    "btop",
    "btrfs-progs",
    "clang",
    "curl",
    "dosfstools",
    "exfatprogs",
    "fastfetch",
    "fd",
    "fuse2",
    "fzf",
    "git",
    "go",
    "gopls",
    "gptfdisk",
    "grub",
    "impala",
    "intel-ucode",
    "iwd",
    "keyd",
    "libnewt",
    "linux",
    "linux-firmware",
    "lua-language-server",
    "man-db",
    "neovim",
    "nodejs",
    "npm",
    "ntfs-3g",
    "openconnect",
    "openssh",
    "openvpn",
    "pacman-contrib",
    "papirus-icon-theme",
    "pyright",
    "python-pip",
    "rclone",
    "reflector",
    "ripgrep",
    "ruff",
    "rust",
    "sbctl",
    "shfmt",
    "sudo",
    "tmux",
    "typescript",
    "typescript-language-server",
    "udisks2",
    "ufw",
    "unzip",
    "usbutils",
    "uv",
    "vscode-css-languageserver",
    "vscode-html-languageserver",
    "vscode-json-languageserver",
    "wget",
    "zip",
    "zram-generator",
    "zsh",
]

if not os.path.exists("/sys/firmware/uefi"):
    BASIC.append("efibootmgr")

DESKTOP = [
    "accountsservice",
    "amberol",
    "android-tools",
    "bluez",
    "bluez-utils",
    "calf",
    "code",
    "deluge-gtk",
    "dmidecode",
    "dnsmasq",
    "eartag",
    "easyeffects",
    "ffmpeg",
    "flatpak",
    "flatseal",
    "gnome-calculator",
    "gnome-clocks",
    "gnome-disk-utility",
    "gnome-sound-recorder",
    "gst-plugins-bad",
    "gvfs-mtp",
    "imagemagick",
    "kitty",
    "loupe",
    "morphosis",
    "mpv",
    "nautilus",
    "noto-fonts",
    "noto-fonts-cjk",
    "noto-fonts-emoji",
    "noto-fonts-extra",
    "ollama",
    "ollama-vulkan",
    "opencode",
    "papers",
    "pdfarranger",
    "pdftk",
    "pipewire",
    "pipewire-alsa",
    "pipewire-jack",
    "pipewire-pulse",
    "polkit-gnome",
    "pyside6",
    "python",
    "qemu-full",
    "scrcpy",
    "snapshot",
    "sof-firmware",
    "solanum",
    "spice-vdagent",
    "swtpm",
    "syncplay",
    "ttf-jetbrains-mono-nerd",
    "virt-manager",
    "vulkan-icd-loader",
    "vulkan-intel",
    "wireplumber",
    "yt-dlp",
    "zed",
]

PROFILES = {
    "hyprland": [
        "bluetui",
        "brightnessctl",
        "cliphist",
        "hypridle",
        "hyprland",
        "hyprlock",
        "hyprpaper",
        "hyprpicker",
        "hyprshot",
        "mako",
        "pavucontrol",
        "power-profiles-daemon",
        "qt5-wayland",
        "qt6-wayland",
        "rofi",
        "uwsm",
        "waybar",
        "wev",
        "wl-clip-persist",
        "wl-clipboard",
        "xdg-desktop-portal-gtk",
        "xdg-desktop-portal-hyprland",
        "xdg-user-dirs",
    ]
    + BASIC
    + DESKTOP,
}

if __name__ == "__main__":
    main()
