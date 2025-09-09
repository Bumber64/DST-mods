
local _G = GLOBAL

PrefabFiles =
{
    "plantmeat_dried",
}

----------------------------------------
------------- Descriptions -------------
----------------------------------------

_G.STRINGS.NAMES.PLANTMEAT_DRIED = "Leaf Jerky"

local char_text = --Reuse speech because I'm not going to write personalities
{
    GENERIC = "MONSTERMEAT_DRIED",
    WILLOW = "LEAFLOAF",
    WOLFGANG = "MONSTERMEAT_DRIED",
    WENDY = "MONSTERMEAT_DRIED",
    WX78 = "MEAT_DRIED",
    WICKERBOTTOM = "LEAFLOAF",
    WOODIE = "MONSTERMEAT_DRIED",
    WAXWELL = "MONSTERMEAT_DRIED",
    WATHGRITHR = "PLANTMEAT_COOKED",
    WEBBER = "MONSTERMEAT_DRIED",
    WARLY = "MONSTERMEAT_DRIED",
    WORMWOOD = "MONSTERMEAT_DRIED",
    WINONA = "LEAFLOAF",
    WORTOX = "MEATYSALAD",
    WURT = "PLANTMEAT_COOKED",
    WALTER = "PLANTMEAT_COOKED",
    WANDA = "LEAFYMEATBURGER",
}
for ch, txt in pairs(char_text) do
    _G.STRINGS.CHARACTERS[ch].DESCRIBE.PLANTMEAT_DRIED = _G.STRINGS.CHARACTERS[ch].DESCRIBE[txt]
end

----------------------------------------
--------------- Recipes ----------------
----------------------------------------

AddIngredientValues({"plantmeat_dried"}, {meat = 1})

local pf = require("preparedfoods")
local recipefns = --Let our leaf jerky satisfy leafy meat requirements
{
    leafloaf = (function(cooker, names, tags)
        return ((names.plantmeat or 0) + (names.plantmeat_cooked or 0) + (names.plantmeat_dried or 0) >= 2)
    end),

    leafymeatburger = (function(cooker, names, tags)
        return (names.plantmeat or names.plantmeat_cooked or names.plantmeat_dried) and
            (names.onion or names.onion_cooked) and
            tags.veggie and tags.veggie >= 2
    end),

    leafymeatsouffle = (function(cooker, names, tags)
    return ((names.plantmeat or 0) + (names.plantmeat_cooked or 0) + (names.plantmeat_dried or 0) >= 2) and
        tags.sweetener and tags.sweetener >= 2
    end),

    meatysalad = (function(cooker, names, tags)
        return (names.plantmeat or names.plantmeat_cooked or names.plantmeat_dried) and
            tags.veggie and tags.veggie >= 3
    end),
}
for k, v in pairs(recipefns) do
    local r = pf[k] --Recipe by name
    r.test = v --Replace the test fn
    AddCookerRecipe("cookpot", r) --Update the recipes
    AddCookerRecipe("portablecookpot", r)
    AddCookerRecipe("archive_cookpot", r)
end

----------------------------------------
------------- Server Stuff -------------
----------------------------------------

if not _G.TheNet:GetIsServer() then
    return
end

AddPrefabPostInit("plantmeat", function(inst)
    inst:AddComponent("dryable")
    inst.components.dryable:SetProduct("plantmeat_dried")
    inst.components.dryable:SetDryTime(_G.TUNING.DRY_FAST)
    --Unused animations already exist for leafy meat. Just add ours for the dried product.
    inst.components.dryable:SetDriedBuildFile("plantmeat_dried")
end)

AddStategraphPostInit("lureplant", function(sg) --Make sure lureplants properly use our animation
    local oldfn = sg.states["showbait"].onenter
    local function my_onenter(inst, playanim)
        if inst.lure and inst.lure.prefab == "plantmeat_dried" then
            inst.AnimState:OverrideSymbol("swap_dried", "plantmeat_dried", "plantmeat_dried")
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("emerge")
        elseif oldfn then
            oldfn(inst, playanim)
        end
    end

    sg.states["showbait"].onenter = my_onenter
end)
