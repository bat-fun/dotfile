
#!/usr/bin/env bash
set -Eeuo pipefail

# ============================================================
# DOTFILES INSTALLER
# ARCH LINUX | HYPRLAND
# ============================================================

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}"
DATA_DIR="${XDG_DATA_HOME:-$HOME/.local/share}"
WALLPAPER_DIR="$HOME/Pictures/wallpaper"
WALLPAPER_REPO="https://github.com/bat-fun/wallpaper.git"

CONFIG_PATHS=(
    dunst gtk-3.0 hypr kitty matugen rofi waybar wlogout starship.toml
)

PACKAGES=(
    hyprland waybar rofi rofimoji kitty dunst hyprlock awww
    networkmanager network-manager-applet nm-connection-editor
    bluez bluez-utils blueman
    pipewire pipewire-pulse wireplumber
    wl-clipboard cliphist matugen starship
    grim slurp brightnessctl playerctl libnotify
    dolphin code python
    noto-fonts noto-fonts-emoji
    ttf-jetbrains-mono-nerd ttf-font-awesome
    adwaita-icon-theme
)

AUR_PACKAGES=(brave-bin wlogout)

BACKUP_DIR=""
STAGE_DIR=""
BUILD_DIR=""
SELECTED_WALLPAPER=""
KEEP_STAGE=0

declare -a MISSING_PACKAGES=()
declare -a MISSING_AUR=()
declare -a INSTALLED_PATHS=()

if [[ -t 1 ]]; then
    RED='\033[1;38;5;203m'
    GREEN='\033[1;38;5;114m'
    YELLOW='\033[1;38;5;221m'
    BLUE='\033[1;38;5;117m'
    RESET='\033[0m'
else
    RED='' GREEN='' YELLOW='' BLUE='' RESET=''
fi

banner() {
    printf '\n%b' "$RED"
    cat <<'EOF'
      _   _  ___  ___ ___
     | \ | |/ _ \|_ _| _ \
     |  \| | (_) || ||   /
     |_|\__|\___/|___|_|_\
EOF
    printf '%b' "$RESET"
    printf '  DOTFILES INSTALLER\n'
    printf '  ARCH LINUX // HYPRLAND // WAYLAND\n\n'
}

log() {
    printf '\n%b[ %s ]%b %s\n' "$BLUE" "$1" "$RESET" "$2"
}

success() {
    printf '  %b[+]%b %s\n' "$GREEN" "$RESET" "$1"
}

warning() {
    printf '  %b[!]%b %s\n' "$YELLOW" "$RESET" "$1"
}

error() {
    printf '\n%b[ERROR]%b %s\n' "$RED" "$RESET" "$*" >&2
}

die() {
    error "$@"
    exit 1
}

ask() {
    local prompt="$1"
    local default="${2:-no}"
    local answer
    local hint="y/N"

    [[ "$default" == yes ]] && hint="Y/n"

    while true; do
        if ! read -r -p "  $prompt [$hint] " answer; then
            return 1
        fi

        answer="${answer,,}"

        case "$answer" in
            "")
                [[ "$default" == yes ]]
                return
                ;;
            y|yes) return 0 ;;
            n|no) return 1 ;;
            *) printf '  Enter y or n.\n' ;;
        esac
    done
}

cleanup() {
    if [[ -n "$STAGE_DIR" && -d "$STAGE_DIR" ]]; then
        if (( KEEP_STAGE )); then
            warning "Recovery files preserved: $STAGE_DIR"
        else
            rm -rf -- "$STAGE_DIR"
        fi
    fi

    if [[ -n "$BUILD_DIR" && -d "$BUILD_DIR" ]]; then
        rm -rf -- "$BUILD_DIR"
    fi
}

trap cleanup EXIT

validate_environment() {
    log "01 // SYSTEM CHECK" "Checking the environment."

    [[ -n "${HOME:-}" ]] || die "HOME is not set."
    [[ "$EUID" -ne 0 ]] || die "Run as your normal user."
    [[ -t 0 ]] || die "Run from an interactive terminal."

    command -v pacman >/dev/null 2>&1 ||
        die "Arch Linux is required."

    command -v git >/dev/null 2>&1 ||
        die "Install Git first: sudo pacman -S git"

    for path in "${CONFIG_PATHS[@]}"; do
        [[ -e "$ROOT_DIR/$path" || -L "$ROOT_DIR/$path" ]] ||
            die "Missing repository configuration: $path"
    done

    mkdir -p -- "$CONFIG_DIR" "$HOME/Pictures"

    success "Environment validated."
}

check_official_packages() {
    log "02 // ARSENAL" "Checking official packages."

    MISSING_PACKAGES=()

    for package in "${PACKAGES[@]}"; do
        if pacman -Q "$package" >/dev/null 2>&1; then
            success "$package"
        else
            warning "Missing: $package"
            MISSING_PACKAGES+=("$package")
        fi
    done

    ((${#MISSING_PACKAGES[@]})) || {
        success "All official packages installed."
        return 0
    }

    printf '\n  Missing packages:\n'
    printf '    %s\n' "${MISSING_PACKAGES[@]}"

    ask "Install missing official packages?" yes || {
        warning "Skipping official packages."
        return 0
    }

    command -v sudo >/dev/null 2>&1 ||
        die "sudo is required."

    sudo pacman -S --needed "${MISSING_PACKAGES[@]}"
}

get_aur_helper() {
    if command -v paru >/dev/null 2>&1; then
        printf 'paru'
    elif command -v yay >/dev/null 2>&1; then
        printf 'yay'
    fi
}

install_yay() {
    log "03 // AUR" "Preparing yay."

    sudo pacman -S --needed base-devel git

    BUILD_DIR="$(mktemp -d "${TMPDIR:-/tmp}/noir-yay.XXXXXXXX")"

    git clone --depth 1 \
        https://aur.archlinux.org/yay.git "$BUILD_DIR/yay"

    (
        cd "$BUILD_DIR/yay"
        makepkg -si
    )

    rm -rf -- "$BUILD_DIR"
    BUILD_DIR=""

    command -v yay >/dev/null 2>&1 ||
        die "yay installation could not be verified."
}

check_aur_packages() {
    local helper

    log "03 // AUR" "Checking extra applications."

    MISSING_AUR=()

    for package in "${AUR_PACKAGES[@]}"; do
        if pacman -Q "$package" >/dev/null 2>&1; then
            success "$package"
        else
            warning "Missing: $package"
            MISSING_AUR+=("$package")
        fi
    done

    ((${#MISSING_AUR[@]})) || return 0

    ask "Install missing AUR applications?" yes || {
        warning "Skipping AUR applications."
        return 0
    }

    helper="$(get_aur_helper || true)"

    if [[ -z "$helper" ]]; then
        ask "Build yay because no AUR helper exists?" yes || return 0
        install_yay
        helper="yay"
    fi

    "$helper" -S --needed "${MISSING_AUR[@]}"
}

validate_configs() {
    local path

    for path in "${CONFIG_PATHS[@]}"; do
        [[ -e "$ROOT_DIR/$path" || -L "$ROOT_DIR/$path" ]] ||
            die "Missing source: $path"

        if [[ "$path" == starship.toml ]]; then
            [[ -f "$ROOT_DIR/$path" ]] ||
                die "Expected a regular file: $path"
        else
            [[ -d "$ROOT_DIR/$path" ]] ||
                die "Expected a directory: $path"
        fi
    done
}

rollback_configs() {
    local index path destination previous

    warning "Deployment failed. Rolling back."

    for ((index=${#INSTALLED_PATHS[@]} - 1; index>=0; index--)); do
        path="${INSTALLED_PATHS[$index]}"
        destination="$CONFIG_DIR/$path"
        previous="$STAGE_DIR/rollback/$path"

        if ! rm -rf -- "$destination"; then
            KEEP_STAGE=1
            error "Could not remove: $destination"
            continue
        fi

        if [[ -e "$previous" || -L "$previous" ]]; then
            mkdir -p -- "$(dirname -- "$destination")"

            if ! mv -- "$previous" "$destination"; then
                KEEP_STAGE=1
                error "Could not restore: $destination"
            fi
        fi
    done
}

install_configs() {
    local path destination source previous backup_path
    local -a existing=()

    log "04 // DEPLOYMENT" "Preparing configurations."

    validate_configs

    printf '\n  Paths to replace:\n'
    for path in "${CONFIG_PATHS[@]}"; do
        printf '    %s\n' "$CONFIG_DIR/$path"
    done

    ask "Continue with installation?" no || return 1

    for path in "${CONFIG_PATHS[@]}"; do
        destination="$CONFIG_DIR/$path"
        if [[ -e "$destination" || -L "$destination" ]]; then
            existing+=("$path")
        fi
    done

    STAGE_DIR="$(mktemp -d "$CONFIG_DIR/.noir-install.XXXXXXXX")"
    mkdir -p "$STAGE_DIR/payload" "$STAGE_DIR/rollback"

    for path in "${CONFIG_PATHS[@]}"; do
        cp -a -- "$ROOT_DIR/$path" "$STAGE_DIR/payload/$path" ||
            die "Could not stage $path."
    done

    if ((${#existing[@]})); then
        printf '\n  Existing configurations detected:\n'
        printf '    %s\n' "${existing[@]}"

        if ask "Back up existing configurations?" yes; then
            mkdir -p "$DATA_DIR/dotfile-backups"
            BACKUP_DIR="$(mktemp -d "$DATA_DIR/dotfile-backups/noir-XXXXXXXX")"
            chmod 700 "$BACKUP_DIR"

            for path in "${existing[@]}"; do
                destination="$CONFIG_DIR/$path"
                backup_path="$BACKUP_DIR/$path"
                mkdir -p "$(dirname "$backup_path")"

                cp -a -- "$destination" "$backup_path" ||
                    die "Backup failed for $path."

                success "Backed up $path"
            done

            success "Backup: $BACKUP_DIR"
        else
            warning "Permanent backup skipped."
        fi
    fi

    INSTALLED_PATHS=()

    for path in "${CONFIG_PATHS[@]}"; do
        destination="$CONFIG_DIR/$path"
        source="$STAGE_DIR/payload/$path"
        previous="$STAGE_DIR/rollback/$path"

        if [[ -e "$destination" || -L "$destination" ]]; then
            if ! mv -- "$destination" "$previous"; then
                rollback_configs
                return 1
            fi
        fi

        INSTALLED_PATHS+=("$path")

        if ! mv -- "$source" "$destination"; then
            rollback_configs
            return 1
        fi

        success "Installed $path"
    done

    INSTALLED_PATHS=()
    success "Configuration deployment completed."
}

has_wallpapers() {
    [[ -d "$WALLPAPER_DIR" ]] || return 1

    find "$WALLPAPER_DIR" -maxdepth 1 -type f \
        \( -iname '*.jpg' -o -iname '*.jpeg' \
        -o -iname '*.png' -o -iname '*.webp' \
        -o -iname '*.gif' \) -print -quit | grep -q .
}

fetch_wallpapers() {
    local image count=0

    log "05 // THE CAVE" "Checking wallpaper collection."

    mkdir -p "$WALLPAPER_DIR"

    if has_wallpapers; then
        success "Existing wallpapers detected."
        return 0
    fi

    warning "No wallpapers found. Cloning collection."

    BUILD_DIR="$(mktemp -d "${TMPDIR:-/tmp}/noir-wallpapers.XXXXXXXX")"

    if ! git clone --depth 1 "$WALLPAPER_REPO" "$BUILD_DIR/repo"; then
        warning "Wallpaper download failed."
        rm -rf "$BUILD_DIR"
        BUILD_DIR=""
        return 0
    fi

    while IFS= read -r -d '' image; do
        if cp -n -- "$image" "$WALLPAPER_DIR/"; then
            count=$((count + 1))
        fi
    done < <(
        find "$BUILD_DIR/repo" -maxdepth 1 -type f \
            \( -iname '*.jpg' -o -iname '*.jpeg' \
            -o -iname '*.png' -o -iname '*.webp' \
            -o -iname '*.gif' \) -print0
    )

    rm -rf "$BUILD_DIR"
    BUILD_DIR=""

    success "Added $count wallpapers."
}

choose_wallpaper() {
    local -a wallpapers=()
    local choice index=1 wallpaper

    SELECTED_WALLPAPER=""

    mapfile -d '' -t wallpapers < <(
        find "$WALLPAPER_DIR" -maxdepth 1 -type f \
            \( -iname '*.jpg' -o -iname '*.jpeg' \
            -o -iname '*.png' -o -iname '*.webp' \
            -o -iname '*.gif' \) -print0 | sort -z
    )

    ((${#wallpapers[@]})) || {
        warning "No wallpapers available."
        return 0
    }

    printf '\n  AVAILABLE WALLPAPERS\n'

    for wallpaper in "${wallpapers[@]}"; do
        printf '    %d) %s\n' "$index" "$(basename "$wallpaper")"
        index=$((index + 1))
    done

    printf '    0) Skip\n'

    read -r -p '  Select wallpaper [1]: ' choice || return 0
    choice="${choice:-1}"

    [[ "$choice" =~ ^[0-9]+$ ]] || {
        warning "Invalid selection."
        return 0
    }

    (( choice == 0 )) && return 0

    if (( choice > ${#wallpapers[@]} )); then
        warning "Selection outside the list."
        return 0
    fi

    SELECTED_WALLPAPER="${wallpapers[$((choice - 1))]}"
    success "Selected $(basename "$SELECTED_WALLPAPER")"
}

generate_colors() {
    [[ -n "$SELECTED_WALLPAPER" ]] || return 0

    log "06 // SHADOWS" "Generating Matugen palette."

    if matugen --mode dark --type scheme-fidelity \
        --source-color-index 0 image "$SELECTED_WALLPAPER"; then
        success "Colors generated."
    else
        warning "Matugen failed."
    fi
}

start_services() {
    local unit

    log "07 // SYSTEM SERVICES" "Checking background services."

    if ! command -v systemctl >/dev/null 2>&1; then
        warning "systemctl unavailable."
        return 0
    fi

    if ask "Enable and start NetworkManager and Bluetooth?" yes; then
        for unit in NetworkManager.service bluetooth.service; do
            if systemctl list-unit-files "$unit" --no-legend |
                grep -q "$unit"; then
                if sudo systemctl enable --now "$unit"; then
                    success "$unit enabled and started."
                else
                    warning "Could not start $unit."
                fi
            fi
        done
    fi

    if systemctl --user show-environment >/dev/null 2>&1; then
        if systemctl --user enable --now \
            pipewire.socket pipewire-pulse.socket wireplumber.service; then
            success "PipeWire and WirePlumber started."
        else
            warning "Audio services could not all be started."
        fi
    else
        warning "User systemd session unavailable."
    fi
}

start_awww() {
    log "08 // WALLPAPER ENGINE" "Starting AWWW."

    if ! command -v awww >/dev/null 2>&1 ||
       ! command -v awww-daemon >/dev/null 2>&1; then
        warning "AWWW unavailable."
        return 0
    fi

    if [[ -z "${WAYLAND_DISPLAY:-}" ]]; then
        warning "No active Wayland session."
        return 0
    fi

    if ! awww query >/dev/null 2>&1; then
        nohup awww-daemon >/dev/null 2>&1 &

        local attempt
        for attempt in {1..10}; do
            sleep 1
            awww query >/dev/null 2>&1 && break
        done
    fi

    if ! awww query >/dev/null 2>&1; then
        warning "AWWW daemon failed to start."
        return 0
    fi

    success "AWWW daemon running."

    if [[ -n "$SELECTED_WALLPAPER" ]]; then
        if awww img "$SELECTED_WALLPAPER"; then
            success "Wallpaper applied."
        else
            warning "Could not apply wallpaper."
        fi
    fi
}

finish() {
    log "09 // MISSION COMPLETE" "Installation finished."

    success "Configurations deployed."
    success "Wallpaper directory: $WALLPAPER_DIR"

    [[ -z "$BACKUP_DIR" ]] ||
        success "Backup: $BACKUP_DIR"

    printf '\n  NEXT STEPS\n'
    printf '  • Ensure your Hyprland Lua loader provides the hl API.\n'
    printf '  • Log out and back into Hyprland if needed.\n'
    printf '  • SUPER + W: Wallpaper picker\n'
    printf '  • SUPER + R: Random wallpaper\n'
    printf '  • SUPER + V: Clipboard history\n'
    printf '  • PRINT: Screenshot selection\n'

    printf '\n%b  THE NIGHT IS YOURS.%b\n\n' "$RED" "$RESET"
}

main() {
    banner

    validate_environment
    check_official_packages
    check_aur_packages

    install_configs || {
        warning "Configuration installation cancelled or failed."
        return 1
    }

    fetch_wallpapers
    choose_wallpaper
    generate_colors

    start_services
    start_awww

    finish
}

main "$@"