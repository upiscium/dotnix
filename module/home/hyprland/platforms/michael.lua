-- ===========================
-- Monitor configuration
-- ===========================
hl.monitor({ output = "eDP-1", mode = "preferred", position = "0x0", scale = 1 })
hl.monitor({ output = "DP-1", mode = "preferred", position = "2560x0", scale = 1 })
hl.monitor({ output = "HDMI-A-3", mode = "preferred", position = "auto-center-up", scale = 1 })

-- ===========================
-- Keybindings
-- ===========================
local mainMod = "ALT"
local subMod = "SUPER"

-- Terminal
hl.bind(mainMod .. "+Return", hl.dsp.exec_cmd("kitty"))

-- Anyrun
-- bind = $mainMod, R, exec, anyrun

-- walker
hl.bind(mainMod .. "+R", hl.dsp.exec_cmd("wofi --show drun"))

-- File manager
hl.bind(mainMod .. "+E", hl.dsp.exec_cmd("nemo"))

-- Window focus
hl.bind(mainMod .. "+L", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. "+K", hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. "+J", hl.dsp.focus({ direction = "down" }))
hl.bind(mainMod .. "+H", hl.dsp.focus({ direction = "left" }))

-- Window move
hl.bind(mainMod .. "+SHIFT+L", hl.dsp.window.move({ direction = "right" }))
hl.bind(mainMod .. "+SHIFT+K", hl.dsp.window.move({ direction = "up" }))
hl.bind(mainMod .. "+SHIFT+J", hl.dsp.window.move({ direction = "down" }))
hl.bind(mainMod .. "+SHIFT+H", hl.dsp.window.move({ direction = "left" }))

-- Window kill
hl.bind(mainMod .. "+Q", hl.dsp.window.close())

-- Lock screen
hl.bind(mainMod .. "+F11", hl.dsp.exec_cmd("hyprlock --no-fade-in"))

-- Full screen
hl.bind(mainMod .. "+F", hl.dsp.window.fullscreen())

-- Toggle floating
hl.bind(mainMod .. "+SHIFT+F", hl.dsp.window.float({ action = "toggle" }))

-- Grouping
-- bind = $mainMod, T, togglegroup
-- bind = $mainMod Shift, L, moveintogroup, l
-- bind = $mainMod Shift, H, moveintogroup, r
-- bind = $mainMod Shift, J, moveintogroup, d
-- bind = $mainMod Shift, K, moveintogroup, u
-- bind = $mainMod, L, changegroupactive, f
-- bind = $mainMod, H, changegroupactive, b
-- bind = $mainMod, Tab, cyclenext, prev tiled

-- Workspace switch
for i = 1, 9 do
    hl.bind(mainMod .. "+" .. i, hl.dsp.focus({ workspace = i }))
end
hl.bind(mainMod .. "+0", hl.dsp.focus({ workspace = 10 }))

hl.bind(subMod .. "+L", hl.dsp.focus({ workspace = "+1" }))
hl.bind(subMod .. "+H", hl.dsp.focus({ workspace = "-1" }))

-- Move window across workspace
for i = 1, 9 do
    hl.bind(mainMod .. "+SHIFT+" .. i, hl.dsp.window.move({ workspace = i }))
end
hl.bind(mainMod .. "+SHIFT+0", hl.dsp.window.move({ workspace = 10 }))

hl.bind(mainMod .. "+" .. subMod .. "+L", hl.dsp.window.move({ workspace = "+1" }))
hl.bind(mainMod .. "+" .. subMod .. "+H", hl.dsp.window.move({ workspace = "-1" }))

-- Functional Keys
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 10%+"))
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 10%-"))
hl.bind("CTRL+F3", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 10%+"))
hl.bind("CTRL+F2", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 10%-"))
hl.bind("CTRL+SHIFT+XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 1%+"))
hl.bind("CTRL+SHIFT+XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 1%-"))
hl.bind("SHIFT+F3", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 1%+"))
hl.bind("SHIFT+F2", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 1%-"))
hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"))
hl.bind("F1", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"))
hl.bind("F7", hl.dsp.exec_cmd("brightnessctl set 5%-"))
hl.bind("F8", hl.dsp.exec_cmd("brightnessctl set +5%"))
hl.bind("SHIFT+F7", hl.dsp.exec_cmd("brightnessctl set 1%-"))
hl.bind("SHIFT+F8", hl.dsp.exec_cmd("brightnessctl set +1%"))

-- Sway-NC
hl.bind(mainMod .. "+N", hl.dsp.exec_cmd("swaync-client -t"))

-- Google
hl.bind(mainMod .. "+G", hl.dsp.exec_cmd("google-chrome-stable"))
hl.bind(mainMod .. "+U", hl.dsp.exec_cmd('google-chrome-stable --profile-directory="Default"')) -- work profile
hl.bind(mainMod .. "+SHIFT+U", hl.dsp.exec_cmd('google-chrome-stable --profile-directory="Profile 7"')) -- university profile
hl.bind(mainMod .. "+I", hl.dsp.exec_cmd('google-chrome-stable --profile-directory="Profile 1"')) -- main profile

-- Asus laptop controls
hl.bind(mainMod .. "+F2", hl.dsp.exec_cmd("asusctl leds prev"))
hl.bind(mainMod .. "+F3", hl.dsp.exec_cmd("asusctl leds next"))

-- ROGSTRIX settings
hl.bind(mainMod .. "+F4", hl.dsp.exec_cmd("asusctl aura effect --next-mode"))
hl.bind(mainMod .. "+F5", hl.dsp.exec_cmd('asusctl profile next && notify-send -u normal "ASUS Profile Switched" "$(asusctl profile get)"'))

-- ====================
-- Custom scripts
-- ====================

-- Screen shortcuts
hl.bind(mainMod .. "+Print", hl.dsp.exec_cmd("~/dotnix/scripts/screenshot.sh whole"))
hl.bind(mainMod .. "+F6", hl.dsp.exec_cmd("~/dotnix/scripts/screenshot.sh selection"))
hl.bind(mainMod .. "+F9", hl.dsp.exec_cmd("gpu-screen-recorder-gtk"))

-- Touchpad
hl.bind(mainMod .. "+Space", hl.dsp.exec_cmd("~/dotnix/scripts/toggleTouchpad.sh"))
hl.bind("F10", hl.dsp.exec_cmd("~/dotnix/scripts/toggleTouchpad.sh"))

-- WireGuard
hl.bind(mainMod .. "+F12", hl.dsp.exec_cmd("~/dotnix/scripts/toggleVPN.sh"))
