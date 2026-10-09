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
INSTALL_SDDM_THEME=0
SDDM_PACKAGE_MISSING=0
CONFIG_REPLACE=0
CONFIG_ENTRIES=(dunst gtk-3.0 hypr kitty matugen rofi waybar wlogout starship.toml)
SDDM_THEME_DIR="$DOTFILES_DIR/sddm/arc-noir"
SDDM_THEME_RESULT="not selected"
BASE_PACKAGES=(
    base-devel git curl wget xdg-user-dirs
    networkmanager network-manager-applet bluez bluez-utils blueman
    pipewire pipewire-pulse wireplumber pavucontrol
    awww brightnessctl playerctl
    procps-ng psmisc
    fontconfig noto-fonts noto-fonts-emoji ttf-jetbrains-mono-nerd
    libnotify matugen starship
)
HYPRLAND_PACKAGES=(
    hyprland xdg-desktop-portal-hyprland polkit
    waybar rofi dunst kitty wl-clipboard grim slurp cliphist
    brightnessctl playerctl thunar hyprlock code rofimoji
    qt5-wayland qt6-wayland
)
AUR_PACKAGES=(brave-bin wlogout)
BASE_MISSING=()
HYPRLAND_MISSING=()
AUR_MISSING=()
UNAVAILABLE_PACKAGES=()
BACKED_UP_TARGETS=()
CREATED_LINKS=()
MISSING_REQUIRED_COMMANDS=()
MISSING_OPTIONAL_COMMANDS=()
INSTALL_STARTED=0
ROLLBACK_IN_PROGRESS=0
THEME_RESULT="not run"
WALLPAPER_RESULT="not checked"
QUOTES=(
    'Linux|A well-kept dotfile is a note to your future self.'
    'Linux|Make the repeatable task a script, then make the script trustworthy.'
    'Linux|When a service fails, read its logs before changing the world.'
    'Linux|A quiet shell leaves room for clear thought.'
    'Linux|Small config changes can make a whole day smoother.'
    'Linux|The best shortcut is the one you still understand tomorrow.'
    'Linux|Keep your tools simple and your backups boring.'
    'Linux|Every process has a purpose; every config has a history.'
    'Linux|Let open tools open doors for everyone.'
    'Batman|A city changes when one person chooses not to look away.'
    'Batman|Preparation turns a dark night into a solvable problem.'
    'Batman|Hope can wear a symbol, but it is carried by people.'
    'Batman|Be precise with your power and gentle with the people around you.'
    'Batman|The night rewards patience, attention, and a steady plan.'
    'Batman|A quiet act of courage can outshine a skyline.'
    'Batman|Protect the small lights; they make the city worth saving.'
    'Batman|Fear shrinks when you know your next move.'
    'Batman|No mask can replace the choices you make.'
    'One Piece|A dream becomes a course when you take the first step.'
    'One Piece|A strong crew makes every rough crossing lighter.'
    'One Piece|The horizon is an invitation, not a boundary.'
    'One Piece|Share the map, share the meal, share the victory.'
    'One Piece|The sea is wide; leave room for every dream.'
    'One Piece|A detour can still carry you toward the right island.'
    'One Piece|Freedom feels bigger when your friends can sail beside you.'
    'One Piece|Keep laughing when the weather turns; the crew is still here.'
    'One Piece|A flag means most when its crew lives by it.'
)

rollback_configuration() {
    local target
    local saved

    ROLLBACK_IN_PROGRESS=1
    warn "Restoring dotfile targets from this install attempt..."
    for target in "${CREATED_LINKS[@]}"; do
        rm -f -- "$target" || warn "Could not remove partial link: $target"
    done
    for target in "${BACKED_UP_TARGETS[@]}"; do
        saved="$BACKUP_DIR/$(basename -- "$target")"
        if [[ -e "$saved" || -L "$saved" ]]; then
            rm -rf -- "$target" || warn "Could not clear partial target: $target"
            mkdir -p -- "$(dirname -- "$target")" || continue
            mv -- "$saved" "$target" || warn "Could not restore backup: $saved"
        fi
    done
    log "Configuration rollback finished."
}

on_error() {
    local exit_code=$?
    local failed_command="$BASH_COMMAND"

    trap - ERR
    fail "Installation failed (exit $exit_code): $failed_command (config phase=$INSTALL_STARTED, dry-run=$DRY_RUN)"

    if [[ "$INSTALL_STARTED" -eq 1 && "$DRY_RUN" -eq 0 && "$ROLLBACK_IN_PROGRESS" -eq 0 ]]; then
        rollback_configuration
    fi

    exit "$exit_code"
}
trap on_error ERR

say() {
    printf '\n✨ %s\n' "$*"
}

print_banner() {
    local cyan='' green='' dim='' reset=''
    local quote_entry="${QUOTES[$((RANDOM % ${#QUOTES[@]}))]}"
    local art_index=$((RANDOM % 3))
    local quote_source="${quote_entry%%|*}"
    local quote_text="${quote_entry#*|}"

    if [[ -t 1 ]]; then
        cyan=$'\033[38;5;44m'
        green=$'\033[38;5;114m'
        dim=$'\033[2m'
        reset=$'\033[0m'
    fi

    printf '\n%s' "$cyan"
    case "$art_index" in
        0)
            cat <<'ART'
        .------------------------------------------.
        |       DOTFILES :: ARCH DESKTOP           |
        |  [ HYPRLAND ] [ WAYBAR ] [ ROFI ]        |
        '------------------------------------------'
ART
            ;;
        1)
            cat <<'ART'
             ___________________________
            /  $ make yourself at home  \
           /_____________________________\
           |  kitty  |  hypr  |  rofi    |
           |_________|_______|___________|
ART
            ;;
        2)
            cat <<'ART'
        +-----------+       +-----------+
        | DOTFILES  | ----> | DESKTOP   |
        +-----------+       +-----------+
              \                 /
               \----[ HOME ]---/
ART
            ;;
    esac
    printf '%s\n%s"%s"%s\n' "$reset" "$dim" "$quote_text" "$reset"
    printf '%s- %s%s\n' "$green" "$quote_source" "$reset"
    printf '\n'
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
    local sddm_state="not selected"

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
    if (( INSTALL_SDDM_THEME )); then
        sddm_state="install Arc Noir theme; do not enable or switch display manager"
    fi

    if [[ -d "$HOME/Pictures/wallpaper" ]] && [[ -n "$(find "$HOME/Pictures/wallpaper" -maxdepth 1 -type f \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \) 2>/dev/null)" ]]; then
        wallpaper_state="existing wallpaper found"
    elif [[ -d "$HOME/Pictures/wallpaper" ]]; then
        wallpaper_state="folder exists, no images found"
    else
        wallpaper_state="no wallpaper detected"
    fi

    print_banner
    printf '+==========================================================+\n'
    printf '|                    ARCH PREFLIGHT                       |\n'
    printf '+==========================================================+\n'
    printf '  System          : Arch / Arch-based (pacman)\n'
    printf '  Base packages   : %s\n' "$base_state"
    printf '  Hyprland stack  : %s\n' "$hypr_state"
    printf '  AUR extras      : %s\n' "$aur_state"
    printf '  Configs         : %s\n' "$config_state"
    printf '  SDDM theme      : %s\n' "$sddm_state"
    printf '  Wallpapers      : %s\n' "$wallpaper_state"
    printf '  Optional apps   : Brave, VS Code, Thunar, nm-applet, blueman\n'
    printf '  Theme           : Matugen when available and a wallpaper exists\n'
    printf '  Fonts           : JetBrainsMono Nerd Font, Noto Color Emoji\n'

    if (( SKIP_INSTALL )); then
        printf '  Install mode    : packages skipped by request\n'
    else
        printf '  Install mode    : interactive; only missing packages selected\n'
    fi
    printf '+----------------------------------------------------------+\n\n'
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

collect_missing_packages() {
    local result_name="$1"
    shift
    local -n missing_ref="$result_name"
    local pkg

    missing_ref=()
    for pkg in "$@"; do
        if pacman -Q "$pkg" >/dev/null 2>&1; then
            continue
        fi
        if pacman -Si "$pkg" >/dev/null 2>&1; then
            missing_ref+=("$pkg")
        elif [[ " ${AUR_PACKAGES[*]} " == *" $pkg "* ]]; then
            missing_ref+=("$pkg")
        else
            UNAVAILABLE_PACKAGES+=("$pkg")
        fi
    done
}

audit_packages() {
    UNAVAILABLE_PACKAGES=()
    collect_missing_packages BASE_MISSING "${BASE_PACKAGES[@]}"
    collect_missing_packages HYPRLAND_MISSING "${HYPRLAND_PACKAGES[@]}"
    collect_missing_packages AUR_MISSING "${AUR_PACKAGES[@]}"

    say "Package audit"
    printf 'Missing base packages: %s\n' "${BASE_MISSING[*]:-none}"
    printf 'Missing Hyprland packages: %s\n' "${HYPRLAND_MISSING[*]:-none}"
    printf 'Missing AUR packages: %s\n' "${AUR_MISSING[*]:-none}"
    if (( ${#UNAVAILABLE_PACKAGES[@]} > 0 )); then
        warn "Not installed and unavailable in configured repositories: ${UNAVAILABLE_PACKAGES[*]}"
        warn "Refresh pacman databases or review these package names before continuing."
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

    if (( DRY_RUN )); then
        printf 'DRY-RUN: clone and build yay from https://aur.archlinux.org/yay.git\n'
        return 0
    fi

    local yay_dir
    yay_dir="$(mktemp -d)"
    if ! git clone "https://aur.archlinux.org/yay.git" "$yay_dir"; then
        network_fail "installing yay"
        rm -rf -- "$yay_dir"
        return 1
    fi

    if ! (
        cd "$yay_dir"
        makepkg -si --noconfirm
    ); then
        warn "yay installation returned a non-zero exit code. You can install it manually later."
        rm -rf -- "$yay_dir"
        return 1
    fi

    rm -rf -- "$yay_dir"
    return 0
}

install_group() {
    local group_name="$1"
    shift
    local pkgs=()
    local pkg

    for pkg in "$@"; do
        if ! pacman -Q "$pkg" >/dev/null 2>&1; then
            pkgs+=("$pkg")
        fi
    done

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


run_sddm_privileged() {
    if [[ "$EUID" -eq 0 ]]; then
        "$@"
    else
        sudo "$@"
    fi
}
    if (( DRY_RUN )); then
        if ! command_exists yay; then
            printf 'DRY-RUN: clone and build yay from https://aur.archlinux.org/yay.git\n'
        fi
        if (( ${#AUR_MISSING[@]} > 0 )); then
            printf 'DRY-RUN: yay -S --needed --noconfirm %s\n' "${AUR_MISSING[*]}"
        fi
        return 0
    fi

    if ! command_exists yay; then
        if ! install_yay; then
            warn "yay installation failed. Missing AUR packages were not installed automatically."
            return 0
        fi
    fi

    if command_exists yay && (( ${#AUR_MISSING[@]} > 0 )); then
        log "Installing missing AUR packages..."
        if ! yay -S --needed --noconfirm "${AUR_MISSING[@]}"; then
            warn "Some AUR packages could not be installed."
        fi
    fi
}

ensure_hyprland_stack() {
    install_group "Hyprland desktop" "${HYPRLAND_MISSING[@]}"
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

    log "Installing required Arch system packages..."
    install_group "base" "${BASE_MISSING[@]}"
}

audit_runtime_commands() {
    local required=(hyprland hyprlock waybar rofi kitty dunst thunar code matugen starship awww awww-daemon hyprctl wl-copy wl-paste cliphist grim slurp playerctl wpctl notify-send nm-applet blueman-manager brightnessctl rofimoji)
    local optional=(brave wlogout)
    local command

    MISSING_REQUIRED_COMMANDS=()
    MISSING_OPTIONAL_COMMANDS=()
    for command in "${required[@]}"; do
        command_exists "$command" || MISSING_REQUIRED_COMMANDS+=("$command")
    done
    for command in "${optional[@]}"; do
        command_exists "$command" || MISSING_OPTIONAL_COMMANDS+=("$command")
    done

    say "Runtime command audit"
    if (( ${#MISSING_REQUIRED_COMMANDS[@]} > 0 )); then
        warn "Configured commands still missing: ${MISSING_REQUIRED_COMMANDS[*]}"
    else
        log "All core configured commands are available."
    fi
    if (( ${#MISSING_OPTIONAL_COMMANDS[@]} > 0 )); then
        warn "Optional commands missing (their bindings/features will not work): ${MISSING_OPTIONAL_COMMANDS[*]}"
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
        if (( FORCE || CONFIG_REPLACE )); then
            log "Backing up existing file: $dest -> $BACKUP_DIR/$base"
            if (( DRY_RUN )); then
                run_cmd mv "$dest" "$BACKUP_DIR/$base"
            else
                mkdir -p -- "$BACKUP_DIR"
                if ! mv -- "$dest" "$BACKUP_DIR/$base"; then
                    warn "Could not back up existing config: $dest"
                    return 1
                fi
                BACKED_UP_TARGETS+=("$dest")
            fi
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

    if (( DRY_RUN == 0 )); then
        if ! mkdir -p -- "$(dirname -- "$dst")"; then
            warn "Could not create config parent for: $dst"
            return 1
        fi
    fi
    if [[ -e "$dst" || -L "$dst" ]]; then
        src_real="$(readlink -f "$src" 2>/dev/null || printf '%s' "$src")"
        dst_real="$(readlink -f "$dst" 2>/dev/null || true)"
        if [[ -L "$dst" && "$dst_real" == "$src_real" ]]; then
            log "Already linked: $dst"
            return 0
        fi

        if (( FORCE || CONFIG_REPLACE )); then
            if ! backup_existing "$dst"; then
                return 1
            fi
        else
            warn "Skipping existing path: $dst"
            return 0
        fi
    fi

    log "Linking $src -> $dst"
    if ! run_cmd ln -sfn "$src" "$dst"; then
        return 1
    fi
    if (( DRY_RUN == 0 )); then
        CREATED_LINKS+=("$dst")
    fi
}

install_dotfiles() {
    local rel

    INSTALL_STARTED=1
    if (( DRY_RUN == 0 )); then
        if ! mkdir -p -- "$CONFIG_DIR"; then
            warn "Could not create config directory: $CONFIG_DIR"
            rollback_configuration
            return 1
        fi
    fi

    for rel in "${CONFIG_ENTRIES[@]}"; do
        [[ "$rel" == "starship.toml" ]] && continue
        if ! symlink_file "$DOTFILES_DIR/$rel" "$CONFIG_DIR/$rel"; then
            rollback_configuration
            warn "Config link failed; installation stopped before proceeding."
            return 1
        fi
    done

    if ! symlink_file "$DOTFILES_DIR/starship.toml" "$CONFIG_DIR/starship.toml"; then
        rollback_configuration
        warn "Starship config link failed; installation stopped before proceeding."
        return 1
    fi

    if [[ -d "$CONFIG_DIR/matugen" ]]; then
        log "Matugen config already present at $CONFIG_DIR/matugen"
    fi
}

configure_starship_bash() {
    local bashrc="$HOME/.bashrc"
    local init_line='eval "$(starship init bash)"'

    if ! command_exists starship; then
        if (( DRY_RUN )); then
            printf 'DRY-RUN: Starship is missing; no Bash initialization will be added.\n'
        else
            warn "Starship is not installed; leaving $bashrc unchanged."
        fi
        return 0
    fi

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
        THEME_RESULT="skipped: Matugen is not installed"
        warn "matugen is not installed, so the theme sync step was skipped."
        return 0
    fi

    local font_validation="available"
    if ! command_exists fc-match; then
        font_validation="unavailable"
        warn "fc-match is not installed, so font validation could not run. Theme sync will continue without font validation."
    fi

    if command_exists fc-match; then
        if ! font_family_available "JetBrainsMono Nerd Font"; then
            THEME_RESULT="skipped: JetBrainsMono Nerd Font is missing"
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
        THEME_RESULT="skipped: no wallpaper found"
        warn "No wallpaper was found for theme sync. Skipping Matugen sync."
        return 0
    fi

    say "Syncing your theme with Matugen..."
    if (( DRY_RUN )); then
        THEME_RESULT="preview: Matugen sync would run"
        printf 'DRY-RUN: matugen -c %s --mode dark --type scheme-fidelity --source-color-index 0 --quiet image %s\n' "$cfg" "$wallpaper"
        return 0
    fi

    if matugen -c "$cfg" --mode dark --type scheme-fidelity --source-color-index 0 --quiet image "$wallpaper"; then
        THEME_RESULT="generated from $(basename -- "$wallpaper")"
    else
        THEME_RESULT="failed: Matugen returned an error"
        warn "Matugen rendered a theme with warnings, but the install continued."
    fi
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
            WALLPAPER_RESULT="kept existing collection ($wallpaper_count images)"
            return 0
        fi
    else
        if ! ask_yes_no "No wallpapers were detected. Would you like to clone the bat-fun wallpaper pack?"; then
            WALLPAPER_RESULT="no wallpaper pack added"
            warn "No wallpaper pack added."
            return 0
        fi
    fi

    say "Fetching a wallpaper pack for your cinematic desktop..."
    if (( DRY_RUN )); then
        WALLPAPER_RESULT="clone previewed; no files downloaded"
        printf 'DRY-RUN: git clone --depth 1 %s %s\n' "$repo_url" "$dest_dir"
        return 0
    fi

    mkdir -p -- "$HOME/Pictures"

    if [[ -d "$dest_dir" && -n "$(find "$dest_dir" -mindepth 1 -maxdepth 1 2>/dev/null)" ]]; then
        WALLPAPER_RESULT="clone skipped because the folder already contains files"
        log "Wallpaper directory already has files. Skipping clone."
        return 0
    fi

    temp_dir="$(mktemp -d)"
    if git clone --depth 1 "$repo_url" "$temp_dir"; then
        mkdir -p "$dest_dir"
        find "$temp_dir" -type f \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \) -exec cp -n {} "$dest_dir/" \;
        rm -rf "$temp_dir"
        WALLPAPER_RESULT="wallpaper pack added ($(count_wallpapers "$dest_dir") images)"
        log "Wallpaper pack added to $dest_dir"
    else
        WALLPAPER_RESULT="download failed; install continued without the pack"
        network_fail "cloning the wallpaper pack"
        warn "The wallpaper step was skipped. Your desktop can still be configured without it."
    fi
}

ensure_user_dirs() {
    if (( DRY_RUN )); then
        log "DRY-RUN: create wallpaper, screenshot, share, and cache directories"
        return 0
    fi
    mkdir -p "$HOME/Pictures/wallpaper" "$HOME/Pictures/screenshots" "$HOME/.local/share/" "$HOME/.cache"
    log "Ensured user directories"
}

setup_permissions() {
    local script_path="$DOTFILES_DIR/install.sh"

    if (( DRY_RUN )); then
        log "DRY-RUN: set installer and Hyprland helper scripts executable"
        return 0
    fi

    if [[ -f "$script_path" ]]; then
        chmod +x "$script_path"
    fi

    for script in "$DOTFILES_DIR"/hypr/scripts/*; do
        [[ -f "$script" ]] && chmod +x "$script"
    done
}

print_package_result() {
    local label="$1"
    local missing_name="$2"
    local selected="$3"
    local -n missing_ref="$missing_name"
    local state

    if (( SKIP_INSTALL )); then
        state="skipped by --skip-install"
    elif (( ${#missing_ref[@]} == 0 )); then
        state="already installed"
    elif (( selected )); then
        if (( DRY_RUN )); then
            state="previewed: would install ${missing_ref[*]}"
        else
            state="installation requested: ${missing_ref[*]}"
        fi
    else
        state="skipped by choice; missing ${missing_ref[*]}"
    fi

    printf '  %-14s %s\n' "$label" "$state"
}

post_install_notes() {
    local linked_count=0
    local preserved_count=0
    local rel
    local source_real
    local target_real
    local completion_title
    local sddm_needs_review=0
    local closing_entry
    local closing_source
    local closing_quote

    if (( DRY_RUN == 0 )); then
        for rel in "${CONFIG_ENTRIES[@]}"; do
            source_real="$(readlink -f "$DOTFILES_DIR/$rel" 2>/dev/null || printf '%s' "$DOTFILES_DIR/$rel")"
            target_real="$(readlink -f "$CONFIG_DIR/$rel" 2>/dev/null || true)"
            if [[ -L "$CONFIG_DIR/$rel" && "$target_real" == "$source_real" ]]; then
                ((linked_count += 1))
            elif [[ -e "$CONFIG_DIR/$rel" || -L "$CONFIG_DIR/$rel" ]]; then
                ((preserved_count += 1))
            fi
        done
    fi

    if (( INSTALL_SDDM_THEME )) && [[ "$SDDM_THEME_RESULT" == failed:* || "$SDDM_THEME_RESULT" == skipped:* ]]; then
        sddm_needs_review=1
    fi

    if (( DRY_RUN )); then
        completion_title="DRY RUN - PREVIEW COMPLETE"
        printf '\nDRY-RUN SUMMARY\n'
        printf '  No system changes were made; actions were previewed only.\n'
    elif (( ${#MISSING_REQUIRED_COMMANDS[@]} > 0 || ${#MISSING_OPTIONAL_COMMANDS[@]} > 0 || linked_count != ${#CONFIG_ENTRIES[@]} || sddm_needs_review )); then
        completion_title="SETUP DONE - REVIEW NOTES"
        printf '\nINSTALL SUMMARY - REVIEW NOTES\n'
    else
        completion_title="HAPPY HACKING - ALL SET"
        printf '\nINSTALL SUMMARY\n'
    fi

    printf '\nPackage groups:\n'
    print_package_result "Base" BASE_MISSING "$INSTALL_PACKAGES"
    print_package_result "Hyprland" HYPRLAND_MISSING "$INSTALL_HYPRLAND"
    print_package_result "AUR" AUR_MISSING "$INSTALL_AUR"

    printf '\nConfiguration:\n'
    if (( DRY_RUN )); then
        printf '  %s targets reviewed; links were previewed only.\n' "${#CONFIG_ENTRIES[@]}"
    else
        printf '  Linked to this checkout: %s of %s\n' "$linked_count" "${#CONFIG_ENTRIES[@]}"
        if (( preserved_count > 0 )); then
            printf '  Existing configs preserved: %s\n' "$preserved_count"
        fi
    fi

    if [[ -d "$BACKUP_DIR" ]]; then
        printf '  Backup: %s\n' "$BACKUP_DIR"
    elif (( CONFIG_REPLACE )); then
        printf '  Backup: no existing config needed backing up\n'
    fi

    printf '\nTheme: %s\n' "$THEME_RESULT"
    printf 'SDDM theme: %s\n' "$SDDM_THEME_RESULT"
    printf 'Wallpapers: %s\n' "$WALLPAPER_RESULT"
    if (( DRY_RUN )); then
        printf 'Starship Bash init: previewed only\n'
    elif [[ -f "$HOME/.bashrc" ]] && grep -Fq 'starship init bash' "$HOME/.bashrc"; then
        printf 'Starship Bash init: present in ~/.bashrc\n'
    else
        printf 'Starship Bash init: not present in ~/.bashrc\n'
    fi

    if (( ${#MISSING_REQUIRED_COMMANDS[@]} > 0 )); then
        printf '\nCommands still missing: %s\n' "${MISSING_REQUIRED_COMMANDS[*]}"
    else
        printf '\nAll core configured commands are available.\n'
    fi
    if (( ${#MISSING_OPTIONAL_COMMANDS[@]} > 0 )); then
        printf 'Optional commands still missing: %s\n' "${MISSING_OPTIONAL_COMMANDS[*]}"
    fi

    printf '\nNext: review any missing commands above, then start or reload Hyprland.\n'
    printf 'Useful: hyprctl reload  |  waybar  |  rofi -show drun  |  kitty\n'
    printf '\nMay your setup feel like home, your system stay steady, and your next idea find its way.\n\n'
    printf '        +--------------------------------------+\n'
    printf '        |  %-36s|\n' "$completion_title"
    printf '        |  %-36s|\n' "one good change at a time"
    printf '        +--------------------------------------+\n'
    closing_entry="${QUOTES[$((RANDOM % ${#QUOTES[@]}))]}"
    closing_source="${closing_entry%%|*}"
    closing_quote="${closing_entry#*|}"
    printf '\n"%s"\n  - %s\n' "$closing_quote" "$closing_source"
}

schedule_first_login_welcome() {
    local bashrc="$HOME/.bashrc"
    local state_dir="$HOME/.local/state/dotfile"
    local marker="$state_dir/welcome-once"

    if [[ -f "$bashrc" ]] && grep -Fq '# Dotfile install first-login welcome' "$bashrc"; then
        :
    else
        if ! cat >> "$bashrc" <<'WELCOME_HOOK'

# Dotfile install first-login welcome
if [[ $- == *i* && -f "$HOME/.local/state/dotfile/welcome-once" ]]; then
    cat <<'WELCOME_NOTE'

  Welcome home. Your new desktop is ready when you are.

      .--------------------------------------.
      |  HYPRLAND IS YOURS - MAKE IT HOME    |
      '--------------------------------------'

  SUPER + Return  open Kitty
  SUPER + D       choose a wallpaper
  SUPER + V       open clipboard history
  SUPER + L       lock the screen

    "A quiet shell leaves room for clear thought."
        - Linux

  Take it one keybind, one good idea, one day at a time.
WELCOME_NOTE
    rm -f -- "$HOME/.local/state/dotfile/welcome-once"
fi
WELCOME_HOOK
        then
            warn "Could not add the first-login welcome to $bashrc."
            return 1
        fi
    fi

    if ! mkdir -p -- "$state_dir" || ! : > "$marker"; then
        warn "Could not schedule the first-login welcome."
        return 1
    fi

    return 0
}

offer_reboot() {
    if (( DRY_RUN )); then
        log "Dry-run: no reboot prompt or system restart."
        return 0
    fi

    if ! ask_yes_no "Installation finished. Reboot now and show a welcome on your next interactive Bash session?"; then
        log "Reboot skipped. Reboot later with: sudo systemctl reboot"
        return 0
    fi

    if ! command_exists systemctl || ! command_exists sudo; then
        warn "systemctl or sudo is unavailable; reboot manually when ready."
        return 0
    fi

    if ! schedule_first_login_welcome; then
        warn "Reboot was not started because the welcome could not be scheduled."
        return 0
    fi

    log "Welcome scheduled for the next interactive Bash session. Rebooting now..."
    if ! sudo systemctl reboot; then
        warn "The reboot command failed. Reboot manually with 'sudo systemctl reboot'; the welcome will show at the next interactive Bash session."
    fi
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
    audit_packages

    if (( SKIP_INSTALL )); then
        warn "Package installation is disabled."
    else
        if (( ${#BASE_MISSING[@]} > 0 )) && ask_yes_no "Install the missing base desktop packages?"; then
            INSTALL_PACKAGES=1
        else
            INSTALL_PACKAGES=0
        fi

        if (( ${#HYPRLAND_MISSING[@]} == 0 )); then
            INSTALL_HYPRLAND=0
        elif ask_yes_no "Install the missing Hyprland desktop and configured app packages?"; then
            INSTALL_HYPRLAND=1
        else
            INSTALL_HYPRLAND=0
        fi

        if (( ${#AUR_MISSING[@]} > 0 )) && ask_yes_no "Install missing AUR extras (${AUR_MISSING[*]})?"; then
            INSTALL_AUR=1
        else
            INSTALL_AUR=0
        fi
    fi

    if [[ -d "$SDDM_THEME_DIR" ]]; then
        if pacman -Q sddm >/dev/null 2>&1; then
            SDDM_PACKAGE_MISSING=0
            if ask_yes_no "Install and select the Arc Noir SDDM theme? This will not enable or switch display managers."; then
                INSTALL_SDDM_THEME=1
            fi
        else
            SDDM_PACKAGE_MISSING=1
            if ask_yes_no "Install SDDM if needed and select the Arc Noir theme? This will not enable or switch display managers."; then
                INSTALL_SDDM_THEME=1
            fi
        fi
    else
        SDDM_THEME_RESULT="unavailable: repository theme folder is missing"
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


install_sddm_theme() {
    local theme_target="/usr/share/sddm/themes/arc-noir"
    local config_target="/etc/sddm.conf.d/10-arc-noir.conf"
    local stage_target="/usr/share/sddm/themes/.arc-noir-stage-$BASHPID"
    local config_stage="/etc/sddm.conf.d/.10-arc-noir.conf-$BASHPID"
    local backup_dir="$BACKUP_DIR/sddm-arc-noir-$BASHPID"
    local had_theme=0
    local had_config=0
    local required

    if (( !INSTALL_SDDM_THEME )); then
        SDDM_THEME_RESULT="not selected"
        return 0
    fi

    for required in metadata.desktop MainCenter.qml theme.conf black_bat.jpg; do
        if [[ ! -f "$SDDM_THEME_DIR/$required" ]]; then
            SDDM_THEME_RESULT="failed: missing $required in repository theme"
            warn "SDDM theme is incomplete: $SDDM_THEME_DIR/$required is missing."
            return 0
        fi
    done

    if (( DRY_RUN )); then
        if (( SDDM_PACKAGE_MISSING )); then
            printf 'DRY-RUN: pacman -S --needed --noconfirm sddm\n'
        fi
        printf 'DRY-RUN: install %s -> %s\n' "$SDDM_THEME_DIR" "$theme_target"
        printf 'DRY-RUN: write %s with Current=arc-noir\n' "$config_target"
        SDDM_THEME_RESULT="previewed: install theme and select it; display manager unchanged"
        return 0
    fi

    if [[ "$EUID" -ne 0 ]] && ! command_exists sudo; then
        SDDM_THEME_RESULT="skipped: sudo is unavailable"
        warn "sudo is required to install a system SDDM theme."
        return 0
    fi

    if (( SDDM_PACKAGE_MISSING )); then
        if (( SKIP_INSTALL )); then
            SDDM_THEME_RESULT="skipped: SDDM package missing while package installation is disabled"
            warn "SDDM is not installed and package installation was skipped; theme not installed."
            return 0
        fi
        install_group "SDDM" sddm
        if ! pacman -Q sddm >/dev/null 2>&1; then
            SDDM_THEME_RESULT="skipped: SDDM package installation failed"
            warn "SDDM is not installed; the theme files were not installed."
            return 0
        fi
    fi

    mkdir -p -- "$backup_dir"

    if [[ -e "$theme_target" || -L "$theme_target" ]]; then
        if ! run_sddm_privileged cp -a -- "$theme_target" "$backup_dir/arc-noir"; then
            SDDM_THEME_RESULT="failed: existing theme backup failed"
            warn "Could not back up existing SDDM theme; leaving it untouched."
            return 0
        fi
        had_theme=1
    fi
    if [[ -e "$config_target" || -L "$config_target" ]]; then
        if ! run_sddm_privileged cp -a -- "$config_target" "$backup_dir/10-arc-noir.conf"; then
            SDDM_THEME_RESULT="failed: SDDM config backup failed"
            warn "Could not back up existing SDDM theme selection."
            return 0
        fi
        had_config=1
    fi

    if ! run_sddm_privileged install -d -m 755 /usr/share/sddm/themes /etc/sddm.conf.d; then
        SDDM_THEME_RESULT="failed: could not create SDDM directories"
        warn "Could not create system SDDM directories."
        return 0
    fi

    if ! run_sddm_privileged cp -a -- "$SDDM_THEME_DIR" "$stage_target"; then
        SDDM_THEME_RESULT="failed: theme staging failed"
        warn "Could not stage the Arc Noir theme under /usr/share/sddm/themes."
        return 0
    fi
    if ! run_sddm_privileged chown -R root:root "$stage_target" ||
        ! run_sddm_privileged find "$stage_target" -type d -exec chmod 755 {} + ||
        ! run_sddm_privileged find "$stage_target" -type f -exec chmod 644 {} + ||
        ! printf 'dotfile:arc-noir\n' | run_sddm_privileged tee "$stage_target/.dotfile-managed" >/dev/null; then
        run_sddm_privileged rm -rf -- "$stage_target" || true
        SDDM_THEME_RESULT="failed: staged theme permissions could not be set"
        warn "Could not set safe permissions on the staged SDDM theme."
        return 0
    fi

    if ! printf '# Managed by the dotfile installer: Arc Noir\n[Theme]\nCurrent=arc-noir\n' | run_sddm_privileged tee "$config_stage" >/dev/null; then
        run_sddm_privileged rm -rf -- "$stage_target" || true
        SDDM_THEME_RESULT="failed: could not stage SDDM selection"
        warn "Could not stage the SDDM theme-selection config."
        return 0
    fi

    if [[ -e "$theme_target" || -L "$theme_target" ]]; then
        if ! run_sddm_privileged rm -rf -- "$theme_target"; then
            run_sddm_privileged rm -rf -- "$stage_target" "$config_stage" || true
            SDDM_THEME_RESULT="failed: could not replace existing theme"
            warn "Could not replace the existing Arc Noir system theme."
            return 0
        fi
    fi
    if ! run_sddm_privileged mv -- "$stage_target" "$theme_target"; then
        if (( had_theme )); then
            run_sddm_privileged cp -a -- "$backup_dir/arc-noir" "$theme_target" || warn "Could not restore previous SDDM theme."
        fi
        run_sddm_privileged rm -f -- "$config_stage" || true
        SDDM_THEME_RESULT="failed: could not install staged theme"
        warn "Could not install the staged Arc Noir theme."
        return 0
    fi

    if [[ -e "$config_target" || -L "$config_target" ]]; then
        if ! run_sddm_privileged rm -f -- "$config_target"; then
            run_sddm_privileged rm -rf -- "$theme_target" || true
            if (( had_theme )); then
                run_sddm_privileged cp -a -- "$backup_dir/arc-noir" "$theme_target" || warn "Could not restore previous SDDM theme."
            fi
            run_sddm_privileged rm -f -- "$config_stage" || true
            SDDM_THEME_RESULT="failed: could not replace SDDM config"
            warn "Could not replace the Arc Noir SDDM selection."
            return 0
        fi
    fi
    if ! run_sddm_privileged mv -- "$config_stage" "$config_target"; then
        run_sddm_privileged rm -rf -- "$theme_target" || true
        if (( had_theme )); then
            run_sddm_privileged cp -a -- "$backup_dir/arc-noir" "$theme_target" || warn "Could not restore previous SDDM theme."
        fi
        if (( had_config )); then
            run_sddm_privileged cp -a -- "$backup_dir/10-arc-noir.conf" "$config_target" || warn "Could not restore previous SDDM config."
        fi
        SDDM_THEME_RESULT="failed: could not activate theme selection"
        warn "Could not activate the Arc Noir SDDM theme selection."
        return 0
    fi

    if (( had_theme || had_config )); then
        run_sddm_privileged chown -R "$(id -u):$(id -g)" "$backup_dir" || warn "Could not change ownership of SDDM backups."
        SDDM_THEME_RESULT="installed and selected; previous files backed up at $backup_dir"
    else
        rmdir -- "$backup_dir" 2>/dev/null || true
        SDDM_THEME_RESULT="installed and selected; display manager was not enabled or changed"
    fi

    log "Arc Noir SDDM theme installed. The active display manager was not enabled or switched."
}
    install_sddm_theme
    audit_runtime_commands
    check_required_fonts
    ensure_user_dirs
    install_dotfiles
    sync_theme
    clone_wallpaper_repo
    setup_permissions
    INSTALL_STARTED=0
    configure_starship_bash
    post_install_notes
    offer_reboot
}

main "$@"
