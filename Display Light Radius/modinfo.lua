
name = "Display Light Radius"
description = "Display indicators of the range of darkness protection provided by lights."
author = "Bumber"
version = "1.1"
forumthread = ""

icon_atlas = "modicon.xml"
icon = "modicon.tex"

api_version = 10
dst_compatible = true
all_clients_require_mod = false
client_only_mod = true

local alpha_keys = {}
for i = ("a"):byte(), ("z"):byte() do
    alpha_keys[i+1-("a"):byte()] = {description = ("").char(i):upper(), data = i}
end

configuration_options =
{
    {
        name = "start_enabled",
        label = "Start Toggle Enabled",
        hover = "Have light radii enabled when entering game",
        options =
        {
            {description = "No", data = false, hover = "Start with radii off"},
            {description = "Yes", data = true, hover = "Start with radii on"},
        },
        default = false,
    },
    {
        name = "toggle_key",
        label = "Toggle Key",
        hover = "Use this key to toggle all light radii on/off",
        options = alpha_keys,
        default = ("r"):byte(),
    },
    {
        name = "highlight_mode",
        label = "Mouse-over Mode",
        hover = "Show light radius when hovering mouse over an object",
        options =
        {
            {description = "Disabled", data = 0, hover = "Show light radii only via toggle"},
            {description = "Hold Force Inspect", data = 1, hover = "Hover over while holding force inspect (default: left alt)"},
            {description = "Any Mouse-over", data = 2, hover = "Hover over without needing force inspect"},
        },
        default = 1,
    },
    {
        name = "light_color",
        label = "Color Radius",
        hover = "Color light radii based on light color",
        options =
        {
            {description = "No", data = false, hover = "Use white"},
            {description = "Yes", data = true, hover = "Use light color"},
        },
        default = true,
    },
    {
        name = "light_refresh",
        label = "Radius Refresh Rate",
        hover = "How often to recalculate light radius. Less often may increase performance, but look worse with some lights.",
        options =
        {
            {description = "0.1", data = 0.1, hover = "10 times per second"},
            {description = "0.2", data = 0.2, hover = "5 times per second"},
            {description = "0.5", data = 0.5, hover = "2 times per second"},
        },
        default = 0.1,
    },
    {
        name = "discover_rate",
        label = "Discovery Rate",
        hover = "How often to check all nearby entities for lights. 5 should be fine unless the delay on new sources bothers you for some reason.",
        options =
        {
            {description = "1", data = 1, hover = "Every 1 second"},
            {description = "2", data = 2, hover = "Every 2 seconds"},
            {description = "5", data = 5, hover = "Every 5 seconds"},
        },
        default = 5,
    },
}
