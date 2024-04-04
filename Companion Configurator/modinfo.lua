
name = "Companion Configurator" --formerly "Invincible Friendly Fruit Fly"
description = "Modify follower mass, remove loyalty loss, and make them not trigger traps. Make non-combat followers invincible or non-targetable."
author = "Bumber"
version = "2.7"
forumthread = ""

icon_atlas = "modicon.xml"
icon = "modicon.tex"

api_version = 10
dst_compatible = true
all_clients_require_mod = false
client_only_mod = false

priority = -1

local function health_options(txt)
    local rv =
    {
        {description = "Default", data = 0, hover = txt},
        {description = "Beefy", data = 1, hover = "10k health with default recovery."},
        {description = "Instant Regen", data = 2, hover = "10k health that fully recovers every second."},
        {description = "Invincible", data = 3, hover = "Don't take damage."},
    }
    return rv
end

local divider = {name = "", label = "", options = {{description = "", data = 0}}, default = 0}

configuration_options =
{
    divider,
    {
        name = "chester_health",
        label = "Chester/Hutch Health",
        hover = "Make Chester and Hutch harder to kill.",
        options = health_options("450 health when unmodded."),
        default = 0,
    },
    {
        name = "chester_notarget",
        label = "Chester/Hutch Non-targetable",
        hover = "Whether or not Chester or Hutch can be targeted for attacks.",
        options =
        {
            {description = "Default", data = 0, hover = "Can be targeted and trigger spider creep."},
            {description = "Non-targetable", data = 1, hover = "Can't be targeted or trigger spider creep."},
        },
        default = 0,
    },
    {
        name = "hutch_fridge",
        label = "Hutch Fridge",
        hover = "Make Hutch act like Snow Chester.",
        options =
        {
            {description = "Default", data = 0, hover = "Normal spoilage rate."},
            {description = "Cold", data = 1, hover = "Cool thermal stones and slow food spoilage."},
        },
        default = 0,
    },
    {
        name = "shadow_fridge",
        label = "Shadow Fridge",
        hover = "Make Maxwell and Shadow Chester's shared storage act like Snow Chester.",
        options =
        {
            {description = "Default", data = 0, hover = "High spoilage rate."},
            {description = "Cool", data = 1, hover = "Cool thermal stones and somewhat slow food spoilage."},
            {description = "Cold", data = 2, hover = "Cool thermal stones and slow food spoilage."},
        },
        default = 0,
    },
    {
        name = "chester_mass",
        label = "Chester/Hutch Mass",
        hover = "How difficult Chester and Hutch are to push around, or push others.",
        options =
        {
            {description = "1", data = 1, hover = "Same as fruit flies, catcoons, and glommer."},
            {description = "10", data = 10, hover = "Same as spider, tallbird, hounds, etc."},
            {description = "30", data = 30, hover = ""},
            {description = "50", data = 50, hover = "Same as pigs, merms, and pet lavae."},
            {description = "70", data = 70, hover = ""},
            {description = "Default", data = 0, hover = "75 when unmodded (same as player)"},
        },
        default = 0,
    },
    divider,
    {
        name = "glommer_health",
        label = "Glommer Health",
        hover = "Make Glommer harder to kill.",
        options = health_options("100 health when unmodded."),
        default = 0,
    },
    {
        name = "glommer_notarget",
        label = "Glommer Non-targetable",
        hover = "Whether or not Glommer can be targeted for attacks.",
        options =
        {
            {description = "Default", data = 0, hover = "Can be targeted."},
            {description = "Non-targetable", data = 1, hover = "Can't be targeted."},
        },
        default = 0,
    },
    {
        name = "glommer_mass",
        label = "Glommer Mass",
        hover = "How difficult Glommer is to push around, or push others.",
        options =
        {
            {description = "Default", data = 0, hover = "1 when unmodded"},
            {description = "10", data = 10, hover = "Same as spider, tallbird, hounds, etc."},
            {description = "30", data = 30, hover = ""},
            {description = "50", data = 50, hover = "Same as pigs, merms, and pet lavae."},
            {description = "70", data = 70, hover = ""},
        },
        default = 0,
    },
    divider,
    {
        name = "polly_health",
        label = "Polly Rogers Health",
        hover = "Make Polly Rogers harder to kill.",
        options = health_options("50 health when unmodded."),
        default = 0,
    },
    {
        name = "polly_notarget",
        label = "Polly Rogers Non-targetable",
        hover = "Whether or not Polly Rogers can be targeted for attacks.",
        options =
        {
            {description = "Default", data = 0, hover = "Can be targeted."},
            {description = "Non-targetable", data = 1, hover = "Can't be targeted."},
        },
        default = 0,
    },
    {
        name = "polly_mass",
        label = "Polly Rogers Mass",
        hover = "How difficult Polly Rogers is to push around, or push others.",
        options =
        {
            {description = "Default", data = 0, hover = "1 when unmodded"},
            {description = "10", data = 10, hover = "Same as spider, tallbird, hounds, etc."},
            {description = "30", data = 30, hover = ""},
            {description = "50", data = 50, hover = "Same as pigs, merms, and pet lavae."},
            {description = "70", data = 70, hover = ""},
        },
        default = 0,
    },
    divider,
    {
        name = "fffly_health",
        label = "Friendly Fruit Fly Health",
        hover = "Make the friendly fruit fly harder to kill.",
        options = health_options("100 health when unmodded."),
        default = 0,
    },
    {
        name = "fffly_notarget",
        label = "Friendly Fruit Fly Non-targetable",
        hover = "Whether or not the friendly fruit fly can be targeted for attacks.",
        options =
        {
            {description = "Default", data = 0, hover = "Can be targeted."},
            {description = "Non-targetable", data = 1, hover = "Can't be targeted."},
        },
        default = 0,
    },
    {
        name = "fffly_nofreeze",
        label = "Friendly Fruit Fly Unfreezable",
        hover = "Whether or not the friendly fruit fly can be frozen.",
        options =
        {
            {description = "Default", data = 0, hover = "Can be frozen as usual."},
            {description = "Freeze Immunity", data = 1, hover = "Can't be frozen."},
        },
        default = 0,
    },
    {
        name = "fffly_mass",
        label = "Friendly Fruit Fly Mass",
        hover = "How difficult the friendly fruit fly is to push around, or push others.",
        options =
        {
            {description = "Default", data = 0, hover = "1 when unmodded"},
            {description = "10", data = 10, hover = "Same as spider, tallbird, hounds, etc."},
            {description = "30", data = 30, hover = ""},
            {description = "50", data = 50, hover = "Same as pigs, merms, and pet lavae."},
            {description = "70", data = 70, hover = ""},
        },
        default = 0,
    },
    divider,
    {
        name = "lavae_pet_health",
        label = "Pet Lavae Health",
        hover = "Make extra-adorable lavae harder to kill. (Freezing overrides invincibility.)",
        options = health_options("250 health when unmodded."),
        default = 0,
    },
    {
        name = "lavae_pet_notarget",
        label = "Pet Lavae Non-targetable",
        hover = "Whether or not extra-adorable lavae can be targeted for attacks.\n(Can be frozen by giving an ice staff or being hit by ice flingomatic.)",
        options =
        {
            {description = "Default", data = 0, hover = "Can be targeted and trigger spider creep."},
            {description = "Non-targetable", data = 1, hover = "Can't be targeted or trigger spider creep."},
        },
        default = 0,
    },
    {
        name = "lavae_pet_nofreeze",
        label = "Pet Lavae Unfreezable",
        hover = "Whether or not extra-adorable lavae can be frozen by ordinary means.",
        options =
        {
            {description = "Default", data = 0, hover = "Can be frozen as usual."},
            {description = "Freeze Protection", data = 1, hover = "Can only be frozen by giving it an ice staff."},
            {description = "Freeze Immunity", data = 2, hover = "Can't be frozen. Giving it an ice staff yields a Chilled Lavae."},
        },
        default = 0,
    },
    {
        name = "lavae_pet_nofire",
        label = "Pet Lavae Fire Prevention",
        hover = "Whether or not extra-adorable lavae can ignite nearby objects.",
        options =
        {
            {description = "Default", data = 0, hover = "Lavae can start fires."},
            {description = "Prevent", data = 1, hover = "Lavae won't start fires. (Still provides warmth for players.)"},
        },
        default = 0,
    },
    {
        name = "lavae_pet_mass",
        label = "Pet Lavae Mass",
        hover = "How difficult extra-adorable lavae are to push around, or push others.",
        options =
        {
            {description = "1", data = 1, hover = "Same as fruit flies, catcoons, and glommer."},
            {description = "10", data = 10, hover = "Same as spider, tallbird, hounds, etc."},
            {description = "30", data = 30, hover = ""},
            {description = "Default", data = 0, hover = "50 when unmodded"},
            {description = "70", data = 70, hover = ""},
        },
        default = 0,
    },
    divider,
    {
        name = "beefalo_health",
        label = "Bonded Beefalo Health",
        hover = "Make bonded beefalo harder to kill.\nDisables beefalo attacks while active.",
        options = health_options("1000 health when unmodded."),
        default = 0,
    },
    {
        name = "beefalo_notarget",
        label = "Bonded Beefalo Non-targetable",
        hover = "Whether or not bonded beefalo can be targeted for attacks.\nDisables beefalo attacks while active.",
        options =
        {
            {description = "Default", data = 0, hover = "Can be targeted and trigger spider creep."},
            {description = "Non-targetable", data = 1, hover = "Can't be targeted or trigger spider creep."},
        },
        default = 0,
    },
    {
        name = "beefalo_ride",
        label = "Bonded Beefalo Riding",
        hover = "Do the above settings apply while riding the bonded beefalo?\n(Ignored if above are default.)",
        options =
        {
            {description = "Suspend", data = 0, hover = "Temporarily disable while mounted."},
            {description = "Always On", data = 1, hover = "Apply even while mounted. Player recieves mounted damage."},
        },
        default = 0,
    },
    {
        name = "beefalo_mass",
        label = "Beefalo Mass",
        hover = "How difficult bonded beefalo are to push around, or push others.",
        options =
        {
            {description = "1", data = 1, hover = "Same as fruit flies, catcoons, and glommer."},
            {description = "10", data = 10, hover = "Same as spider, tallbird, hounds, etc."},
            {description = "30", data = 30, hover = ""},
            {description = "50", data = 50, hover = "Same as pigs, merms, and pet lavae."},
            {description = "70", data = 70, hover = ""},
            {description = "Default", data = 0, hover = "100 when unmodded"},
        },
        default = 0,
    },
    divider,
    {
        name = "spiders_notrap",
        label = "Spider No Trap Trigger",
        hover = "Should follower spiders trigger traps?",
        options =
        {
            {description = "Default", data = 0, hover = "All spiders will trigger traps."},
            {description = "Don't Trigger", data = 1, hover = "Follower spiders won't trigger traps."},
        },
        default = 0,
    },
    {
        name = "spiders_deadleader",
        label = "Spider Follow on Death",
        hover = "Should spiders keep loyalty when player dies?",
        options =
        {
            {description = "Default", data = 0, hover = "Spiders will disband on player death."},
            {description = "Keep Loyalty", data = 1, hover = "Spiders will remain loyal on player death."},
        },
        default = 0,
    },
    {
        name = "spiders_mass",
        label = "Spider Mass",
        hover = "How difficult follower spiders are to push around, or push others.",
        options =
        {
            {description = "1", data = 1, hover = "Same as fruit flies, catcoons, and glommer."},
            {description = "Default", data = 0, hover = "10 when unmodded"},
            {description = "30", data = 30, hover = ""},
            {description = "50", data = 50, hover = "Same as pigs, merms, and pet lavae."},
            {description = "70", data = 70, hover = ""},
        },
        default = 0,
    },
    divider,
    {
        name = "pigmermbun_notrap",
        label = "Pig/Merm/Bun No Trap Trigger",
        hover = "Should follower pigs, merms, and bunnymen trigger traps?",
        options =
        {
            {description = "Default", data = 0, hover = "Pigs, merms, and bunnymen will trigger traps."},
            {description = "Don't Trigger", data = 1, hover = "Follower pigs, merms, and bunnymen won't trigger traps."},
        },
        default = 0,
    },
    {
        name = "pigmermbun_loyalty",
        label = "Pig/Merm/Bun No Loyaly Timer",
        hover = "Should pigs, merms, and bunnymen lose loyalty over time?",
        options =
        {
            {description = "Default", data = 0, hover = "Pigs, merms, and bunnymen lose loyalty over time."},
            {description = "No Loyalty Timer", data = 1, hover = "Pigs, merms, and bunnymen don't lose loyalty over time."},
        },
        default = 0,
    },
    {
        name = "pigmermbun_deadleader",
        label = "Pig/Merm/Bun Follow on Death",
        hover = "Should pigs, merms, and bunnymen keep loyalty when player dies?",
        options =
        {
            {description = "Default", data = 0, hover = "Pigs, merms, and bunnymen will disband on player death."},
            {description = "Keep Loyalty", data = 1, hover = "Pigs, merms, and bunnymen will remain loyal on player death."},
        },
        default = 0,
    },
    {
        name = "pigmermbun_mass",
        label = "Pig/Merm/Bun Mass",
        hover = "How difficult follower pigs, merms, and bunnymen are to push around,\nor push others.",
        options =
        {
            {description = "1", data = 1, hover = "Same as fruit flies, catcoons, and glommer."},
            {description = "10", data = 10, hover = "Same as spider, tallbird, hounds, etc."},
            {description = "30", data = 30, hover = ""},
            {description = "Default", data = 0, hover = "50 when unmodded"},
            {description = "70", data = 70, hover = ""},
        },
        default = 0,
    },
    divider,
    {
        name = "rocky_loyalty",
        label = "Rock Lobster No Loyaly Timer",
        hover = "Should rock lobsters lose loyalty over time?\n(Disabling timer also prevents loyalty loss when scared by bosses.)",
        options =
        {
            {description = "Default", data = 0, hover = "Rock lobsters lose loyalty over time."},
            {description = "No Loyalty Timer", data = 1, hover = "Rock lobsters don't lose loyalty over time or when scared by bosses."},
        },
        default = 0,
    },
    {
        name = "rocky_deadleader",
        label = "Rock Lobster Follow on Death",
        hover = "Should rock lobsters keep loyalty when player dies?",
        options =
        {
            {description = "Default", data = 0, hover = "Rock lobsters will disband on player death."},
            {description = "Keep Loyalty", data = 1, hover = "Rock lobsters will remain loyal on player death."},
        },
        default = 0,
    },
    {
        name = "rocky_speed",
        label = "Rock Lobster Speed",
        hover = "Follower rock lobster walk speed.",
        options =
        {
            {description = "Default", data = 0, hover = "2 when unmodded"},
            {description = "3", data = 3, hover = "Same as pig walk speed"},
            {description = "4", data = 4, hover = "Same as spider warrior walk speed"},
            {description = "5", data = 5, hover = "Same as pig run speed"},
            {description = "6", data = 6, hover = "Same as default player run speed"},
        },
        default = 0,
    },
    {
        name = "rocky_mass",
        label = "Rock Lobster Mass",
        hover = "How difficult follower rock lobsters are to push around, or push others.",
        options =
        {
            {description = "1", data = 1, hover = "Same as fruit flies, catcoons, and glommer."},
            {description = "10", data = 10, hover = "Same as spider, tallbird, hounds, etc."},
            {description = "30", data = 30, hover = ""},
            {description = "50", data = 50, hover = "Same as pigs, merms, and pet lavae."},
            {description = "70", data = 70, hover = ""},
            {description = "Default", data = 0, hover = "200 when unmodded"},
        },
        default = 0,
    },
    divider,
    {
        name = "smallbird_deadleader",
        label = "Smallbird Follow on Death",
        hover = "Should smallbirds and smallish tallbirds keep loyalty when player dies?",
        options =
        {
            {description = "Default", data = 0, hover = "Smallbirds and smallish tallbirds will disband on player death."},
            {description = "Keep Loyalty", data = 1, hover = "Smallbirds and smallish tallbirds will remain loyal on player death."},
        },
        default = 0,
    },
    {
        name = "smallbird_mass",
        label = "Smallbird Mass",
        hover = "How difficult follower smallbirds and smallish tallbirds are to push around,\nor push others.",
        options =
        {
            {description = "1", data = 1, hover = "Same as fruit flies, catcoons, and glommer."},
            {description = "Default", data = 0, hover = "10 when unmodded"},
            {description = "30", data = 30, hover = ""},
            {description = "50", data = 50, hover = "Same as pigs, merms, and pet lavae."},
            {description = "70", data = 70, hover = ""},
        },
        default = 0,
    },
    divider,
    {
        name = "follow_ghost",
        label = "Followers Follow Ghost",
        hover = "Should followers follow player ghosts when set to keep loyalty?\n(Set to \"No Follow\" to prevent players from leading armies as a ghost.)",
        options =
        {
            {description = "No Follow", data = 0, hover = "Wait around until player revives. (Doesn't affect pets or Woby.)"},
            {description = "Default", data = 1, hover = "Follow player ghost around."},
        },
        default = 1,
    },
}
