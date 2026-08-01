-- ===========================
-- Monitor configuration
-- ===========================
hl.monitor({ output = "eDP-1", mode = "preferred", position = "auto", scale = 1.6 })
hl.monitor({ output = "HDMI-A-3", mode = "preferred", position = "auto", scale = 1, mirror = "eDP-1" })


-- ===========================
-- Keybindings
-- ===========================
local mainMod = "ALT"
local subMod = "SUPER"

-- Terminal
hl.bind(mainMod .. " + Return", hl.dsp.exec_cmd("kitty"))

-- Anyrun
-- hl.bind(mainMod .. " + R", hl.dsp.exec_cmd("anyrun"))

-- walker
hl.bind(mainMod .. " + R", hl.dsp.exec_cmd("wofi --show drun"))

-- File manager
hl.bind(mainMod .. " + E", hl.dsp.exec_cmd("nemo"))


-- Window focus
for key, direction in pairs({ L = "right", K = "up", J = "down", H = "left" }) do
    hl.bind(mainMod .. " + " .. key, hl.dsp.focus({ direction = direction }))
end

-- Window move
for key, direction in pairs({ L = "right", K = "up", J = "down", H = "left" }) do
    hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ direction = direction }))
end

-- Window kill
hl.bind(mainMod .. " + Q", hl.dsp.window.kill())

-- Lock screen
hl.bind(mainMod .. " + F11", hl.dsp.exec_cmd("hyprlock --no-fade-in"))

-- Full screen
hl.bind(mainMod .. " + F", hl.dsp.window.fullscreen())

-- Grouping
hl.bind(mainMod .. " + T", hl.dsp.group.toggle())
hl.bind(mainMod .. " + SHIFT + L", hl.dsp.window.move({ into_group = "left" }))
hl.bind(mainMod .. " + SHIFT + H", hl.dsp.window.move({ into_group = "right" }))
hl.bind(mainMod .. " + SHIFT + J", hl.dsp.window.move({ into_group = "down" }))
hl.bind(mainMod .. " + SHIFT + K", hl.dsp.window.move({ into_group = "up" }))
hl.bind(mainMod .. " + L", hl.dsp.group.next())
hl.bind(mainMod .. " + H", hl.dsp.group.prev())
-- bind = $mainMod SHIFT, Tab, cyclenext, prev tiled

-- Workspace switch
for i = 1, 10 do
    local key = i % 10
    hl.bind(mainMod .. " + " .. key, hl.dsp.focus({ workspace = i }))
end

hl.bind(subMod .. " + l", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(subMod .. " + h", hl.dsp.focus({ workspace = "e-1" }))

-- Move window across workspace
for i = 1, 10 do
    local key = i % 10
    hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
end

hl.bind(mainMod .. " + " .. subMod .. " + l", hl.dsp.window.move({ workspace = "e+1" }))
hl.bind(mainMod .. " + " .. subMod .. " + h", hl.dsp.window.move({ workspace = "e-1" }))


-- Functional Keys
hl.bind("F2", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 10%-"))
hl.bind("F3", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 10%+"))
hl.bind("SHIFT + F2", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 1%-"))
hl.bind("SHIFT + F3", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 1%+"))
hl.bind("F1", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"))
hl.bind("F4", hl.dsp.exec_cmd("brightnessctl set 5%-"))
hl.bind("F5", hl.dsp.exec_cmd("brightnessctl set +5%"))
hl.bind("SHIFT + F4", hl.dsp.exec_cmd("brightnessctl set 1%-"))
hl.bind("SHIFT + F5", hl.dsp.exec_cmd("brightnessctl set +1%"))

-- Touchpad
hl.bind(mainMod .. " + Space", hl.dsp.exec_cmd("~/dotnix/resources/scripts/toggleTouchpad.sh"))

-- Sway-NC
hl.bind(mainMod .. " + N", hl.dsp.exec_cmd("swaync-client -t"))

-- Google
hl.bind(mainMod .. " + G", hl.dsp.exec_cmd("google-chrome-stable"))
hl.bind(mainMod .. " + U", hl.dsp.exec_cmd("google-chrome-stable --profile-directory=\"Default\"")) -- work profile
hl.bind(mainMod .. " + SHIFT + U", hl.dsp.exec_cmd("google-chrome-stable --profile-directory=\"Profile 2\"")) -- university profile
hl.bind(mainMod .. " + I", hl.dsp.exec_cmd("google-chrome-stable --profile-directory=\"Profile 1\"")) -- main profile

-- Asus laptop controls
hl.bind(mainMod .. " + F7", hl.dsp.exec_cmd("asusctl -n"))

-- Screen shortcuts
hl.bind(mainMod .. " + Print", hl.dsp.exec_cmd("~/dotnix/resources/scripts/screenshot.sh whole"))
hl.bind(mainMod .. " + F11", hl.dsp.exec_cmd("~/dotnix/resources/scripts/screenshot.sh selection"))
hl.bind(mainMod .. " + F8", hl.dsp.exec_cmd("gpu-screen-recorder-gtk"))

-- WireGuard
hl.bind(mainMod .. " + F9", hl.dsp.exec_cmd("~/dotnix/resources/scripts/toggleVPN.sh"))
