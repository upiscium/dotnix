local laptopKbEnabled = true

hl.device({
    name = "asue120d:00-04f3:31fb-touchpad",
    enabled = laptopKbEnabled,
})

hl.config({
    xwayland = {
        force_zero_scaling = true,
    },

    general = {
        gaps_in = 0,
        gaps_out = 2,
        border_size = 2,

        col = {
            active_border = "rgb(255,0,0)",
            inactive_border = "rgb(68,0,0)",
        },

        layout = "dwindle",
    },

    animations = {
        enabled = true,
    },

    decoration = {
        rounding = 12,
        blur = {
            enabled = true,
            size = 8,
            passes = 3,
        },
    },
})

hl.curve("motion", {
    type = "bezier",
    points = {
        { 0.5, -0.3 },
        { 0, 1 },
    },
})

hl.animation({
    leaf = "windows",
    enabled = true,
    speed = 4,
    bezier = "motion",
    style = "popin",
})

hl.animation({
    leaf = "workspaces",
    enabled = true,
    speed = 4,
    bezier = "motion",
    style = "slidefade",
})

-- Toolkit-specific scale
hl.env("GDK_SCALE", "2")
hl.env("XCURSOR_SIZE", "16")

hl.on("hyprland.start", function()
    hl.exec_cmd("fcitx5")
    hl.exec_cmd("hypridle")
    hl.exec_cmd("nm-applet")
    hl.exec_cmd("hyprpaper")
    hl.exec_cmd("waybar-top")
    hl.exec_cmd("waybar-bottom")
    hl.exec_cmd("./.config/conky/start_conky.sh")
end)

require("platform")
