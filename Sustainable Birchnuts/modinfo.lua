
name = "Sustainable Birchnuts"
description = "Add an extra birchnut drop at a configurable chance to mature trees in all seasons. Also allow planting of rotten birchnuts."
author = "Bumber"
version = "1.2"
forumthread = ""

icon_atlas = "modicon.xml"
icon = "modicon.tex"

api_version = 10
dst_compatible = true
all_clients_require_mod = true
client_only_mod = false

priority = -1000

configuration_options =
{
    {
        name = "bonus_acorn_chance",
        label = "Extra Birchnut Chance",
        hover = "Chance to drop an extra birchnut (normal or tall trees, all seasons)",
        options =
        {
            {description = "0%", data = 0.0, hover = ""},
            {description = "25%", data = 0.25, hover = ""},
            {description = "50%", data = 0.5, hover = ""},
            {description = "75%", data = 0.75, hover = ""},
            {description = "100%", data = 1.0, hover = ""},
        },
        default = 0.0,
    },
    {
        name = "rotten_acorns",
        label = "Plantable Rotten Birchnuts",
        hover = "Birchnuts can still be planted after rotting instead of turning into rot.",
        options =
        {
            {description = "Disabled", data = false, hover = ""},
            {description = "Enabled", data = true, hover = ""},
        },
        default = false,
    },
}
