
name = "Display Light Radius"
description = "Display indicators for the range of darkness protection provided by lights."
author = "Bumber"
version = "1.2"
forumthread = ""

icon_atlas = "modicon.xml"
icon = "modicon.tex"

api_version = 10
dst_compatible = true
all_clients_require_mod = false
client_only_mod = true

local alpha_keys = {}
local KEY_A, KEY_F1 = 97, 282 --from constants.lua
for i = 0, 25 do --A to Z
    alpha_keys[i+1] = {description = ("").char(i+KEY_A):upper(), data = i+KEY_A}
end
for i = 26, 37 do --F1 to F12
    alpha_keys[i+1] = {description = ("F%d"):format(i-25), data = i+KEY_F1-26}
end

configuration_options =
{
    {
        name = "start_enabled",
        label = "Start Toggle Enabled",
        hover = "Have all radius indicators enabled when entering game?",
        options =
        {
            {description = "No", data = false, hover = "Start with indicators off."},
            {description = "Yes", data = true, hover = "Start with indicators on."},
        },
        default = false,
    },
    {
        name = "toggle_key",
        label = "Toggle Key",
        hover = "Use this key to toggle all indicators on/off.",
        options = alpha_keys,
        default = 114, --KEY_R
    },
    {
        name = "highlight_mode",
        label = "Mouse-over Mode",
        hover = "Show indicator when hovering mouse over an entity?\n(Doesn't work on every light source.)",
        options =
        {
            {description = "Disabled", data = 0, hover = "Only show indicators via toggle."},
            {description = "Hold Force Inspect", data = 1, hover = "Hover over while holding force inspect (default: Left Alt)."},
            {description = "Any Mouse-over", data = 2, hover = "Hover over without needing force inspect."},
        },
        default = 1,
    },
    {
        name = "radius_color",
        label = "Color Indicator",
        hover = "Color radius indicators based on light color.",
        options =
        {
            {description = "No", data = false, hover = "Use white."},
            {description = "Yes", data = true, hover = "Use light color."},
        },
        default = true,
    },
    {
        name = "radius_opacity",
        label = "Indicator Opacity",
        hover = "Make the radius indicators more transparent.",
        options =
        {
            {description = "0.1", data = 0.1, hover = "10%"},
            {description = "0.2", data = 0.2, hover = "20%"},
            {description = "0.3", data = 0.3, hover = "30%"},
            {description = "0.4", data = 0.4, hover = "40%"},
            {description = "0.5", data = 0.5, hover = "50%"},
            {description = "0.6", data = 0.6, hover = "60%"},
            {description = "0.7", data = 0.7, hover = "70%"},
            {description = "0.8", data = 0.8, hover = "80%"},
            {description = "0.9", data = 0.9, hover = "90%"},
            {description = "1.0", data = 1.0, hover = "100%"},
        },
        default = 0.5,
    },
    {
        name = "light_thresh",
        label = "Light Threshold",
        hover = "Which level of light the radius indicates.",
        options =
        {
            {description = "Leave Safety", data = 0.05, hover = "0.05"},
            {description = "Return to Safety", data = 0.075, hover = "0.075"},
            {description = "Sanity Loss", data = 0.1, hover = "0.1"},
        },
        default = 0.075,
    },
    {
        name = "radius_freq",
        label = "Indicator Refresh Rate",
        hover = "How often to recalculate light radius.\nLess often may increase performance, but look worse with some lights.",
        options =
        {
            {description = "0.1", data = 0.1, hover = "10 times per second."},
            {description = "0.2", data = 0.2, hover = "5 times per second."},
            {description = "0.5", data = 0.5, hover = "2 times per second."},
        },
        default = 0.1,
    },
    {
        name = "discover_freq",
        label = "Discovery Rate",
        hover = "How often to check all nearby entities for lights.\n5 should be fine unless the delay on new sources bothers you for some reason.",
        options =
        {
            {description = "1", data = 1.0, hover = "Every 1 second."},
            {description = "2", data = 2.0, hover = "Every 2 seconds."},
            {description = "5", data = 5.0, hover = "Every 5 seconds."},
        },
        default = 5.0,
    },
}
