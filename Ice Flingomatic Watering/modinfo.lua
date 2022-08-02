
name = "Ice Flingomatic Watering"
description = "The ice flingomatic waters crops while active. Also has an option to only target witherable plants when it's hot enough to wither them."
author = "Bumber"
version = "1.9"
forumthread = ""

icon_atlas = "modicon.xml"
icon = "modicon.tex"

api_version = 10
dst_compatible = true
all_clients_require_mod = false
client_only_mod = false

priority = -2000 --this should load after other flingomatic mods

configuration_options =
{
    {
        name = "smart_target_wither",
        label = "Smart Target Witherables",
        hover = "Only target witherables when it's too hot out.",
        options =   {
                        {description = "Disabled", data = false, hover = ""},
                        {description = "Enabled", data = true, hover = ""},
                    },
        default = true,
    },
    {
        name = "smart_target_crops",
        label = "Smart Target Crops",
        hover = "Only target crops when they actually need water.",
        options =   {
                        {description = "Disabled", data = false, hover = "Keep the soil wet."},
                        {description = "Enabled", data = true, hover = "Water crops once per stage, and not when fully grown."},
                    },
        default = true,
    },
    {
        name = "target_center",
        label = "Target Soil",
        hover = "Target the center of each soil tile once, rather than every crop within it.",
        options =   {
                        {description = "Disabled", data = false, hover = "Not recommended. Snowballs can hit wrong tile for crops close to edge."},
                        {description = "Enabled", data = true, hover = "Don't spam snowballs."},
                    },
        default = true,
    },
    {
        name = "water_percent",
        label = "Desired Soil Moisture",
        hover = "Keep a crop's soil moisture above this amount if \"Smart Target Crops\" is disabled.",
        options =   {
                        {description = ">0%", data = 0.0, hover = ""},
                        {description = ">25%", data = 25.0, hover = ""},
                        {description = ">50%", data = 50.0, hover = ""},
                        {description = ">75%", data = 75.0, hover = ""},
                        {description = ">90%", data = 90.0, hover = ""},
                    },
        default = 0.0,
    },
    {
        name = "add_wetness",
        label = "Flingomatic Wetness",
        hover = "Flingomatic snowballs add this much wetness",
        options =   {
                        {description = "20", data = 20, hover = "Same as waterballoon and fire pump"},
                        {description = "25", data = 25, hover = "Same as watering can"},
                        {description = "50", data = 50, hover = ""},
                        {description = "75", data = 75, hover = "Same as ocean"},
                        {description = "100", data = 100, hover = ""},
                    },
        default = 20,
    },
}
