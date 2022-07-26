
name = "Sustainable Birchnuts"
description = "Add an extra birchnut drop at a configurable chance to mature trees in all seasons."
author = "Bumber"
version = "1.1"
forumthread = ""

icon_atlas = "modicon.xml"
icon = "modicon.tex"

api_version = 10
dst_compatible = true
all_clients_require_mod = false
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
            {description = "25%", data = 0.25, hover = ""},
            {description = "50%", data = 0.5, hover = ""},
            {description = "75%", data = 0.75, hover = ""},
            {description = "100%", data = 1.0, hover = ""},
        },
        default = 0.5,
    },
}
