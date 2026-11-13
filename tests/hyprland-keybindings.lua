-- Run from the repository root with Lua 5.4:
-- lua tests/hyprland-keybindings.lua
-- An optional original Michael platform file also checks extraction equivalence.
package.path = "module/home/hyprland/?.lua;" .. package.path

local function serialize(value)
    if type(value) ~= "table" then
        return tostring(value)
    end
    local fields = {}
    for key, item in pairs(value) do
        fields[#fields + 1] = tostring(key) .. "=" .. serialize(item)
    end
    table.sort(fields)
    return "{" .. table.concat(fields, ",") .. "}"
end

local function capture(path)
    local bindings, monitors, workspaceRules, startupCommands = {}, {}, {}, {}
    local function dispatcher(name)
        return function(value)
            return { dispatcher = name, value = value }
        end
    end
    hl = {
        config = function(config)
            assert(type(config) == "table")
        end,
        bind = function(key, action)
            assert(not bindings[key], "Duplicate key: " .. key)
            bindings[key] = serialize(action)
        end,
        monitor = function(config)
            monitors[#monitors + 1] = serialize(config)
        end,
        workspace_rule = function(config)
            workspaceRules[#workspaceRules + 1] = serialize(config)
        end,
        on = function(event, callback)
            assert(event == "hyprland.start")
            callback()
        end,
        exec_cmd = function(command)
            startupCommands[#startupCommands + 1] = command
        end,
        dsp = {
            exec_cmd = dispatcher("exec"),
            focus = dispatcher("focus"),
            window = {
                move = dispatcher("move"),
                close = dispatcher("close"),
                fullscreen = dispatcher("fullscreen"),
                float = dispatcher("float"),
            },
        },
    }
    assert(loadfile(path))()
    return bindings, monitors, workspaceRules, startupCommands
end

local michael, michaelMonitors, michaelWorkspaceRules = capture("module/home/hyprland/platforms/michael.lua")
local adam, adamMonitors, adamWorkspaceRules, adamStartup = capture("module/home/hyprland/platforms/adam.lua")
local laptopOnly = {
    ["ALT+F2"] = true,
    ["ALT+F3"] = true,
    ["ALT+F4"] = true,
    ["ALT+F5"] = true,
    ["ALT+Space"] = true,
    ["F10"] = true,
}

for key, action in pairs(michael) do
    if laptopOnly[key] then
        assert(not adam[key], "Laptop-only binding on Adam: " .. key)
    else
        local expected = action:gsub("~/dotnix/scripts/screenshot%.sh", "hypr-screenshot")
        assert(adam[key] == expected, "Adam/Michael mismatch: " .. key)
    end
end
for key in pairs(adam) do
    assert(michael[key], "Unexpected Adam binding: " .. key)
end

for i = 1, 10 do
    local digit = i == 10 and 0 or i
    assert(adam["ALT+" .. digit], "Missing workspace switch: " .. digit)
    assert(adam["ALT+SHIFT+" .. digit], "Missing workspace move: " .. digit)
end
assert(adam["ALT+Return"] == serialize({ dispatcher = "exec", value = "kitty" }))
assert(adam["ALT+R"] == serialize({ dispatcher = "exec", value = "wofi --show drun" }))
assert(adam["ALT+F11"] == serialize({ dispatcher = "exec", value = "hyprlock --no-fade-in" }))
assert(#adamMonitors == 1)
assert(adamMonitors[1] == serialize({ output = "SUNSHINE", mode = "1920x1080@60", position = "0x0", scale = 1 }))
assert(#adamWorkspaceRules == 1)
assert(adamWorkspaceRules[1] == serialize({
    workspace = "1",
    monitor = "SUNSHINE",
    default = true,
    persistent = true,
}))
assert(#michaelWorkspaceRules == 0, "Adam-only workspace rule leaked to Michael")
assert(serialize(adamStartup) == serialize({ "adam-hyprland-session-ready" }))

if arg[1] then
    local original, originalMonitors = capture(arg[1])
    assert(serialize(original) == serialize(michael), "Michael bindings changed during extraction")
    assert(serialize(originalMonitors) == serialize(michaelMonitors), "Michael monitors changed")
end

print("PASS: shared bindings, workspace controls, host-specific exclusions, monitors and workspace rules")
