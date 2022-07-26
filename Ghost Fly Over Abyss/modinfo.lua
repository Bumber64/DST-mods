
name = "Ghost Fly Over Abyss"
description = "Allow player ghosts to fly over abyss in caves and through other creatures."
author = "Bumber"
version = "1.1"
forumthread = ""

icon_atlas = "modicon.xml"
icon = "modicon.tex"

api_version = 10
dst_compatible = true
all_clients_require_mod = false
client_only_mod = false

configuration_options =
{
    {
        name = "ghost_abyss",
        label = "Ghost Fly Over Abyss",
        hover = "Allows player ghosts to fly over cave abyss",
        options =
        {
            {description = "Enabled", data = true, hover = ""},
            {description = "Disabled", data = false, hover = ""},
        },
        default = true,
    },
    {
        name = "ghost_chars",
        label = "Ghost Fly Through Creatures",
        hover = "Allows player ghosts to fly through other creatures",
        options =
        {
            {description = "Enabled", data = true, hover = ""},
            {description = "Disabled", data = false, hover = ""},
        },
        default = true,
    },
}
