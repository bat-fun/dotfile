#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="${HOME}/.config"
DOTFILES_DIR="$SCRIPT_DIR"
FORCE=0
FULL_RESET=0

usage() {
    cat <<'EOF_USAGE'
Usage: ./uninstall.sh [options]

Options:
  --force   Remove files without a confirmation prompt.
  --help    Show this help message.
EOF_USAGE
}

log() {
    printf '\n[%s] %s\n' "dotfiles-uninstall" "$*"
}

warn() {
    printf '\n[warn] %s\n' "$*" >&2
}

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

check_arch_only() {
    if ! command_exists pacman; then
        echo "This uninstall script is intended for Arch Linux and Arch-based distros only." >&2
        exit 1
    fi
}

confirm() {
    local prompt="$1"
    if [[ "${FORCE:-0}" -eq 1 ]]; then
        return 0
    fi
    local answer
    read -r -p "$prompt [y/N]: " answer || answer="n"
    [[ "${answer:-n}" =~ ^[Yy]$ ]]
}

ask_select_mode() {
    local choice
    while true; do
        printf '\nChoose uninstall mode:\n' >&2
        printf '  1) Normal uninstall (remove dotfile symlinks only)\n' >&2
        printf '  2) Full reset (remove symlinks + wallpapers + caches + backups)\n' >&2
        read -r -p "Select mode [1/2]: " choice || choice="1"

        case "$choice" in
            1)
                FULL_RESET=0
                return 0
                ;;
            2)
                FULL_RESET=1
                return 0
                ;;
            *)
                warn "Please choose 1 or 2."
                ;;
        esac
    done
}

show_uninstall_summary() {
    printf '\nUninstall plan:\n'
    printf '  - Remove linked dotfiles from ~/.config\n'
    if (( FULL_RESET )); then
        printf '  - Remove wallpapers, screenshots, cache files, and backup metadata\n'
        printf '  - This is a full wipe of the dotfiles setup\n'
    else
        printf '  - Keep wallpapers and cache unless you remove them manually\n'
        printf '  - This is a normal dotfile cleanup\n'
    fi
}

remove_symlink() {
    local target="$1"

    if [[ -L "$target" ]]; then
        log "Removing symlink: $target"
        rm -f "$target"
    elif [[ -e "$target" ]]; then
        warn "Path exists but is not a symlink: $target"
    fi
}

remove_linked_dirs() {
    local dirs=(
        "$CONFIG_DIR/dunst"
        "$CONFIG_DIR/gtk-3.0"
        "$CONFIG_DIR/hypr"
        "$CONFIG_DIR/kitty"
        "$CONFIG_DIR/matugen"
        "$CONFIG_DIR/rofi"
        "$CONFIG_DIR/waybar"
        "$CONFIG_DIR/wlogout"
        "$CONFIG_DIR/starship.toml"
    )

    for item in "${dirs[@]}"; do
        if [[ -L "$item" ]]; then
            remove_symlink "$item"
        fi
    done
}

restore_backups() {
    local backup_dirs=()
    local backup

    shopt -s nullglob
    backup_dirs=("$HOME"/.dotfiles-backup*)
    shopt -u nullglob

    for backup in "${backup_dirs[@]}"; do
        [[ -d "$backup" ]] || continue
        log "Found backup directory: $backup"
        find "$backup" -mindepth 1 -maxdepth 2 -print
    done
}

remove_optional_dirs() {
    if (( FULL_RESET )); then
        if [[ -d "$HOME/Pictures/wallpaper" ]] && confirm "Remove wallpaper directory at $HOME/Pictures/wallpaper?"; then
            rm -rf "$HOME/Pictures/wallpaper"
            log "Removed wallpaper directory."
        fi

        if [[ -d "$HOME/Pictures/screenshots" ]] && confirm "Remove screenshots directory at $HOME/Pictures/screenshots?"; then
            rm -rf "$HOME/Pictures/screenshots"
            log "Removed screenshots directory."
        fi
    else
        if [[ -d "$HOME/Pictures/wallpaper" ]]; then
            warn "Wallpaper directory was kept because this is a normal uninstall."
        fi
    fi
}

cleanup_backup_metadata() {
    local backup_dirs=()
    local backup

    if (( FULL_RESET )); then
        shopt -s nullglob
        backup_dirs=("$HOME"/.dotfiles-backup*)
        shopt -u nullglob

        for backup in "${backup_dirs[@]}"; do
            [[ -d "$backup" ]] || continue
            if confirm "Remove backup directory $backup?"; then
                rm -rf "$backup"
                log "Removed backup directory: $backup"
            fi
        done
    fi
}

cleanup_runtime_cache() {
    local cache_paths=(
        "$HOME/.cache/color-wallpaper"
        "$HOME/.cache/matugen"
    )

    for path in "${cache_paths[@]}"; do
        if [[ -e "$path" ]] && confirm "Remove cache path: $path?"; then
            rm -rf "$path"
            log "Removed $path"
        fi
    done
}

parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --force)
                FORCE=1
                ;;
            -h|--help)
                usage
                exit 0
                ;;
            *)
                warn "Unknown option: $1"
                usage
                exit 1
                ;;
        esac
        shift
    done
}

main() {
    parse_args "$@"
    check_arch_only

    log "Starting dotfiles uninstall..."
    ask_select_mode
    show_uninstall_summary

    if (( FULL_RESET )); then
        if ! confirm "Full reset is destructive. It will remove linked config, wallpapers, caches, and backups. Continue?"; then
            log "Full reset cancelled."
            exit 0
        fi
    else
        if ! confirm "This will remove the symlinks created by the dotfiles installer. Continue?"; then
            log "Uninstall cancelled."
            exit 0
        fi
    fi

    remove_linked_dirs
    restore_backups
    remove_optional_dirs
    cleanup_backup_metadata
    cleanup_runtime_cache

    log "Dotfiles uninstall complete."
    if (( FULL_RESET )); then
        log "Full reset finished. Your setup was wiped back to a clean baseline."
    else
        log "Normal uninstall finished. Your dotfile symlinks were removed."
    fi
}

main "$@"
