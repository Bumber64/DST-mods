
name = "Loot Drop Tweaks"
description = "Guarantees (or improves the chance of) certain drops from monsters. Configurable."
author = "Bumber"
version = "1.11"
forumthread = ""

icon_atlas = "modicon.xml"
icon = "modicon.tex"

api_version = 10
dst_compatible = true
all_clients_require_mod = false
client_only_mod = false
priority = -0x80000000 --load after everything else, then we'll check the final loot tables

----------------------
-- General settings --
----------------------

configuration_options =
{
    {
        name = "batilisk_wing",
        label = "Batilisk Wing",
        hover = "Batilisk wing drop rate (batilisk)",
        options =   {
                        {description = "Default", data = 0.0, hover = "25% unless modded"},
                        {description = "50%", data = 0.5, hover = ""},
                        {description = "75%", data = 0.75, hover = ""},
                        {description = "100%", data = 1.0, hover = ""},
                    },
        default = 0.0,
    },
    {
        name = "bee_honey",
        label = "Bee Honey",
        hover = "Honey drop rates (bee and killer bee)",
        options =   {
                        {description = "Default", data = 0.0, hover = "16.7% unless modded"},
                        {description = "50%", data = 0.5, hover = "This makes bee loot drop independently!"},
                        {description = "100%", data = 1.0, hover = "This makes bee loot drop independently!"},
                    },
        default = 0.0,
    },
    {
        name = "bird_morsel",
        label = "Bird Morsel",
        hover = "Morsel drop rates (crow, puffin, redbird, and snowbird)",
        options =   {
                        {description = "Default", data = 0.0, hover = "50% unless modded"},
                        {description = "100%", data = 1.0, hover = "This makes (non-canary) bird loot drop independently!"},
                    },
        default = 0.0,
    },
    {
        name = "bird_feather",
        label = "Bird Feather",
        hover = "Feather drop rates (crow, puffin, redbird, and snowbird)",
        options =   {
                        {description = "Default", data = 0.0, hover = "50% unless modded"},
                        {description = "100%", data = 1.0, hover = "This makes (non-canary) bird loot drop independently!"},
                    },
        default = 0.0,
    },
    {
        name = "canary_saffron",
        label = "Canary Saffron Feather",
        hover = "Saffron feather drop rate (canary)\n[Also: Morsel drop rate 91% when Default, else 100%]",
        options =   {
                        {description = "Default", data = 0.0, hover = "9% unless modded"},
                        {description = "25%", data = 0.25, hover = "This makes canary loot drop independently!"},
                        {description = "50%", data = 0.5, hover = "This makes canary loot drop independently!"},
                        {description = "75%", data = 0.75, hover = "This makes canary loot drop independently!"},
                        {description = "100%", data = 1.0, hover = "This makes canary loot drop independently!"},
                    },
        default = 0.0,
    },
    {
        name = "bunnyman_carrot",
        label = "Bunnyman Carrot",
        hover = "Carrot drop rate (bunnyman, not beardlord)",
        options =   {
                        {description = "Default", data = 0.0, hover = "37.5% unless modded"},
                        {description = "50%", data = 0.5, hover = "This makes bunnyman loot drop independently!"},
                        {description = "75%", data = 0.75, hover = "This makes bunnyman loot drop independently!"},
                        {description = "100%", data = 1.0, hover = "This makes bunnyman loot drop independently!"},
                    },
        default = 0.0,
    },
    {
        name = "bunnyman_meat",
        label = "Bunnyman Meat",
        hover = "Meat drop rate (bunnyman, not beardlord)",
        options =   {
                        {description = "Default", data = 0.0, hover = "37.5% unless modded"},
                        {description = "50%", data = 0.5, hover = "This makes bunnyman loot drop independently!"},
                        {description = "75%", data = 0.75, hover = "This makes bunnyman loot drop independently!"},
                        {description = "100%", data = 1.0, hover = "This makes bunnyman loot drop independently!"},
                    },
        default = 0.0,
    },
    {
        name = "bunnyman_tail",
        label = "Bunnyman Bunny Puff",
        hover = "Bunny puff drop rate (bunnyman, excluding beardlord)",
        options =   {
                        {description = "Default", data = 0.0, hover = "25% unless modded"},
                        {description = "50%", data = 0.5, hover = "This makes bunnyman loot drop independently!"},
                        {description = "75%", data = 0.75, hover = "This makes bunnyman loot drop independently!"},
                        {description = "100%", data = 1.0, hover = "This makes bunnyman loot drop independently!"},
                    },
        default = 0.0,
    },
    {
        name = "catcoon_tail",
        label = "Catcoon Cat Tail",
        hover = "Cat tail drop rate (catcoon)",
        options =   {
                        {description = "Default", data = 0.0, hover = "33% unless modded"},
                        {description = "100%", data = 1.0, hover = ""},
                    },
        default = 0.0,
    },
    {
        name = "cookiecutter_shell",
        label = "Cookie Cutter Shell",
        hover = "Cookie cutter shell drop rate (cookie cutter)",
        options =   {
                        {description = "Default", data = 0.0, hover = "50% unless modded"},
                        {description = "100%", data = 1.0, hover = ""},
                    },
        default = 0.0,
    },
    {
        name = "dragonfly_egg",
        label = "Dragonfly Egg",
        hover = "Lavae egg drop rate (dragonfly)",
        options =   {
                        {description = "Default", data = 0.0, hover = "33% unless modded"},
                        {description = "75%", data = 0.75, hover = ""},
                        {description = "100%", data = 1.0, hover = ""},
                    },
        default = 0.0,
    },
    {
        name = "hound_tooth",
        label = "Hound Tooth",
        hover = "Hound's tooth drop rate (hound)",
        options =   {
                        {description = "Default", data = 0.0, hover = "12.5% unless modded"},
                        {description = "25%", data = 0.25, hover = ""},
                        {description = "50%", data = 0.5, hover = ""},
                        {description = "75%", data = 0.75, hover = ""},
                        {description = "100%", data = 1.0, hover = ""},
                    },
        default = 0.0,
    },
    {
        name = "hound_redgem",
        label = "Red Hound Gem",
        hover = "Red gem drop rate (red hound)",
        options =   {
                        {description = "Default", data = 0.0, hover = "20% unless modded"},
                        {description = "50%", data = 0.5, hover = ""},
                        {description = "75%", data = 0.75, hover = ""},
                        {description = "100%", data = 1.0, hover = ""},
                    },
        default = 0.0,
    },
    {
        name = "hound_bluegem",
        label = "Blue Hound Gem",
        hover = "Blue gem drop rate (blue hound)",
        options =   {
                        {description = "Default", data = 0.0, hover = "20% unless modded"},
                        {description = "50%", data = 0.5, hover = ""},
                        {description = "75%", data = 0.75, hover = ""},
                        {description = "100%", data = 1.0, hover = ""},
                    },
        default = 0.0,
    },
    {
        name = "krampus_pack",
        label = "Krampus Sack",
        hover = "Krampus Sack drop rate (krampus)",
        options =   {
                        {description = "Default", data = 0.0, hover = "1% unless modded"},
                        {description = "12.5%", data = 0.125, hover = ""},
                        {description = "25%", data = 0.25, hover = ""},
                        {description = "50%", data = 0.5, hover = ""},
                        {description = "75%", data = 0.75, hover = ""},
                        {description = "100%", data = 1.0, hover = ""},
                    },
        default = 0.0,
    },
    {
        name = "mactusk_hat",
        label = "MacTusk Hat",
        hover = "Tam o' Shanter drop rate (MacTusk)",
        options =   {
                        {description = "Default", data = 0.0, hover = "25% unless modded"},
                        {description = "50%", data = 0.5, hover = ""},
                        {description = "75%", data = 0.75, hover = ""},
                        {description = "100%", data = 1.0, hover = ""},
                    },
        default = 0.0,
    },
    {
        name = "mactusk_tusk",
        label = "MacTusk Tusk",
        hover = "Walrus tusk drop rate (MacTusk)",
        options =   {
                        {description = "Default", data = 0.0, hover = "50% unless modded"},
                        {description = "75%", data = 0.75, hover = ""},
                        {description = "100%", data = 1.0, hover = ""},
                    },
        default = 0.0,
    },

    {
        name = "pigman_meat",
        label = "Pig Meat",
        hover = "Meat drop rate (pig, excluding guardian pig and werepig)",
        options =   {
                        {description = "Default", data = 0.0, hover = "75% unless modded"},
                        {description = "100%", data = 1.0, hover = "This makes pig loot drop independently!"},
                    },
        default = 0.0,
    },
    {
        name = "pigman_skin",
        label = "Pig Skin",
        hover = "Pig skin drop rate (pig, excluding guardian pig and werepig)",
        options =   {
                        {description = "Default", data = 0.0, hover = "25% unless modded"},
                        {description = "50%", data = 0.5, hover = "This makes pig loot drop independently!"},
                        {description = "75%", data = 0.75, hover = "This makes pig loot drop independently!"},
                        {description = "100%", data = 1.0, hover = "This makes pig loot drop independently!"},
                    },
        default = 0.0,
    },
    {
        name = "spider_silk",
        label = "Spider Silk",
        hover = "Silk drop rates (all spider variants, excluding queen)",
        options =   {
                        {description = "Default", data = 0.0, hover = "25% unless modded"},
                        {description = "50%", data = 0.5, hover = "This makes spider loot drop independently!"},
                        {description = "75%", data = 0.75, hover = "This makes spider loot drop independently!"},
                        {description = "100%", data = 1.0, hover = "This makes spider loot drop independently!"},
                    },
        default = 0.0,
    },
    {
        name = "spider_gland",
        label = "Spider Glands",
        hover = "Spider gland drop rates (all spider variants, excluding queen)",
        options =   {
                        {description = "Default", data = 0.0, hover = "25% unless modded"},
                        {description = "50%", data = 0.5, hover = "This makes spider loot drop independently!"},
                        {description = "75%", data = 0.75, hover = "This makes spider loot drop independently!"},
                        {description = "100%", data = 1.0, hover = "This makes spider loot drop independently!"},
                    },
        default = 0.0,
    },
    {
        name = "slurtle_helm",
        label = "Shelmet",
        hover = "Shelmet drop rate (slurtle)",
        options =   {
                        {description = "Default", data = 0.0, hover = "10% unless modded"},
                        {description = "25%", data = 0.25, hover = ""},
                        {description = "50%", data = 0.5, hover = ""},
                        {description = "75%", data = 0.75, hover = ""},
                        {description = "100%", data = 1.0, hover = ""},
                    },
        default = 0.0,
    },
    {
        name = "snurtle_armor",
        label = "Snurtle Shell Armor",
        hover = "Snurtle shell armor drop rate (snurtle)",
        options =   {
                        {description = "Default", data = 0.0, hover = "75% unless modded"},
                        {description = "100%", data = 1.0, hover = ""},
                    },
        default = 0.0,
    },
    {
        name = "tentacle_spot",
        label = "Tentacle Spots",
        hover = "Tentacle spots drop rates (tentacle and big tentacle)",
        options =   {
                        {description = "Default", data = 0.0, hover = "20% (40% big) unless modded"},
                        {description = "50%", data = 0.5, hover = ""},
                        {description = "75%", data = 0.75, hover = ""},
                        {description = "100%", data = 1.0, hover = ""},
                    },
        default = 0.0,
    },
}
