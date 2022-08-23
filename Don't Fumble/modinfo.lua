
name = "Don't Fumble"
description = "Prevent players from fumbling tools and weapons. Also prevent monsters from smashing and stealing. Configurable."
author = "Bumber"
version = "1.0"
forumthread = ""

icon_atlas = "modicon.xml"
icon = "modicon.tex"

api_version = 10
dst_compatible = true
all_clients_require_mod = false
client_only_mod = false

local divider = {name = "", label = "", options = {{description = "", data = 0}}, default = 0}

configuration_options =
{
    divider,
    {
        name = "all_nofumble",
        label = "All Player Strong Grip",
        hover = "Whether or not all players have strong grip like Wurt.\n(Prevents fumbling tools and weapons, as well as inventory when drowning.)",
        options =
        {
            {description = "Default", data = 0, hover = ""},
            {description = "Strong Grip", data = 1, hover = ""},
        },
        default = 0,
    },
    {
        name = "wet_nofumble",
        label = "No Wetness Fumble",
        hover = "Prevent players from dropping wet equipped tools. Allow protecting inventory from drowning (including item held by mouse, which strong grip doesn't.)",
        options =
        {
            {description = "Default", data = 0, hover = ""},
            {description = "Tools", data = 1, hover = "Protect tools and weapons from slippage even without strong grip."},
            {description = "Drowning", data = 2, hover = "Protect tools and don't drop any items when drowning."},
        },
        default = 0,
    },
    {
        name = "cutless_nosteal",
        label = "Non-player Cutless Stealing",
        hover = "Protect targets from item theft by cutlesses held by non-players\n(such as powder monkeys.)",
        options =
        {
            {description = "Default", data = 0, hover = ""},
            {description = "Protect Players", data = 1, hover = "Don't knock items from player inventories."},
            {description = "Protect Followers", data = 2, hover = "Don't knock items from players nor their followers."},
            {description = "Protect All", data = 3, hover = "Don't knock items from any inventories, including hostiles."},
        },
        default = 0,
    },
    {
        name = "cutless_player",
        label = "Player Cutless Stealing",
        hover = "Protect targets from item theft by cutlesses held by players.",
        options =
        {
            {description = "Default", data = 0, hover = ""},
            {description = "Protect Players", data = 1, hover = "Don't knock items from player inventories."},
            {description = "Protect Followers", data = 2, hover = "Don't knock items from players nor their followers."},
            {description = "Protect All", data = 3, hover = "Don't knock items from any inventories, including hostiles."},
        },
        default = 0,
    },
    divider,
    {
        name = "moose_nofumble",
        label = "No Moose/Goose Fumble",
        hover = "Whether or not moose/goose honks cause players to drop\ntheir equipped weapons if they lack strong grip.",
        options =
        {
            {description = "Default", data = 0, hover = ""},
            {description = "No Fumble", data = 1, hover = ""},
        },
        default = 0,
    },
    divider,
    {
        name = "bearger_nofumble",
        label = "No Bearger Fumble",
        hover = "Whether or not bearger attacks cause players to drop\ntheir equipped weapons if they lack strong grip.",
        options =
        {
            {description = "Default", data = 0, hover = ""},
            {description = "No Fumble", data = 1, hover = ""},
        },
        default = 0,
    },
    {
        name = "bearger_nosmash",
        label = "Bearger Smashing",
        hover = "Have bearger do less unnecessary smashing.",
        options =
        {
            {description = "Default", data = 0, hover = ""},
            {description = "Containers", data = 1, hover = "Bearger will simply empty chests and fridges instead of hammering them."},
            {description = "Trampling", data = 2, hover = "Bearger won't trample stuff while not angry. Trees and boulders still affected."},
            {description = "Beehives", data = 3, hover = "Bearger won't smash containers, trample stuff, nor attack wild beehives."},
        },
        default = 0,
    },
    {
        name = "bearger_nosteal",
        label = "Bearger Stealing",
        hover = "Protect targets from bearger's sticky claws.",
        options =
        {
            {description = "Default", data = 0, hover = ""},
            {description = "Containers", data = 1, hover = "Bearger won't target chests, fridges, and dropped backpacks for looting."},
            {description = "Structures", data = 2, hover = "Bearger won't target containers nor harvestable structures for looting."},
            {description = "Pickables", data = 3, hover = "Bearger won't target containers, structures, nor plants for looting."},
        },
        default = 0,
    },
    divider,
    {
        name = "frog_nosteal",
        label = "Frog Stealing",
        hover = "Protect targets from frogs' sticky tongues.",
        options =
        {
            {description = "Default", data = 0, hover = ""},
            {description = "Protect Players", data = 1, hover = "Don't knock items from player inventories."},
            {description = "Protect Followers", data = 2, hover = "Don't knock items from players nor their followers."},
            {description = "Protect All", data = 3, hover = "Don't knock items from any inventories, including hostiles."},
        },
        default = 0,
    },
    divider,
    {
        name = "pmonkey_nosmash",
        label = "Powder Monkey Tinkering",
        hover = "Limit what powder monkeys can mess with during pirate raids.",
        options =
        {
            {description = "Default", data = 0, hover = ""},
            {description = "Masts", data = 1, hover = "Don't hammer masts on boats."},
            {description = "Chests", data = 2, hover = "Don't hammer masts nor empty any chests."},
            {description = "No Tinker", data = 3, hover = "Don't hammer masts, empty chests, nor mess with anchors and winged sails."},
        },
        default = 0,
    },
    {
        name = "pmonkey_nosteal",
        label = "Powder Monkey Pickpocketing",
        hover = "Protect targets from powder monkeys' sticky fingers.",
        options =
        {
            {description = "Default", data = 0, hover = ""},
            {description = "Protect Players", data = 1, hover = "Don't steal items from player inventories."},
            {description = "Protect Followers", data = 2, hover = "Don't steal items from players nor their followers."},
            {description = "Protect All", data = 3, hover = "Don't knock items from any inventories, including hostiles."},
        },
        default = 0,
    },
    {
        name = "pmonkey_nosteal_ground",
        label = "Powder Monkey Looting",
        hover = "Limit what powder monkeys can do with items found on the ground.",
        options =
        {
            {description = "Default", data = 0, hover = ""},
            {description = "Don't Wear Hats", data = 1, hover = "Powder monkeys won't equip any hats they pick up."},
            {description = "Bananas Only", data = 2, hover = "Powder monkeys will only grab some floor bananas."},
            {description = "No Looting", data = 3, hover = "Powder monkeys can't grab items off of the ground."},
        },
        default = 0,
    },
    divider,
    {
        name = "slurper_nosteal",
        label = "Hat Slurper Protection",
        hover = "What to do with your hat if a slurper attaches itself to your head.",
        options =
        {
            {description = "Default", data = 0, hover = "Hat always falls to the ground, where splumonkeys might steal it."},
            {description = "Unequip", data = 1, hover = "Hat will go into player inventory if space remains. Followers always drop hat."},
            {description = "Protect", data = 2, hover = "Hats protect players and followers from slurpers."},
        },
        default = 0,
    },
    divider,
    {
        name = "slurtle_nosteal",
        label = "Slurtle and Snurtle Stealing",
        hover = "Safeguard stuff from slurtle and snurtle snacking.",
        options =
        {
            {description = "Default", data = 0, hover = ""},
            {description = "Containers", data = 1, hover = "Containers (including Hutch) protect your minerals."},
            {description = "Players", data = 2, hover = "Slurtles and snurtles only clean up minerals left on the ground."},
        },
        default = 0,
    },
    divider,
    {
        name = "splumonkey_nochest",
        label = "Splumonkey Rummaging",
        hover = "Prevent splumonkeys from messing with your containers (including Hutch,) which results in items dropped to the ground.",
        options =
        {
            {description = "Default", data = 0, hover = ""},
            {description = "Ignore Containers", data = 1, hover = ""},
        },
        default = 0,
    },
    {
        name = "splumonkey_nosteal",
        label = "Splumonkey Stealing",
        hover = "Limit what splumonkeys can steal off of the ground.",
        options =
        {
            {description = "Default", data = 0, hover = ""},
            {description = "Miscellaneous", data = 1, hover = "Splumonkeys won't steal recent drops nor items they see the player targeting."},
            {description = "Hats", data = 2, hover = "Splumonkeys won't steal miscellaneous items nor hats."},
            {description = "Pickables", data = 3, hover = "Splumonkeys won't steal misc items, hats, nor pick plants for food."},
            {description = "Food", data = 4, hover = "Only pick up existing poop to throw, not the food to produce it."},
        },
        default = 0,
    },
}
