
name = "Don't Fumble"
description = "Prevent players from fumbling tools and weapons. Also prevent monsters from smashing and stealing. Configurable."
author = "Bumber"
version = "1.10"
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
            {description = "Strong Grip", data = 1, hover = "As good as Wurt. (Doesn't protect item held by mouse if you drown.)"},
        },
        default = 0,
    },
    {
        name = "wet_nofumble",
        label = "No Wetness Fumble",
        hover = "Prevent players from dropping wet equipped tools. Allow protecting inventory from drowning (including item held by mouse, which strong grip doesn't).",
        options =
        {
            {description = "Default", data = 0, hover = ""},
            {description = "Protect Wet", data = 1, hover = "Protect tools and weapons from slippage even without strong grip."},
            {description = "Protect Drowning", data = 2, hover = "Protect from slippage and don't drop any items when drowning."},
        },
        default = 0,
    },
    {
        name = "cutless_nosteal",
        label = "Non-player Cutless Stealing",
        hover = "Protect targets from item theft by cutlesses held by non-players\n(such as powder monkeys).",
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
            {description = "No Containers", data = 1, hover = "Bearger will simply empty chests and fridges instead of hammering them."},
            {description = "No Trampling", data = 2, hover = "Bearger won't trample stuff while not angry. Trees and boulders still affected."},
            {description = "No Beehives", data = 3, hover = "Bearger won't smash containers, trample stuff, nor attack wild beehives."},
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
            {description = "No Containers", data = 1, hover = "Bearger won't target chests, fridges, nor dropped backpacks for looting."},
            {description = "No Structures", data = 2, hover = "Bearger won't target containers nor harvestable structures for looting."},
            {description = "No Pickables", data = 3, hover = "Bearger won't target containers, structures, nor plants for looting."},
        },
        default = 0,
    },
    divider,
    {
        name = "gdw_nocreature",
        label = "GDW Eating Creatures",
        hover = "Whether or not the great depths worm can eat most creatures.\n(Excludes players and Hutch.)",
        options =
        {
            {description = "Default", data = 0, hover = "Creatures are removed from existence, manure drops in place of loot."},
            {description = "No Creatures", data = 1, hover = "Creatures receive a large amount of damage instead, drop loot on death."},
            {description = "No Critters", data = 2, hover = "Small creatures (spiders, etc.) also damaged, not eaten like items."},
        },
        default = 0,
    },
    {
        name = "gdw_noitem",
        label = "GDW Eating Items",
        hover = "Limit which items the great depths worm can eat.\n(Small creatures are technically items, but handled above.)",
        options =
        {
            {description = "Default", data = 0, hover = "All non-irreplaceable stuff is removed from existence."},
            {description = "No Misc", data = 1, hover = "Protect inedible items. (Note: Bunny puffs, twigs, etc., are defined edible.)"},
            {description = "No Edibles", data = 2, hover = "Protect all items. Irreplaceables allow a brief attack window before spit out."},
        },
        default = 0,
    },
    {
        name = "gdw_noplayer",
        label = "GDW Eating Player/Hutch",
        hover = "Whether or not the great depths worm can eat the player or Hutch.\n(Technically includes Chester if he could enter caves.)",
        options =
        {
            {description = "Default", data = 0, hover = "Player or Hutch will be stucklocked and in limbo."},
            {description = "No Player", data = 1, hover = "Player will receive a large amount of nonlethal damage instead."},
            {description = "No Hutch", data = 2, hover = "Player or Hutch will receive a large amount of nonlethal damage instead."},
        },
        default = 0,
    },
    {
        name = "gdw_nosmash",
        label = "GDW Smashing",
        hover = "Protect structures, trees, etc., from the great depths worm.\n(Excludes walls, which have health.)",
        options =
        {
            {description = "Default", data = 0, hover = ""},
            {description = "No Smash", data = 1, hover = "The ground-pound AoE from burrowing won't act like a hammer."},
        },
        default = 0,
    },
    divider,
    {
        name = "icker_nofumble",
        label = "No Icker Fumble",
        hover = "Whether or not ickers can steal players' equipped\nweapons if they lack strong grip.",
        options =
        {
            {description = "Default", data = 0, hover = ""},
            {description = "No Fumble", data = 1, hover = ""},
        },
        default = 0,
    },
    {
        name = "icker_nosteal",
        label = "Icker Stealing",
        hover = "Protect backpacks and armor from being a sticker in the icker.",
        options =
        {
            {description = "Default", data = 0, hover = ""},
            {description = "No Backpacks", data = 1, hover = "Protect wearables that act as containers."},
            {description = "No Armor", data = 2, hover = "Protect anything worn by the player."},
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
        name = "krampus_nochest",
        label = "Krampus Rummaging",
        hover = "Have krampus empty chests instead of hammering,\nor just ignore them altogether.",
        options =
        {
            {description = "Default", data = 0, hover = "Krampus will hammer chests to get items out."},
            {description = "No Smash", data = 1, hover = "Krampus will empty chest contents without hammering."},
            {description = "Ignore Chests", data = 2, hover = "Krampus will ignore all chests."},
        },
        default = 0,
    },
    {
        name = "krampus_noexit",
        label = "Krampus Escape",
        hover = "Prevent krampus from exiting the universe.",
        options =
        {
            {description = "Default", data = 0, hover = "Krampus will exit after stealing enough items."},
            {description = "No Exit", data = 1, hover = "Krampus will stick around forever."},
        },
        default = 0,
    },
    {
        name = "krampus_nosteal",
        label = "Krampus Stealing",
        hover = "Limit what krampus can steal off of the ground.\nBeware that krampus will continue to spill chest contents if not prohibited from doing so!",
        options =
        {
            {description = "Default", data = 0, hover = ""},
            {description = "Food Only", data = 1, hover = "Krampus will only steal meat and goodies."},
            {description = "Ignore All", data = 2, hover = "Krampus will ignore all items."},
        },
        default = 0,
    },
    divider,
    {
        name = "marotter_nochest",
        label = "Marotter Rummaging",
        hover = "Limit what marotters can steal from containers.",
        options =
        {
            {description = "Default", data = 0, hover = "Steal any edible (including pig skin, etc.) except mandrakes."},
            {description = "Meat Only", data = 1, hover = "Steal only the meat/fish that the marotter will actually eat."},
            {description = "Ignore Containers", data = 2, hover = "Don't snatch items from containers."},
        },
        default = 0,
    },
    {
        name = "marotter_noharvest",
        label = "Marotter Harvesting",
        hover = "Limit what marotters can harvest.\n(Harvesting fish results in fish meat, not live fish.)",
        options =
        {
            {description = "Default", data = 0, hover = "Marotters will go fishing and harvest bull kelp."},
            {description = "No Fish", data = 1, hover = "Leave fish schools alone. Only harvest bull kelp."},
            {description = "No Kelp", data = 2, hover = "Harvest neither fish nor kelp."},
        },
        default = 0,
    },
    {
        name = "marotter_nosteal",
        label = "Marotter Stealing",
        hover = "Limit what marotters can steal off the ground, and prevent pickpocketing.",
        options =
        {
            {description = "Default", data = 0, hover = "Steal any edible (including pig skin, etc.) except mandrakes."},
            {description = "Protect Players", data = 1, hover = "Marotters won't pickpocket."},
            {description = "Meat Only", data = 2, hover = "Steal only the meat/fish that the marotter will actually eat."},
            {description = "Just Eat", data = 3, hover = "Eat meat/fish off the ground, when hungry."},
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
            {description = "No Masts", data = 1, hover = "Don't hammer masts on boats."},
            {description = "No Chests", data = 2, hover = "Don't hammer masts nor empty any chests."},
            {description = "Ignore All", data = 3, hover = "Don't hammer masts, empty chests, nor mess with anchors and winged sails."},
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
        label = "Powder Monkey Stealing",
        hover = "Limit what powder monkeys can steal off of the ground.",
        options =
        {
            {description = "Default", data = 0, hover = ""},
            {description = "Don't Wear Hats", data = 1, hover = "Powder monkeys won't equip any hats they pick up."},
            {description = "Bananas Only", data = 2, hover = "Powder monkeys will only grab some floor bananas."},
            {description = "Ignore All", data = 3, hover = "Powder monkeys can't grab items off of the ground."},
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
            {description = "No Containers", data = 1, hover = "Containers (including Hutch) protect your minerals."},
            {description = "No Players", data = 2, hover = "Slurtles and snurtles only clean up minerals left on the ground."},
        },
        default = 0,
    },
    divider,
    {
        name = "splumonkey_nochest",
        label = "Splumonkey Rummaging",
        hover = "Prevent splumonkeys from messing with your containers (including Hutch), which results in items dropped to the ground.",
        options =
        {
            {description = "Default", data = 0, hover = "Splumonkeys will empty containers of their contents."},
            {description = "Ignore Containers", data = 1, hover = "Splumonkeys will leave containers alone."},
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
            {description = "No Misc", data = 1, hover = "Splumonkeys won't steal recent drops nor items they see the player targeting."},
            {description = "No Hats", data = 2, hover = "Splumonkeys won't steal misc items nor hats."},
            {description = "No Pickables", data = 3, hover = "Splumonkeys won't steal misc items, hats, nor pick plants for food."},
            {description = "No Food", data = 4, hover = "Only pick up existing poop to throw, not the food to produce it."},
        },
        default = 0,
    },
}
