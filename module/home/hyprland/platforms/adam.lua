-- Temporary VM black-screen diagnostics; restore the default after diagnosis.
-- Enable this before backend initialization so DRM/EGL startup is recorded.
hl.config({ debug = { disable_logs = false } })

-- UWSM selects the NVIDIA DRM card; place the desktop on its named virtual output.
hl.monitor({ output = "SUNSHINE", mode = "1920x1080@60", position = "0x0", scale = 1 })
hl.workspace_rule({ workspace = "1", monitor = "SUNSHINE", default = true, persistent = true })

-- Keep desktop interaction identical to Michael, without laptop-only controls.
require("keybindings")({ screenshot = "hypr-screenshot" })

-- Request the named output, then finalize UWSM even if creation fails so the
-- session remains diagnosable. Sunshine separately requires a valid mode/frame.
hl.on("hyprland.start", function()
    hl.exec_cmd("adam-hyprland-session-ready")
end)
