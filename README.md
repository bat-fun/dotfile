<div align="center">

# DOTFILES

**My personal Hyprland desktop. Minimal And built around a dark theme**

`ARCH LINUX` &nbsp;·&nbsp; `HYPRLAND` &nbsp;·&nbsp; `MATUGEN`

</div>

Read through the requirements and keybindings before installing; the setup expects a few specific applications.

## The Setup

| Area                 | Included                                                                            |
| -------------------- | ----------------------------------------------------------------------------------- |
| Window manager       | Hyprland Lua config, animations, rules, and keybindings                             |
| Shell of the desktop | Waybar, Rofi, Dunst, Kitty, wlogout, and GTK settings                               |
| Adaptive color       | Matugen templates for Waybar, Kitty, Rofi, Dunst, and Starship                      |
| Small tools          | Wallpaper picker, clipboard picker, screenshot helper, emoji picker, and web search |


## Install

Paste this into a terminal on Arch Linux:

```bash
sudo pacman -S --needed git && git clone https://github.com/bat-fun/dotfile.git && cd dotfile && ./install.sh
```

place wallpaper in  `~/Pictures/wallpaper` or change dir in scripts.,
Screenshots are saved to `~/Pictures/screenshots`.

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
| `SUPER + M`                               | Exit Hyprland, using `hyprshutdown`           |
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

## USE AS YOU LIKE 🙃🙃🙃
