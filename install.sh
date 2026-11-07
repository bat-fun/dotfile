#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
CONFIG_DIR="${HOME:-}/.config"
BACKUP_DIR="${HOME:-}/.local/share/dotfile-backups/$(date +%Y%m%d-%H%M%S)-$$"
WALLPAPER_DIR="${HOME:-}/Pictures/wallpaper"
BACKUP_CONFIGS=0

CONFIG_PATHS=(
    dunst gtk-3.0 hypr kitty matugen rofi waybar wlogout starship.toml
)

PACKAGES=(
    hyprland waybar rofi kitty dunst hyprlock wlogout
    networkmanager network-manager-applet nm-connection-editor
    bluez bluez-utils blueman
    pipewire pipewire-pulse wireplumber
    wl-clipboard cliphist swww matugen starship
    grim slurp brightnessctl playerctl libnotify
    dolphin code python
    noto-fonts noto-fonts-emoji ttf-jetbrains-mono-nerd ttf-font-awesome
    adwaita-icon-theme
)
AUR_PACKAGES=(brave-bin rofimoji)

say() {
    printf '\n\033[1;38;5;114m  [%s]\033[0m %s\n' "$1" "$2"
}

ask_yes_no() {
    local prompt="$1"
    local default="${2:-no}"
    local answer
    local hint='y/N'

    [[ "$default" == yes ]] && hint='Y/n'
    while true; do
        read -r -p "  $prompt [$hint] " answer || answer=''
        answer="${answer,,}"
        if [[ -z "$answer" ]]; then
            [[ "$default" == yes ]] && return 0 || return 1
        fi
        case "$answer" in
            y|yes) return 0 ;;
            n|no) return 1 ;;
            *) printf '  Please answer y or n.\n' ;;
        esac
    done
}

fail() {
    printf '\n  ERROR: %s\n' "$*" >&2
    exit 1
}

install_official_packages() {
    local missing=()
    local package

    say '01 / Checking packages' 'Checking the Arch package database against the desktop requirements.'
    for package in "${PACKAGES[@]}"; do
        if pacman -Q "$package" >/dev/null 2>&1; then
            printf '  [ok]      %s\n' "$package"
        else
            printf '  [missing] %s\n' "$package"
            missing+=("$package")
        fi
    done

    if ((${#missing[@]} == 0)); then
        printf '  Everything in the official package list is already installed.\n'
        return
    fi

    printf '\n  Missing official packages: %s\n' "${missing[*]}"
    if ! ask_yes_no 'Install these packages now with pacman?' yes; then
        printf '  Skipping package installation. Related features may be unavailable.\n'
        return
    fi

    say 'Installing official packages' 'Review the package manager prompt, then confirm to continue.'
    if (( EUID == 0 )); then
        pacman -S --needed "${missing[@]}"
    else
        command -v sudo >/dev/null 2>&1 || fail 'sudo is required to install packages. Install dependencies manually and rerun.'
        sudo pacman -S --needed "${missing[@]}"
    fi
}

get_aur_helper() {
    if command -v paru >/dev/null 2>&1; then
        printf 'paru'
    elif command -v yay >/dev/null 2>&1; then
        printf 'yay'
    fi
}

install_brave() {
    local helper
    local missing=()
    local package

    say '02 / Extra apps' 'Checking Brave and the emoji picker from the Arch User Repository.'
    for package in "${AUR_PACKAGES[@]}"; do
        if pacman -Q "$package" >/dev/null 2>&1; then
            printf '  [ok]      %s\n' "$package"
        else
            printf '  [missing] %s\n' "$package"
            missing+=("$package")
        fi
    done
    if ((${#missing[@]} == 0)); then
        return 0
    fi

    helper="$(get_aur_helper)"
    if [[ -z "$helper" ]]; then
        printf '  No AUR helper (yay or paru) was found.\n'
        if ! ask_yes_no 'Build and install yay so this setup can install these apps?' yes; then
            printf '  Skipping AUR apps: %s\n' "${missing[*]}"
            return
        fi

        (( EUID != 0 )) || fail 'Do not run makepkg as root. Start the installer as your normal user.'
        command -v sudo >/dev/null 2>&1 || fail 'sudo is required to install yay dependencies.'
        say 'Preparing yay' 'Installing build tools, then building yay as your normal user.'
        sudo pacman -S --needed base-devel git
        local build_dir
        build_dir="$(mktemp -d)"
        if ! git clone https://aur.archlinux.org/yay.git "$build_dir/yay"; then
            rm -rf -- "$build_dir"
            fail 'Could not clone yay from the AUR.'
        fi
        if ! (cd "$build_dir/yay" && makepkg -si); then
            rm -rf -- "$build_dir"
            fail 'Could not build yay. Review the makepkg output and try again.'
        fi
        rm -rf -- "$build_dir"
        helper=yay
    fi

    say 'Installing AUR apps' "Running $helper for ${missing[*]}. Review its package prompts."
    "$helper" -S --needed "${missing[@]}"
}

show_destinations() {
    local path

    printf '  These paths will be replaced with files from this checkout:\n'
    for path in "${CONFIG_PATHS[@]}"; do
        printf '    %s\n' "$CONFIG_DIR/$path"
    done
}

replace_configs() {
    local path
    local source
    local destination
    local existing=()

    say '03 / Configuration files' 'Review the destinations before continuing.'
    show_destinations
    if ! ask_yes_no 'Continue and replace these paths?' no; then
        printf '\n  Configuration was not changed.\n'
        return 1
    fi

    for path in "${CONFIG_PATHS[@]}"; do
        destination="$CONFIG_DIR/$path"
        if [[ -e "$destination" || -L "$destination" ]]; then
            existing+=("$path")
        fi
    done

    if ((${#existing[@]})); then
        printf '\n  Existing paths found: %s\n' "${existing[*]}"
        if ask_yes_no 'Back up these existing paths before replacing them?' yes; then
            BACKUP_CONFIGS=1
            install -d -m 700 -- "$BACKUP_DIR"
            printf '  Backup folder: %s\n' "$BACKUP_DIR"
        else
            printf '  No backup will be created. Existing paths will be replaced.\n'
        fi
    else
        printf '  No existing config paths need a backup.\n'
    fi

    for path in "${CONFIG_PATHS[@]}"; do
        source="$ROOT_DIR/$path"
        destination="$CONFIG_DIR/$path"
        [[ -e "$source" ]] || fail "repository config is missing: $path"

        if [[ -e "$destination" || -L "$destination" ]]; then
            if (( BACKUP_CONFIGS )); then
                mkdir -p -- "$BACKUP_DIR/$(dirname -- "$path")"
                cp -a -- "$destination" "$BACKUP_DIR/$path"
                printf '  [backup] %s\n' "$path"
            fi
            rm -rf -- "$destination"
        fi

        mkdir -p -- "$(dirname -- "$destination")"
        if [[ -d "$source" ]]; then
            mkdir -p -- "$destination"
            cp -a -- "$source/." "$destination/"
        else
            cp -a -- "$source" "$destination"
        fi
        printf '  [copied] %s\n' "$path"
    done
}

generate_colors() {
    local -a wallpapers=()
    local choice
    local wallpaper
    local index=1

    say '04 / Wallpaper colors' 'Matugen can build a matching palette from one of your images.'
    if ! command -v matugen >/dev/null 2>&1; then
        printf '  Matugen is not installed; skipping color generation.\n'
        return
    fi
    if [[ ! -d "$WALLPAPER_DIR" ]]; then
        printf '  No wallpaper folder at %s. Add images there, then run:\n' "$WALLPAPER_DIR"
        printf '  matugen --mode dark --type scheme-fidelity image /path/to/wallpaper.jpg\n'
        return
    fi

    mapfile -d '' -t wallpapers < <(
        find "$WALLPAPER_DIR" -maxdepth 1 -type f \
            \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \) \
            -print0 | sort -z
    )
    if ((${#wallpapers[@]} == 0)); then
        printf '  No JPG, PNG, or WebP images found in %s.\n' "$WALLPAPER_DIR"
        return
    fi

    printf '  Wallpapers found in %s:\n' "$WALLPAPER_DIR"
    for wallpaper in "${wallpapers[@]}"; do
        printf '    %d) %s\n' "$index" "$(basename -- "$wallpaper")"
        index=$((index + 1))
    done
    printf '    0) Skip for now\n'
    read -r -p '  Choose a wallpaper number [1]: ' choice || choice=''
    choice="${choice:-1}"
    [[ "$choice" =~ ^[0-9]+$ ]] || {
        printf '  Invalid choice; skipping color generation.\n'
        return
    }
    if (( choice == 0 )); then
        printf '  Skipping color generation.\n'
        return
    fi
    if (( choice > ${#wallpapers[@]} )); then
        printf '  Choice is outside the list; skipping color generation.\n'
        return
    fi

    wallpaper="${wallpapers[$((choice - 1))]}"
    say 'Generating colors' "Using $(basename -- "$wallpaper")."
    matugen --mode dark --type scheme-fidelity --source-color-index 0 image "$wallpaper"
    printf '  Colors written to the installed Matugen, Waybar, Kitty, Rofi, Dunst, and Starship configs.\n'
}

show_tips() {
    say '05 / All done' 'A few useful next steps.'
    printf '  • Start or reload Hyprland to use the new desktop config.\n'
    printf '  • Put wallpapers in ~/Pictures/wallpaper for the picker.\n'
    printf '  • SUPER + W opens the wallpaper picker; SUPER + R applies a random image.\n'
    printf '  • SUPER + V opens clipboard history; PRINT selects a screenshot area.\n'
    printf '  • The Hyprland config expects a Lua loader that provides the global hl API.\n'
    printf '  • If you skipped packages, run the installer again after installing them.\n'
}

main() {
    printf '\n  NOIR / DOTFILES\n  A Hyprland desktop setup\n\n'
    [[ -n "${HOME:-}" ]] || fail 'HOME is not set.'
    [[ -d "$ROOT_DIR" ]] || fail 'Could not find the dotfile repository.'
    [[ -t 0 ]] || fail 'Run this installer from a terminal so it can ask before installing or replacing files.'
    [[ "$EUID" -ne 0 ]] || fail 'Run this as your normal user, not with sudo.'
    command -v pacman >/dev/null 2>&1 || fail 'This installer is for Arch Linux and Arch-based distributions (pacman required).'
    install_official_packages
    install_brave
    if ! replace_configs; then
        printf '\n  Setup stopped before changing your configs.\n'
        return 0
    fi
    generate_colors
    show_tips
}

main "$@"