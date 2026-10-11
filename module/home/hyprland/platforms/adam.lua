-- Output names are host-specific; discover connected monitors automatically.
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = 1 })

-- Keep desktop interaction identical to Michael, without laptop-only controls.
require("keybindings")({ screenshot = "hypr-screenshot" })

-- Export the live compositor environment before UWSM starts session services
-- such as Sunshine (Hyprland's READY notification alone does not export it).
hl.on("hyprland.start", function()
    hl.exec_cmd("uwsm finalize")
end)
