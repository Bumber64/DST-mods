
name = "Nightvision for Free (Ultimate)"
description = "Updated and improved version of Gleenus's original mod.\n\n"..
    "Options for auto-toggling nightvision, adding a nightvision indicator, and changing nightvision colorcubes. "..
    "Takes moggles and WX-78's optoelectronic circuit into account."
author = "Bumber and Gleenus"
version = "1.0"

icon_atlas = "modicon.xml"
icon = "modicon.tex"

api_version = 10
dst_compatible = true
all_clients_require_mod = false
client_only_mod = true

priority = -1 --Load after other mods that modify moggle colorcubes

local alpha_keys = {}
alpha_keys[1] = {description = "Disabled", data = 0} --Allow disabling the toggle key
for i = ("a"):byte(), ("z"):byte() do
    alpha_keys[i+2-("a"):byte()] = {description = ("").char(i):upper(), data = i}
end
alpha_keys[#alpha_keys+1] = {description = "Disabled", data = 0} --Another disable after Z

local cc_options =
{
    {description = "Default", data = false, hover = "(Or use other mod setting.)"},
    {description = "None", data = "identity_colourcube.tex", hover = "#nofilter"},
    {description = "Moggles Bright", data = "mole_vision_off_cc.tex", hover = "Stare into the sun."},
    {description = "Moggles Black/Red", data = "mole_vision_on_cc.tex", hover = "Standard nightvision."},
    {description = "Werebeaver", data = "beaver_vision_cc.tex", hover = "Yellow"},
    {description = "Ghost", data = "ghost_cc.tex", hover = "Grayscale"},
    {description = "Autumn Night", data = "night03_cc.tex", hover = "Pale blue"},
    {description = "Caves", data = "caves_default.tex", hover = "Mute greens, strengthen blues."},
    {description = "Ruins Calm", data = "ruins_dark_cc.tex", hover = "Mute reds and greens, add blue."},
    {description = "Ruins Warning", data = "ruins_dim_cc.tex", hover = "Dark gray"},
    {description = "Ruins Wild", data = "ruins_light_cc.tex", hover = "Mute greens and blues, brighten reds."},
    {description = "Fungus", data = "fungus_cc.tex", hover = "Pink"},
    {description = "Moonstorm", data = "moonstorm_cc.tex", hover = "Add some blue."},
    {description = "Lunacy", data = "lunacy_regular_cc.tex", hover = "Dark blue"},
    {description = "Full Moon", data = "purple_moon_cc.tex", hover = "Indigo"},
}

local scale_options = {}
for i = 0, 10 do --1.0 to 2.0
    scale_options[i+1] = {description = ("%d%%"):format(100+i*10), data = 1.0+i*0.1}
end

local function offset_options(digit)
    local t = {}
    for i = -9, 9 do
        t[i+10] = {description = ("%d"):format(i*digit), data = i*digit}
    end
    return t
end

local divider = {name = "", label = "", options = {{description = "", data = 0}}, default = 0}

configuration_options =
{
    divider,
    {
        name = "TOGGLEKEY",
        label = "Toggle Nightvision Key",
        hover = "Use this key to toggle nightvision on and off (or disable key binding.)",
        options = alpha_keys,
        default = ("n"):byte(),
    },
    {
        name = "GRUEALERT",
        label = "Darkness Alert",
        hover = "Alert the player when they can be attacked by darkness.",
        options =
        {
            {description = "Disabled", data = 0},
            {description = "Warn Vulnerable", hover = "Don't alert while asleep, invincible, etc.", data = 1},
            {description = "Always Warn", hover = "Always warn while in darkness, even if not currently vulnerable.", data = 2},
        },
        default = 0,
    },
    {
        name = "GRUE_ALERT_NV_ONLY",
        label = "Darkness Alert Requires Free Nightvision",
        hover = "Only show darkness alert while free nightvision is active?",
        options =
        {
            {description = "Yes", data = true},
            {description = "No", hover = "Show alert even while free nightvision is off.", data = false},
        },
        default = true,
    },
    divider,
    {
        name = "MOGGLES_EQUIP",
        label = "Moggles Behaviour",
        hover = "How to handle free nightvision toggle when moggles are equipped.\nDoesn't toggle moggle nightvision itself.",
        options =
        {
            {description = "Always Toggle", data = 0, hover = "Turn on/off with key."},
            {description = "Toggle Off", data = 1, hover = "Turn off but not back on."},
            {description = "Don't Toggle", data = 2, hover = "Ignore toggle key while moggles are equipped."},
            {description = "Auto Toggle Off", data = 3, hover = "Automaticaly turn off whenever moggles are equipped."},
        },
        default = 0,
    },
    {
        name = "WX_ACTIVATE",
        label = "Optoelectronic Circuit Behaviour",
        hover = "How to handle free nightvision toggle when nightvision circuit is active.\nDoesn't toggle circuit itself.",
        options =
        {
            {description = "Always Toggle", data = 0, hover = "Turn on/off with key."},
            {description = "Toggle Off", data = 1, hover = "Turn off but not back on."},
            {description = "Don't Toggle", data = 2, hover = "Ignore toggle key while circuit is active."},
            {description = "Auto Toggle Off", data = 3, hover = "Automaticaly turn off whenever circuit activates."},
        },
        default = 0,
    },
    {
        name = "AUTO_DARK",
        label = "Auto Enable",
        hover = "When to turn on nightvision automatically.",
        options =
        {
            {description = "Disabled", data = 0, hover = "Manual toggle only."},
            {description = "Night", data = 1, hover = "Turn on at night when on surface."},
            {description = "Night and Caves", data = 2, hover = "Turn on at night and when in caves."},
            {description = "Darkness", data = 3, hover = "Turn on when entering darkness."},
        },
        default = 0,
    },
    {
        name = "AUTO_LIGHT",
        label = "Auto Disable",
        hover = "When to turn off nightvision automatically.",
        options =
        {
            {description = "Disabled", data = 0, hover = "Manual toggle only."},
            {description = "Day", data = 1, hover = "Turn off when on surface and sun rises."},
            {description = "Light", data = 2, hover = "Turn off when entering light."},
        },
        default = 0,
    },
    {
        name = "DUSK_IS_DAY",
        label = "Dusk is Day",
        hover = "Should dusk be considered day for colorcubes (if changed) and\nfor auto enable/disable?",
        options =
        {
            {description = "True", data = true},
            {description = "False", data = false},
        },
        default = true,
    },
    {
        name = "DAY_CC",
        label = "Day Colorcube",
        hover = "Colorcube to use for day and full moon while nightvision is enabled.\nAlso affects moggles.",
        options = cc_options,
        default = false,
    },
    {
        name = "NIGHT_CC",
        label = "Night Colorcube",
        hover = "Colorcube to use for night and caves while nightvision is enabled.\nAlso affects moggles.",
        options = cc_options,
        default = false,
    },
    divider,
    {
        name = "NV_ICON",
        label = "Nightvision Indicator",
        hover = "Adds a UI indicator of which types of nightvision are active.\n(Moggles, Optoelectronic Circuit, Free Nightvision)",
        options =
        {
            {description = "Disabled", data = false},
            {description = "Enabled", data = true},
        },
        default = false,
    },
    {
        name = "ICON_SCALE",
        label = "Indicator Scale",
        hover = "Adjust the size of the indicator.",
        options = scale_options,
        default = 1.4,
    },
    {
        name = "ICON_HANCHOR",
        label = "Indicator Horizontal Anchor",
        hover = "Where to place icon on screen horizontally.",
        options =
        {
            {description = "Left", data = 1}, --ANCHOR_LEFT
            {description = "Center", data = 0}, --ANCHOR_MIDDLE
            {description = "Right", data = 2}, --ANCHOR_RIGHT
        },
        default = 1,
    },
    {
        name = "ICON_VANCHOR",
        label = "Indicator Vertical Anchor",
        hover = "Where to place icon on screen vertically.",
        options =
        {
            {description = "Top", data = 1}, --ANCHOR_TOP
            {description = "Center", data = 0}, --ANCHOR_MIDDLE
            {description = "Bottom", data = 2}, --ANCHOR_BOTTOM
        },
        default = 1,
    },
    divider,
    {
        name = "ICON_X_ONES",
        label = "Indicator X Offset (Ones)",
        hover = "Fine-tune the indicator's horizontal location.\nNegative values are left, positive is right.",
        options = offset_options(1),
        default = 0,
    },
    {
        name = "ICON_X_TENS",
        label = "Indicator X Offset (Tens)",
        hover = "Apply this to the previous value.",
        options = offset_options(10),
        default = 0,
    },
    {
        name = "ICON_X_HUNDREDS",
        label = "Indicator X Offset (Hundreds)",
        hover = "Apply this to the previous values.",
        options = offset_options(100),
        default = 0,
    },
    divider,
    {
        name = "ICON_Y_ONES",
        label = "Indicator Y Offset (Ones)",
        hover = "Fine-tune the indicator's vertical location.\nNegative values are down, positive is up.",
        options = offset_options(1),
        default = 0,
    },
    {
        name = "ICON_Y_TENS",
        label = "Indicator Y Offset (Tens)",
        hover = "Apply this to the previous value.",
        options = offset_options(10),
        default = 0,
    },
    {
        name = "ICON_Y_HUNDREDS",
        label = "Indicator Y Offset (Hundreds)",
        hover = "Apply this to the previous values.",
        options = offset_options(100),
        default = 0,
    },
}
