# ✦ A little more at home

> A personal Arch desktop built around Hyprland, warm terminal sessions, and small shortcuts that make the day flow.

```text
╭─────────────────────────────────────────────────────────╮
│  HYPRLAND  ·  KITTY  ·  WAYBAR  ·  ROFI  ·  MATUGEN   │
│  tidy configs, deliberate keybinds, wallpaper-made color │
╰─────────────────────────────────────────────────────────╯
```

This repository is my daily-driver setup: a Lua-based Hyprland configuration, a compact app palette, Waybar, Rofi, Dunst, Kitty, Matugen themes, and a handful of desktop scripts. It is opinionated and tuned for my workflow, but the install stays cautious with existing config files.

## Install

For Arch Linux and Arch-based distributions, run this one line as your regular user:

```bash
git clone https://github.com/bat-fun/dotfile.git && cd dotfile && ./install.sh
```

The installer is interactive. It checks for `pacman`, audits installed packages, and offers only missing base, Hyprland desktop, and AUR packages. It asks before backing up existing config paths and linking this checkout. Backups go to a timestamped `~/.dotfiles-backup-*` directory. It also audits configured runtime commands, can offer a wallpaper collection when none is found, and uses Matugen to generate colors when Matugen and a usable wallpaper are available. The Arc Noir SDDM theme is an optional system-wide install; the installer copies it into SDDM's theme directory and selects it in a dedicated config drop-in, but does not enable or switch display managers.

After setup, the installer asks whether to reboot now. If you agree, it schedules a one-time ASCII welcome, a short Linux quote, and useful keybinding hints for the next interactive Bash session, then requests a reboot through `sudo systemctl reboot`. Declining leaves the system running; reboot later with `sudo systemctl reboot` when convenient.

Run with `./install.sh --help` to see the optional dry-run and package-skip switches. Dry-run previews the changes without writing to your home directory or changing script permissions. Run the installer from a normal user account with `sudo` available; do not launch it as root because yay builds must run as a regular user.

## What’s Inside

| Path             | What it does                                      |
| ---------------- | ------------------------------------------------- |
| `hypr/`          | Hyprland Lua config, modules, and desktop scripts |
| `waybar/`        | Bar layout and styling                            |
| `rofi/`          | Application launcher and wallpaper picker themes  |
| `kitty/`         | Terminal configuration                            |
| `dunst/`         | Desktop notifications                             |
| `matugen/`       | Color templates and generated theme files         |
| `wlogout/`       | Logout menu layout and styling                    |
| `gtk-3.0/`       | GTK 3 appearance settings                         |
| `sddm/arc-noir/` | Arc Noir SDDM greeter theme and bundled artwork   |
| `starship.toml`  | Starship prompt configuration                     |
| `install.sh`     | Interactive Arch / Arch-based installer           |
| `uninstall.sh`   | Interactive normal uninstall or full reset        |

The package choices include common networking, Bluetooth, audio, and font packages, plus configured Hyprland desktop utilities, Code - OSS, and rofimoji. Brave and wlogout are offered as AUR extras. If you decline a package group, the runtime audit reports commands that remain unavailable.

## Keybindings

`SUPER` means the Super/Windows key. These are the active bindings in `hypr/module/binds.lua`.

### Apps & Desktop

| Keys             | Action                                                  |
| ---------------- | ------------------------------------------------------- |
| `SUPER + Return` | Open Kitty                                              |
| `SUPER + E`      | Open Thunar                                             |
| `SUPER + A`      | Open the Rofi app launcher                              |
| `SUPER + B`      | Open Brave                                              |
| `SUPER + C`      | Open VS Code                                            |
| `SUPER + G`      | Open Google search helper                               |
| `SUPER + .`      | Open emoji picker                                       |
| `SUPER + D`      | Open wallpaper picker                                   |
| `SUPER + R`      | Apply a random wallpaper                                |
| `SUPER + W`      | Restart Waybar                                          |
| `SUPER + L`      | Lock the screen                                         |
| `SUPER + X`      | Open the wlogout menu                                   |
| `SUPER + M`      | Shut down Hyprland, using `hyprshutdown` when available |

### Windows & Workspaces

| Keys                             | Action                                             |
| -------------------------------- | -------------------------------------------------- |
| `SUPER + Q`                      | Close the active window                            |
| `SUPER + Space`                  | Toggle floating mode                               |
| `SUPER + P`                      | Toggle pseudo tiling                               |
| `SUPER + J`                      | Toggle split direction                             |
| `SUPER + F`                      | Toggle fullscreen                                  |
| `SUPER + Arrow keys`             | Focus a window in that direction                   |
| `SUPER + 1` ... `9`, `0`         | Switch to workspaces 1 ... 9, 10                   |
| `SUPER + SHIFT + 1` ... `9`, `0` | Move the active window to workspaces 1 ... 9, 10   |
| `SUPER + S`                      | Toggle the centered scratchpad terminal            |
| `SUPER + SHIFT + S`              | Send the active window to the scratchpad workspace |
| `SUPER + Mouse wheel`            | Move between workspaces                            |
| `SUPER + Left mouse drag`        | Move a window                                      |
| `SUPER + Right mouse drag`       | Resize a window                                    |

### Capture & Clipboard

| Keys                | Action                                         |
| ------------------- | ---------------------------------------------- |
| `Print`             | Capture a selected screen region               |
| `SHIFT + Print`     | Capture the full screen                        |
| `SUPER + V`         | Open clipboard history                         |
| `SUPER + SHIFT + V` | Clear clipboard history and clipboard contents |

### Media & Hardware

| Keys                                            | Action                   |
| ----------------------------------------------- | ------------------------ |
| `XF86AudioRaiseVolume` / `XF86AudioLowerVolume` | Adjust output volume     |
| `XF86AudioMute`                                 | Toggle output mute       |
| `XF86AudioMicMute`                              | Toggle microphone mute   |
| `XF86MonBrightnessUp` / `XF86MonBrightnessDown` | Adjust screen brightness |
| `XF86AudioNext` / `XF86AudioPrev`               | Skip media track         |
| `XF86AudioPlay` / `XF86AudioPause`              | Toggle media playback    |

Hardware keys depend on keyboard and device support. Media shortcuts use PipeWire/WirePlumber and Playerctl; brightness shortcuts use Brightnessctl.

## Personalizing

- Change app commands in `hypr/module/programs.lua`; bindings consume that table.
- Edit bindings in `hypr/module/binds.lua`.
- Adjust compositor appearance and autostart in `hypr/hyprland.lua` and animations in `hypr/module/animation.lua`.
- Pick a wallpaper with `SUPER + D`; Matugen can then generate matching colors for the supported apps.
- If Starship is installed, its initialization is added to `~/.bashrc` when missing; the installer leaves the file unchanged otherwise.

After changing the Hyprland configuration, reload it with `hyprctl reload` when supported by your Lua configuration runner, or restart the session.

## Uninstall

Run:

```bash
./uninstall.sh
```

Choose a normal uninstall to remove linked dotfile paths while keeping wallpapers and installer backups; it may separately ask about known runtime caches. Full reset offers removal of wallpapers, screenshots, caches, and installer backups. If Arc Noir was installed by this repository, full reset can remove its managed SDDM theme/config and restore saved prior files. The uninstaller removes a config symlink only when it resolves to the matching path in this checkout; unrelated symlinks, regular files, and directories are preserved.

## A Small Note

This is a personal desktop, not a universal preset. The config expects the applications and scripts named above, a Hyprland environment that supports this repository’s Lua `hl` API, and a working Wayland session. The installer helps with common Arch packages, but it cannot supply every external runtime or hardware-specific piece of a desktop.
