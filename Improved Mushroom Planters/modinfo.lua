
name = "Improved Mushroom Planters"
description = "Planted mushrooms don't turn into rot in winter, plus configurable options for fertilizers and moon shrooms."
author = "Bumber"
version = "1.8"
forumthread = ""

icon_atlas = "modicon.xml"
icon = "modicon.tex"

api_version = 10
dst_compatible = true
all_clients_require_mod = false
client_only_mod = false
priority = 1

configuration_options =
{
    {
        name = "max_harvests",
        label = "Maximum Fertilization",
        hover = "Maximum amount of fertilizer value the planter can store.\nLiving logs restore this many harvests.",
        options =
        {
            {description = "Unlimited", data = -1, hover = "Default, but never decrease"},
            {description = "Default", data = 0, hover = "4 unless modded"},
            {description = "8", data = 8, hover = "8 harvests"},
            {description = "16", data = 16, hover = "16 harvests"},
            {description = "32", data = 32, hover = "32 harvests"},
        },
        default = 0,
    },
    {
        name = "easy_fert",
        label = "Allow Fertilizers",
        hover = "Can fertilizers can be used in place of living logs?",
        options =
        {
            {description = "No", data = false, hover = "Living logs only"},
            {description = "Yes", data = true, hover = "Fertilizes by the sum of all nutrients divided by 8"},
        },
        default = false,
    },
    {
        name = "snow_grow",
        label = "Grow When Snow-covered",
        hover = "Whether to continue growing in winter or pause growth until snow melts.",
        options =
        {
            {description = "No", data = false, hover = "Pause growth"},
            {description = "Yes", data = true, hover = "Keep growing"},
        },
        default = false,
    },
    {
        name = "spore_harvest",
        label = "Release Spores on Harvest",
        hover = "Option to release spores on player harvest instead of\nwhen finished growing (when grown from spores).",
        options =
        {
            {description = "Default", data = false, hover = "Release ASAP on max size"},
            {description = "On Harvest", data = true, hover = "Release only after harvesting"},
        },
        default = false,
    },
    {
        name = "moon_ok",
        label = "Everyone Plant Moon Shrooms",
        hover = "Should planters accept moon shrooms from everyone?\nDoesn't effect lunar spores.",
        options =
        {
            {description = "No", data = false, hover = "Only accept moon shrooms from Wormwood with appropriate skill"},
            {description = "Yes", data = true, hover = "Accept moon shrooms from everyone"},
        },
        default = false,
    },
    {
        name = "moon_spore",
        label = "Catchable Lunar Spores",
        hover = "Lunar spores can be caught with a bug net and used in a planter.\nWhat could go wrong?",
        options =
        {
            {description = "No", data = false, hover = "Spores just explode, as usual"},
            {description = "Yes", data = true, hover = "Spores can be caught and planted"},
        },
        default = false,
    },
}
