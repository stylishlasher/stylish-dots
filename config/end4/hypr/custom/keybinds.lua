-- User keybinds (loaded AFTER upstream ones, so these win)

hl.bind("CTRL+SUPER+ALT+Slash", hl.dsp.exec_cmd("xdg-open ~/.config/hypr/custom/keybinds.lua"),
    { description = "Edit user keybinds" })

local shotsDir = os.getenv("HOME") .. "/Изображения/Screenshots"
local prepare = "mkdir -p '" .. shotsDir .. "' && "

-- Print: whole active monitor -> file + clipboard + notification
hl.bind("Print", hl.dsp.exec_cmd(
    prepare .. "hyprshot -m output -m active -o '" .. shotsDir .. "' -f 'Screenshot_$(date +%Y-%m-%d_%H-%M-%S).png'"
), { locked = true, description = "Screenshot: save active monitor" })

-- Shift+Print: select a region with the mouse -> file + clipboard
hl.bind("SHIFT + Print", hl.dsp.exec_cmd(
    prepare .. "hyprshot -m region -o '" .. shotsDir .. "' -f 'Region_$(date +%Y-%m-%d_%H-%M-%S).png'"
), { locked = true, description = "Screenshot: select region" })

-- Ctrl+Print: clipboard only
hl.bind("CTRL + Print", hl.dsp.exec_cmd(
    "grim -o \"$(hyprctl activeworkspace -j | jq -r '.monitor')\" - | wl-copy && notify-send -a Hyprshot -t 3000 'Screenshot copied' 'Image copied to clipboard'"
), { locked = true, non_consuming = true, description = "Screenshot: copy to clipboard" })
