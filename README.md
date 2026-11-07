<div align="center">

# NOIR / DOTFILES

**A personal Hyprland desktop, tuned for quiet focus and quick movement.**

`ARCH LINUX` &nbsp;·&nbsp; `HYPRLAND` &nbsp;·&nbsp; `WAYLAND` &nbsp;·&nbsp; `MATUGEN`

<pre>
┌──────────────────────────────────────────────────────────┐
│  HYPRLAND      window management / Lua config            │
│  WAYBAR        compact status, workspaces, system state  │
│  ROFI          launcher, wallpaper and emoji workflows   │
│  MATUGEN       colors generated from your wallpaper      │
└──────────────────────────────────────────────────────────┘
</pre>

</div>

This is a working desktop, not a universal preset. It is built around an Arch-based Linux system running Hyprland. Read through the requirements and keybindings before installing; the setup expects a few specific applications and a Lua configuration layer that provides the `hl` API.

## The Setup

| Area                 | Included                                                                            |
| -------------------- | ----------------------------------------------------------------------------------- |
| Window manager       | Hyprland Lua config, animations, rules, and keybindings                             |
| Shell of the desktop | Waybar, Rofi, Dunst, Kitty, wlogout, and GTK settings                               |
| Adaptive color       | Matugen templates for Waybar, Kitty, Rofi, Dunst, and Starship                      |
| Small tools          | Wallpaper picker, clipboard picker, screenshot helper, emoji picker, and web search |

The palette leans into near-black surfaces, cool light text, and a sharp accent. Set a wallpaper, generate a matching palette, and let the rest of the desktop follow.

## Requirements

**Platform:** Arch Linux or an Arch-based distribution, Hyprland, and a Lua config loader compatible with the global `hl` API used by `hypr/hyprland.lua`. The loader is not included in this repository; make sure it is installed and configured before restarting Hyprland.

**Session essentials:** Waybar, Dunst, NetworkManager applet, `wl-clipboard`, `cliphist`, Kitty, Rofi, Hyprlock, wlogout, and `swww` (or Awww). The Hyprland startup config launches the available wallpaper daemon, `nm-applet`, and the clipboard watchers directly.

**Shortcuts and extras:** Brave, Code - OSS, Dolphin, `rofimoji`, `matugen`, `grim`, `slurp`, `brightnessctl`, `playerctl`, `wpctl`, `nmtui`, `nm-connection-editor`, and `blueman`.

**Fonts:** JetBrainsMono Nerd Font and Font Awesome are used by the desktop styling. GTK is set to Adwaita-dark.

The installer is for Arch Linux and Arch-based distributions. It checks the required packages and offers to install missing packages with `pacman`. Brave and Rofimoji come from the AUR; if you do not already have `yay` or `paru`, the installer can offer to build `yay`. It does not enable services, change display managers, or run the installer as root.

## Install

Paste this into a terminal on Arch Linux:

```bash
sudo pacman -S --needed git && git clone https://github.com/bat-fun/dotfile.git && cd dotfile && ./install.sh
```

The installer walks through package checks and asks before installing missing packages. It then lists every config path it will replace and asks you to continue. If configs already exist, it asks whether to back them up first. Answering `n` means **no backup is made**; those paths are still replaced after your confirmation.

When it finds wallpapers in `~/Pictures/wallpaper`, choose one to generate matching colors with Matugen. Choose `0` to skip. The installer copies regular files and directories into `~/.config`; it does not create symlinks.

Run the installer as your normal user. The one-line command uses `sudo` only for installing Git and any packages you approve. AUR packages are built as your normal user. Screenshots are saved to `~/Pictures/screenshots`.

## Keybindings

`SUPER` is the Windows/Super key.

| Keys                                      | Action                                             |
| ----------------------------------------- | -------------------------------------------------- |
| `SUPER + Return`                          | Open Kitty                                         |
| `SUPER + E`                               | Open Dolphin                                       |
| `SUPER + A`                               | Open the Rofi launcher                             |
| `SUPER + B`                               | Open Brave                                         |
| `SUPER + C`                               | Open Code - OSS                                    |
| `SUPER + G`                               | Search Google                                      |
| `SUPER + .`                               | Open the emoji picker                              |
| `SUPER + V`                               | Open clipboard history                             |
| `SUPER + SHIFT + V`                       | Clear clipboard history                            |
| `SUPER + W`                               | Choose a wallpaper                                 |
| `SUPER + R`                               | Apply a random wallpaper                           |
| `SUPER + SHIFT + W`                       | Restart Waybar                                     |
| `SUPER + L`                               | Lock the session                                   |
| `SUPER + X`                               | Open the logout menu                               |
| `SUPER + M`                               | Exit Hyprland, using `hyprshutdown` when available |
| `SUPER + Q`                               | Close the focused window                           |
| `SUPER + SPACE`                           | Toggle floating                                    |
| `SUPER + F`                               | Toggle fullscreen                                  |
| `SUPER + S`                               | Toggle the scratchpad terminal                     |
| `PRINT` / `SHIFT + PRINT`                 | Select an area / capture the full screen           |
| `SUPER + 1` … `SUPER + 0`                 | Switch to workspaces 1–10                          |
| `SUPER + SHIFT + 1` … `SUPER + SHIFT + 0` | Move the focused window to workspaces 1–10         |

Audio, microphone, brightness, and media keys are also configured where supported by the hardware.

## Repository Map

```text
dunst/       notifications
gtk-3.0/     GTK appearance
hypr/        Hyprland config, modules, and desktop scripts
kitty/       terminal
matugen/     color-generation config and templates
rofi/        launcher and wallpaper picker themes
waybar/      status bar
wlogout/     logout menu
starship.toml shell prompt
install.sh   guided package, config, backup, and wallpaper setup
```

## License

No license is included yet. Unless a license is added, standard copyright applies and reuse is not granted by default.
