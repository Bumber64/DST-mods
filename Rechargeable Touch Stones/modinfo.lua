
name = "Rechargeable Touch Stones"
description = "Recharge touch stones using life giving amulets or telltale hearts. Configurable."
author = "Bumber"
version = "1.0"
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
        name = "repair_type",
        label = "Recharge Item",
        hover = "Item used to recharge touch stone.",
        options =
        {
            {description = "Life Giving Amulet", data = 0, hover = ""},
            {description = "Telltale Heart (Penalty)", data = 1, hover = "Max health penalty applied upon recharging touch stone."},
            {description = "Telltale Heart (No Penalty)", data = 2, hover = ""},
        },
        default = 0,
    },
}
