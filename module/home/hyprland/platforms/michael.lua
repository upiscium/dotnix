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
require('keybindings')()

-- Asus laptop controls
hl.bind(mainMod .. "+F2", hl.dsp.exec_cmd("asusctl leds prev"))
hl.bind(mainMod .. "+F3", hl.dsp.exec_cmd("asusctl leds next"))

-- ROGSTRIX settings
hl.bind(mainMod .. "+F4", hl.dsp.exec_cmd("asusctl aura effect --next-mode"))
hl.bind(mainMod .. "+F5", hl.dsp.exec_cmd('asusctl profile next && notify-send -u normal "ASUS Profile Switched" "$(asusctl profile get)"'))

-- Touchpad
hl.bind(mainMod .. "+Space", hl.dsp.exec_cmd("~/dotnix/scripts/toggleTouchpad.sh"))
hl.bind("F10", hl.dsp.exec_cmd("~/dotnix/scripts/toggleTouchpad.sh"))
