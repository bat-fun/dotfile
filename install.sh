#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$SCRIPT_DIR"
CONFIG_DIR="${HOME}/.config"
BACKUP_DIR="${HOME}/.dotfiles-backup-$(date +%Y%m%d-%H%M%S)"
DRY_RUN=0
FORCE=0
SKIP_INSTALL=0
INSTALL_PACKAGES=0
INSTALL_HYPRLAND=0
INSTALL_AUR=0
CONFIG_REPLACE=0
CONFIG_ENTRIES=(dunst gtk-3.0 hypr kitty matugen rofi waybar wlogout starship.toml)

say() {
    printf '\n✨ %s\n' "$*"
}

print_banner() {
    local cyan='' green='' dim='' bold='' reset=''
    local quotes=(
        'May your tools stay quiet and your ideas travel far.'
        'Small comforts add up: one keybinding, one calmer day.'
        'Build patiently; let the little things feel like home.'
        'Good tools make space for good work and gentle pauses.'
    )
    local quote_index=$((RANDOM % ${#quotes[@]}))

    if [[ -t 1 ]]; then
        cyan=$'\033[38;5;44m'
        green=$'\033[38;5;114m'
        dim=$'\033[2m'
        bold=$'\033[1m'
        reset=$'\033[0m'
    fi

    printf '\n%s╭────────────────────────────────────────────────────────╮%s\n' "$cyan" "$reset"
    printf '%s│%s  %sDOTFILES%s  %s/%s  ARCH DESKTOP SETUP                     %s│%s\n' \
        "$cyan" "$reset" "$bold" "$reset" "$green" "$dim" "$cyan" "$reset"
    printf '%s│%s  Hyprland  ·  Kitty  ·  Waybar  ·  Rofi                %s│%s\n' \
        "$cyan" "$reset" "$cyan" "$reset"
    printf '%s╰────────────────────────────────────────────────────────╯%s\n' "$cyan" "$reset"
    printf '\n%s“%s”%s\n\n' "$dim" "${quotes[$quote_index]}" "$reset"
}

spin() {
    local i
    local frames=('⠋' '⠙' '⠹' '⠸' '⠼' '⠴' '⠦' '⠧' '⠇' '⠏')

    if [[ -t 1 ]]; then
        for i in {0..23}; do
            printf '\r\033[38;5;44m%s\033[0m  Preparing your desktop  %s' \
                "${frames[$((i % ${#frames[@]}))]}" "${frames[$(((i + 4) % ${#frames[@]}))]}"
            sleep 0.08
        done
        printf '\r\033[38;5;114m✓\033[0m  Setup is ready.                         \n'
    else
        printf '[1/3] Checking the setup...\n'
        printf '[2/3] Preparing your desktop...\n'
        printf '[3/3] Ready to continue.\n'
    fi
}

usage() {
    cat <<'EOF_USAGE'
Usage: ./install.sh [options]

Options:
  --dry-run          Show what would happen without changing the system.
  --force            Back up existing config files and overwrite them.
  --skip-install     Skip package installation and only link dotfiles.
  -h, --help         Show this help message.
EOF_USAGE
}

log() {
    printf '\n[%s] %s\n' "dotfiles" "$*"
}

warn() {
    printf '\n[warn] %s\n' "$*" >&2
}

fail() {
    printf '\n[error] %s\n' "$*" >&2
    exit 1
}

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

check_arch_only() {
    if ! command_exists pacman; then
        fail "This installer is intended for Arch Linux and Arch-based distros only. pacman was not found."
    fi
}

network_fail() {
    warn "Network failed while ${1}. Please check your internet connection and try again."
}

ask_yes_no() {
    local prompt="$1"
    local answer

    while true; do
        read -r -p "$prompt [Y/n]: " answer || answer="n"
        case "${answer:-Y}" in
            [Yy]|[Yy][Ee][Ss]) return 0 ;;
            [Nn]|[Nn][Oo]) return 1 ;;
            *) printf 'Please answer yes or no.\n' >&2 ;;
        esac
    done
}

show_preflight_summary() {
    local base_state="skipped"
    local hypr_state="skipped"
    local aur_state="skipped"
    local config_state="existing configs will be preserved"
    local wallpaper_state="not checked yet"

    if (( INSTALL_PACKAGES )); then
        base_state="install"
    fi
    if (( INSTALL_HYPRLAND )); then
        hypr_state="install"
    fi
    if (( INSTALL_AUR )); then
        aur_state="install"
    fi
    if (( CONFIG_REPLACE )); then
        config_state="back up existing configs, then link dotfiles"
    fi

    if [[ -d "$HOME/Pictures/wallpaper" ]] && [[ -n "$(find "$HOME/Pictures/wallpaper" -maxdepth 1 -type f \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \) 2>/dev/null)" ]]; then
        wallpaper_state="existing wallpaper found"
    elif [[ -d "$HOME/Pictures/wallpaper" ]]; then
        wallpaper_state="folder exists, no images found"
    else
        wallpaper_state="no wallpaper detected"
    fi

    print_banner
    say "Preflight summary"
    printf 'System: Arch / Arch-based detected via pacman\n'
    printf 'Base packages: %s\n' "$base_state"
    printf 'Hyprland stack: %s\n' "$hypr_state"
    printf 'AUR extras: %s\n' "$aur_state"
    printf 'Dotfile configs: %s\n' "$config_state"
    printf 'Wallpaper state: %s\n' "$wallpaper_state"
    printf 'Optional apps to watch for: brave, VS Code, Thunar, NetworkManager applet, blueman\n'
    printf 'Theme sync: Matugen if installed; otherwise skip with a warning\n'
    printf 'Fonts: JetBrainsMono Nerd Font and Noto Color Emoji; fallback if absent\n\n'

    if (( SKIP_INSTALL )); then
        printf 'Install mode: package install disabled by flag\n'
    else
        printf 'Install mode: interactive package decisions are active\n'
    fi
}

run_cmd() {
    if (( DRY_RUN )); then
        printf 'DRY-RUN: %s\n' "$*"
        return 0
    fi
    "$@"
}

ensure_sudo() {
    if command_exists sudo; then
        sudo -n true >/dev/null 2>&1 || warn "sudo is available but passwordless access is not configured. You may be prompted during install."
    fi
}

detect_package_manager() {
    if command_exists pacman; then
        echo "pacman"
    else
        echo "unknown"
    fi
}

install_yay() {
    if command_exists yay; then
        return 0
    fi

    if [[ "$EUID" -eq 0 ]]; then
        warn "Running as root is not recommended for yay installation. Please run as a normal user."
        return 1
    fi

    log "Installing yay from the AUR..."

    if ! command_exists git; then
        warn "git is required to install yay. Skipping yay setup."
        return 1
    fi

    if ! command_exists makepkg; then
        warn "makepkg is required to build yay. Install base-devel first."
        return 1
    fi

    local yay_dir
    yay_dir="$(mktemp -d)"

    if (( DRY_RUN )); then
        printf 'DRY-RUN: git clone https://aur.archlinux.org/yay.git %s\n' "$yay_dir"
        printf 'DRY-RUN: cd %s && makepkg -si --noconfirm\n' "$yay_dir"
        return 0
    fi

    if ! git clone "https://aur.archlinux.org/yay.git" "$yay_dir"; then
        network_fail "installing yay"
        return 1
    fi

    if ! (
        cd "$yay_dir"
        makepkg -si --noconfirm
    ); then
        warn "yay installation returned a non-zero exit code. You can install it manually later."
        return 1
    fi

    return 0
}

install_group() {
    local group_name="$1"
    shift
    local pkgs=("$@")

    if (( ${#pkgs[@]} == 0 )); then
        return 0
    fi

    say "Installing ${group_name} group..."

    if (( DRY_RUN )); then
        printf 'DRY-RUN: pacman -S --needed --noconfirm %s\n' "${pkgs[*]}"
        return 0
    fi

    if [[ "$EUID" -eq 0 ]]; then
        pacman -S --needed --noconfirm "${pkgs[@]}" || warn "Some packages in the ${group_name} group could not be installed."
    else
        sudo pacman -S --needed --noconfirm "${pkgs[@]}" || warn "Some packages in the ${group_name} group could not be installed."
    fi
}

install_arch_aur_packages() {
    if (( SKIP_INSTALL )); then
        warn "Skipping Arch AUR packages because install is disabled."
        return 0
    fi

    if (( DRY_RUN )); then
        if ! command_exists yay; then
            printf 'DRY-RUN: clone and build yay from https://aur.archlinux.org/yay.git\n'
        fi
        printf 'DRY-RUN: yay -S --needed --noconfirm brave-bin wlogout\n'
        return 0
    fi

    if ! command_exists yay; then
        if ! install_yay; then
            warn "yay installation failed. Brave and wlogout were not installed automatically."
            return 0
        fi
    fi

    if command_exists yay; then
        local essentials=(brave-bin wlogout)
        local pkg
        for pkg in "${essentials[@]}"; do
            if ! pacman -Q "$pkg" >/dev/null 2>&1; then
                log "Installing $pkg with yay..."
                if (( DRY_RUN )); then
                    printf 'DRY-RUN: yay -S --needed --noconfirm %s\n' "$pkg"
                    continue
                fi

                if ! yay -S --needed --noconfirm "$pkg"; then
                    warn "Could not install $pkg via yay."
                fi
            else
                log "$pkg is already installed."
            fi
        done
    fi
}

ensure_hyprland_stack() {
    if command_exists hyprland; then
        log "Hyprland is already installed and available."
        return 0
    fi

    local hypr_packages=(
        hyprland xdg-desktop-portal-hyprland polkit
        waybar rofi dunst kitty wl-clipboard grim slurp cliphist
        brightnessctl playerctl thunar hyprlock
        qt5-wayland qt6-wayland
    )

    install_group "hyprland" "${hypr_packages[@]}"
}

install_packages() {
    local manager
    manager="$(detect_package_manager)"

    if [[ "$manager" != "pacman" ]]; then
        warn "This installer is Arch-specific. Skipping package installation because pacman was not found."
        return 0
    fi

    if [[ "$EUID" -ne 0 ]] && ! command_exists sudo; then
        warn "sudo is required to install packages, but it is not available. Skipping installation."
        return 0
    fi

    local pkgs=(
        base-devel git curl wget xdg-user-dirs
        networkmanager network-manager-applet bluez bluez-utils blueman
        pipewire pipewire-pulse wireplumber pavucontrol
        awww brightnessctl playerctl
        fontconfig noto-fonts noto-fonts-emoji ttf-jetbrains-mono-nerd
        libnotify matugen starship
    )

    log "Installing required Arch system packages..."

    if [[ "$EUID" -eq 0 ]]; then
        run_cmd pacman -S --needed --noconfirm "${pkgs[@]}"
    else
        run_cmd sudo pacman -S --needed --noconfirm "${pkgs[@]}"
    fi
}

check_optional_programs() {
    local optional=(brave code thunar nm-applet blueman-manager)
    local missing=()

    for app in "${optional[@]}"; do
        if ! command_exists "$app"; then
            missing+=("$app")
        fi
    done

    if (( ${#missing[@]} > 0 )); then
        warn "Optional apps not found: ${missing[*]}"
        warn "Install them manually if you want the full experience: brave, VS Code, Thunar, Network Manager applet, blueman"
    fi
}

check_required_fonts() {
    if ! command_exists fc-match; then
        warn "fc-match is not installed, so font validation was skipped."
        return 0
    fi

    if ! font_family_available "JetBrainsMono Nerd Font"; then
        warn "JetBrainsMono Nerd Font is not installed. Falling back to the default terminal font."
    fi

    if ! font_family_available "Noto Color Emoji"; then
        warn "Noto Color Emoji is not installed. Emoji rendering may look incomplete."
    fi
}

font_family_available() {
    local requested="$1"
    local matched
    matched="$(fc-match -f '%{family}\n' "$requested" 2>/dev/null || true)"
    [[ -n "$matched" && "${matched,,}" == *"${requested,,}"* ]]
}

ensure_runtime_tools() {
    local required=(git curl wget bash)

    for tool in "${required[@]}"; do
        if ! command_exists "$tool"; then
            warn "Missing required runtime tool: $tool"
        fi
    done
}

backup_existing() {
    local dest="$1"
    local base
    base="$(basename -- "$dest")"

    if [[ -e "$dest" || -L "$dest" ]]; then
        mkdir -p "$BACKUP_DIR"
        if (( FORCE || CONFIG_REPLACE )); then
            log "Backing up existing file: $dest -> $BACKUP_DIR/$base"
            run_cmd mv "$dest" "$BACKUP_DIR/$base"
        else
            warn "Skipping existing config: $dest (already present). Use --force to back it up."
            return 1
        fi
    fi

    return 0
}

select_config_action() {
    local rel
    local source
    local target
    local source_real
    local target_real
    local conflict_count=0

    for rel in "${CONFIG_ENTRIES[@]}"; do
        source="$DOTFILES_DIR/$rel"
        target="$CONFIG_DIR/$rel"
        [[ -e "$target" || -L "$target" ]] || continue

        source_real="$(readlink -f "$source" 2>/dev/null || printf '%s' "$source")"
        target_real="$(readlink -f "$target" 2>/dev/null || true)"
        if [[ ! -L "$target" || "$target_real" != "$source_real" ]]; then
            ((conflict_count += 1))
        fi
    done

    if (( conflict_count == 0 )); then
        return 0
    fi

    if (( FORCE )); then
        CONFIG_REPLACE=1
        return 0
    fi

    printf '\nFound %s existing config path(s) that are not linked to this checkout.\n' "$conflict_count"
    if ask_yes_no "Back them up under $BACKUP_DIR and link the dotfiles from this repo?"; then
        CONFIG_REPLACE=1
    fi
}

symlink_file() {
    local src="$1"
    local dst="$2"
    local src_real
    local dst_real

    mkdir -p "$(dirname -- "$dst")"
    if [[ -e "$dst" || -L "$dst" ]]; then
        src_real="$(readlink -f "$src" 2>/dev/null || printf '%s' "$src")"
        dst_real="$(readlink -f "$dst" 2>/dev/null || true)"
        if [[ -L "$dst" && "$dst_real" == "$src_real" ]]; then
            log "Already linked: $dst"
            return 0
        fi

        if (( FORCE || CONFIG_REPLACE )); then
            backup_existing "$dst" || return 0
        else
            warn "Skipping existing path: $dst"
            return 0
        fi
    fi

    log "Linking $src -> $dst"
    run_cmd ln -sfn "$src" "$dst"
}

install_dotfiles() {
    local rel

    mkdir -p "$CONFIG_DIR"

    for rel in "${CONFIG_ENTRIES[@]}"; do
        [[ "$rel" == "starship.toml" ]] && continue
        symlink_file "$DOTFILES_DIR/$rel" "$CONFIG_DIR/$rel"
    done

    symlink_file "$DOTFILES_DIR/starship.toml" "$CONFIG_DIR/starship.toml"

    if [[ -d "$CONFIG_DIR/matugen" ]]; then
        log "Matugen config already present at $CONFIG_DIR/matugen"
    fi
}

configure_starship_bash() {
    local bashrc="$HOME/.bashrc"
    local init_line='eval "$(starship init bash)"'

    if [[ -f "$bashrc" ]] && grep -Fq 'starship init bash' "$bashrc"; then
        log "Starship is already initialized in $bashrc"
        return 0
    fi

    if (( DRY_RUN )); then
        printf 'DRY-RUN: append Starship Bash initialization to %s\n' "$bashrc"
        return 0
    fi

    printf '\n# Initialize Starship prompt\n%s\n' "$init_line" >> "$bashrc"
    log "Added Starship initialization to $bashrc"
}

sync_theme() {
    if ! command_exists matugen; then
        warn "matugen is not installed, so the theme sync step was skipped."
        return 0
    fi

    if ! command_exists fc-match; then
        warn "fc-match is not installed, so font validation could not run. Theme sync will continue without font validation."
    fi

    if command_exists fc-match; then
        if ! font_family_available "JetBrainsMono Nerd Font"; then
            warn "JetBrainsMono Nerd Font is missing. Falling back to the default font and skipping theme sync."
            return 0
        fi
    fi

    local cfg="$HOME/.config/matugen/config.toml"
    local wallpaper=""

    if [[ -f "$HOME/.cache/color-wallpaper" ]]; then
        wallpaper="$(<"$HOME/.cache/color-wallpaper")"
    fi

    if [[ -z "$wallpaper" || ! -f "$wallpaper" ]]; then
        local wallpaper_dir="$HOME/Pictures/wallpaper"
        if [[ -d "$wallpaper_dir" ]]; then
            mapfile -t wallpapers < <(find "$wallpaper_dir" -maxdepth 1 -type f \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \) | head -n 10)
            if (( ${#wallpapers[@]} > 0 )); then
                wallpaper="${wallpapers[0]}"
            fi
        fi
    fi

    if [[ -z "$wallpaper" || ! -f "$wallpaper" ]]; then
        warn "No wallpaper was found for theme sync. Skipping Matugen sync."
        return 0
    fi

    say "Syncing your theme with Matugen..."
    if (( DRY_RUN )); then
        printf 'DRY-RUN: matugen -c %s --mode dark --type scheme-fidelity --source-color-index 0 --quiet image %s\n' "$cfg" "$wallpaper"
        return 0
    fi

    matugen -c "$cfg" --mode dark --type scheme-fidelity --source-color-index 0 --quiet image "$wallpaper" || warn "Matugen rendered a theme with warnings, but the install continued."
}

count_wallpapers() {
    local wallpaper_dir="$1"
    if [[ ! -d "$wallpaper_dir" ]]; then
        echo 0
        return 0
    fi

    find "$wallpaper_dir" -maxdepth 1 -type f \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \) 2>/dev/null | wc -l | tr -d ' '
}

clone_wallpaper_repo() {
    local repo_url="https://github.com/bat-fun/wallpaper.git"
    local dest_dir="$HOME/Pictures/wallpaper"
    local temp_dir
    local wallpaper_count

    wallpaper_count="$(count_wallpapers "$dest_dir")"

    if (( wallpaper_count > 0 )); then
        if ! ask_yes_no "A wallpaper collection already exists. Would you like to add the curated bat-fun wallpaper pack too?"; then
            return 0
        fi
    else
        if ! ask_yes_no "No wallpapers were detected. Would you like to clone the bat-fun wallpaper pack?"; then
            warn "No wallpaper pack added."
            return 0
        fi
    fi

    say "Fetching a wallpaper pack for your cinematic desktop..."
    mkdir -p "$HOME/Pictures"

    if (( DRY_RUN )); then
        printf 'DRY-RUN: git clone --depth 1 %s %s\n' "$repo_url" "$dest_dir"
        return 0
    fi

    if [[ -d "$dest_dir" && -n "$(find "$dest_dir" -mindepth 1 -maxdepth 1 2>/dev/null)" ]]; then
        log "Wallpaper directory already has files. Skipping clone."
        return 0
    fi

    temp_dir="$(mktemp -d)"
    if git clone --depth 1 "$repo_url" "$temp_dir"; then
        mkdir -p "$dest_dir"
        find "$temp_dir" -type f \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \) -exec cp -n {} "$dest_dir/" \;
        rm -rf "$temp_dir"
        log "Wallpaper pack added to $dest_dir"
    else
        network_fail "cloning the wallpaper pack"
        warn "The wallpaper step was skipped. Your desktop can still be configured without it."
    fi
}

ensure_user_dirs() {
    mkdir -p "$HOME/Pictures/wallpaper" "$HOME/Pictures/screenshots" "$HOME/.local/share/" "$HOME/.cache"
    log "Ensured user directories"
}

setup_permissions() {
    local script_path="$DOTFILES_DIR/install.sh"
    if [[ -f "$script_path" ]]; then
        chmod +x "$script_path"
    fi

    for script in "$DOTFILES_DIR"/hypr/scripts/*; do
        [[ -f "$script" ]] && chmod +x "$script"
    done
}

post_install_notes() {
    cat <<'POST'

Installation complete.

Recommended next steps:
  1. Re-log into your session or restart Hyprland.
  2. Check whether your package manager installed everything successfully.
  3. Launch: hyprland
  4. If some optional tools are missing, install them manually.

Useful commands:
  - hyprctl reload
  - waybar
  - rofi -show drun
  - kitty
  - starship preset nerd-font-symbols -o ~/.config/starship.toml
POST
}

parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --dry-run)
                DRY_RUN=1
                ;;
            --force)
                FORCE=1
                ;;
            --skip-install)
                SKIP_INSTALL=1
                ;;
            -h|--help)
                usage
                exit 0
                ;;
            *)
                fail "Unknown option: $1"
                ;;
        esac
        shift
    done
}

main() {
    parse_args "$@"
    check_arch_only

    if (( SKIP_INSTALL )); then
        warn "Package installation is disabled."
    else
        if ask_yes_no "Install the base desktop packages for this machine?"; then
            INSTALL_PACKAGES=1
        else
            INSTALL_PACKAGES=0
        fi

        if command -v hyprland >/dev/null 2>&1; then
            INSTALL_HYPRLAND=0
        elif ask_yes_no "Hyprland is not installed. Install the Hyprland desktop stack?"; then
            INSTALL_HYPRLAND=1
        else
            INSTALL_HYPRLAND=0
        fi

        if ask_yes_no "Install AUR extras for this setup (Brave + wlogout)?"; then
            INSTALL_AUR=1
        else
            INSTALL_AUR=0
        fi
    fi

    select_config_action
    show_preflight_summary
    log "Starting dotfiles install..."
    spin
    ensure_sudo
    ensure_runtime_tools

    if (( SKIP_INSTALL )); then
        warn "Skipping package installation as requested."
    else
        if (( INSTALL_PACKAGES )); then
            install_packages
        else
            warn "Base packages will be skipped."
        fi

        if (( INSTALL_HYPRLAND )); then
            ensure_hyprland_stack
        fi

        if (( INSTALL_AUR )); then
            install_arch_aur_packages
        fi
    fi

    check_optional_programs
    check_required_fonts
    ensure_user_dirs
    install_dotfiles
    configure_starship_bash
    sync_theme
    clone_wallpaper_repo
    setup_permissions
    post_install_notes
}

main "$@"
