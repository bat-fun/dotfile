---------------------
---- KEYBINDINGS ----
---------------------

local programs = require("module.programs")
local mainMod = "SUPER"

-- Core applications
hl.bind(mainMod .. " + Q", hl.dsp.window.close())

hl.bind(mainMod .. " + RETURN", hl.dsp.exec_cmd(programs.terminal))
hl.bind(mainMod .. " + E", hl.dsp.exec_cmd(programs.fileManager))
hl.bind(mainMod .. " + A", hl.dsp.exec_cmd(programs.menu))
hl.bind(mainMod .. " + B", hl.dsp.exec_cmd(programs.browser))
hl.bind(mainMod .. " + C", hl.dsp.exec_cmd(programs.code))

hl.bind(mainMod .. " + G", hl.dsp.exec_cmd("~/.config/hypr/scripts/google-search"))

-- Random wallpaper
hl.bind(mainMod .. " + R", hl.dsp.exec_cmd("~/.config/hypr/scripts/wallpaper-picker --random"))

-- Session / UI
hl.bind(mainMod .. " + W", hl.dsp.exec_cmd("pkill -x waybar || true; waybar"))
hl.bind(mainMod .. " + L", hl.dsp.exec_cmd("hyprlock"))
hl.bind(mainMod .. " + X", hl.dsp.exec_cmd("wlogout"))
hl.bind(mainMod .. " + M", hl.dsp.exec_cmd("command -v hyprshutdown >/dev/null 2>&1 && hyprshutdown || hyprctl dispatch exit"))
hl.bind(mainMod .. " + D", hl.dsp.exec_cmd("~/.config/hypr/scripts/wallpaper-picker"))

hl.bind(mainMod .. " + period",hl.dsp.exec_cmd("~/.config/hypr/scripts/emoji-picker"))
-- Clipboard / screenshots
hl.bind(mainMod .. " + V", hl.dsp.exec_cmd("~/.config/hypr/scripts/clipboard-picker"))
-- hl.bind(mainMod .. " + V",  hl.dsp.exec_cmd("~/.config/hypr/scripts/clipboard-vault"))
hl.bind("PRINT", hl.dsp.exec_cmd("~/.config/hypr/scripts/screenshot"))
hl.bind("SHIFT + PRINT", hl.dsp.exec_cmd("~/.config/hypr/scripts/screenshot full"))
hl.bind(mainMod .. " + SHIFT + V", hl.dsp.exec_cmd("cliphist wipe && wl-copy --clear && notify-send -t 1800 'Clipboard' 'History cleared'"))

-- Window behavior
hl.bind(mainMod .. " + SPACE", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + P", hl.dsp.window.pseudo())
hl.bind(mainMod .. " + J", hl.dsp.layout("togglesplit"))
hl.bind(mainMod .. " + F", hl.dsp.window.fullscreen())

-- Focus
hl.bind(mainMod .. " + left", hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + right", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + up", hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + down", hl.dsp.focus({ direction = "down" }))

-- Workspaces
for i = 1, 10 do
    local key = i % 10
    hl.bind(mainMod .. " + " .. key, hl.dsp.focus({ workspace = i }))
    hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
end


-- Scratchpad terminal
local function toggle_scratchpad()
    local scratchpad = hl.get_window("class:scratchpad")

    if scratchpad ~= nil then
        hl.dispatch(hl.dsp.workspace.toggle_special("scratchpad"))
        return
    end

    hl.dispatch(hl.dsp.exec_cmd( "kitty --class scratchpad --title Scratchpad",
            {
                workspace = "special:scratchpad",
                float = true,
                center = true,
                size = {
                    "monitor_w * 0.75",
                    "monitor_h * 0.50",
                },
            }
        )
    )
end

hl.bind(mainMod .. " + S", toggle_scratchpad, { description = "Toggle scratchpad terminal" })

hl.bind(mainMod .. " + SHIFT + S", hl.dsp.window.move({ workspace = "special:scratchpad" }), { description = "Send window to scratchpad" })

-- Workspace scrolling
hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + mouse_up", hl.dsp.focus({ workspace = "e-1" }))

-- Mouse movement
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- Media / hardware
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"), { locked = true, repeating = true })
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"), { locked = true, repeating = true })
hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"), { locked = true, repeating = true })
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%+"), { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%-"), { locked = true, repeating = true })

hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"), { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"), { locked = true })