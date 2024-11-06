
name = "Sturdier Spider Den Decorations"
description = "Prevent spider dens from becoming undecorated when den or nearby spiders are hurt. Configurable."
author = "Bumber"
version = "1.8"
forumthread = ""

icon_atlas = "modicon.xml"
icon = "modicon.tex"

api_version = 10
dst_compatible = true
all_clients_require_mod = false
client_only_mod = false

priority = 1000

configuration_options =
{
    {
        name = "den_hit",
        label = "Den Hit",
        hover = "When to break bedazzlement if den hit.",
        options =
        {
            {description = "Default", data = 0, hover = "Break when den takes damage from any source."},
            {description = "No Earthquake", data = 1, hover = "Don't break from earthquake debris."},
            {description = "Player Only", data = 2, hover = "Only break when attacked by players."},
            {description = "Razor Only", data = 3, hover = "Only break when shorn by Webber."},
        },
        default = 0,
    },
    {
        name = "spider_hit",
        label = "Spider Hit",
        hover = "When to break bedazzlement if nearby spider hit.\n(Will be considered an attack on den, subject to above setting.)",
        options =
        {
            {description = "Default", data = 0, hover = "Break when spider takes damage from any source."},
            {description = "Player Only", data = 1, hover = "Only break when spider attacked by players."},
            {description = "Never", data = 2, hover = "Only break when den is directly attacked."},
        },
        default = 0,
    },
}
