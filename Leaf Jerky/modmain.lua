
PrefabFiles =
{
    "plantmeat_dried",
}

local _G = GLOBAL

----------------------------------------
------------- Descriptions -------------
----------------------------------------
local STRINGS = _G.STRINGS
STRINGS.NAMES.PLANTMEAT_DRIED = "Leaf Jerky"

local char_text =
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
    STRINGS.CHARACTERS[ch].DESCRIBE.PLANTMEAT_DRIED = STRINGS.CHARACTERS[ch].DESCRIBE[txt]
end

----------------------------------------
--------------- Recipes ----------------
----------------------------------------
AddIngredientValues({"plantmeat_dried"}, {meat = 1})

local pf = require("preparedfoods")
local recipefns =
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
    local r = pf[k]
    r.test = v
    AddCookerRecipe("cookpot", r)
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
end)

AddPrefabPostInit("meatrack", function(inst)
    local oldfn = inst.components.dryer.ondonedrying
    local function new_ondonedrying(inst, product, buildfile)
        if product == "plantmeat_dried" then
            if _G.POPULATING then
                inst.AnimState:PlayAnimation("idle_full")
            else
                inst.AnimState:PlayAnimation("drying_pst")
                inst.AnimState:PushAnimation("idle_full", false)
            end
            inst.AnimState:OverrideSymbol("swap_dried", "plantmeat_dried", "plantmeat_dried")
        elseif oldfn then
            oldfn(inst, product, buildfile)
        end
    end

    inst.components.dryer:SetDoneDryingFn(new_ondonedrying)
end)

AddStategraphPostInit("lureplant", function(sg)
    local oldfn = sg.states["showbait"].onenter
    local function new_onenter(inst, playanim)
        if inst.lure and inst.lure.prefab == "plantmeat_dried" then
            inst.AnimState:OverrideSymbol("swap_dried", "plantmeat_dried", "plantmeat_dried")
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("emerge")
        elseif oldfn then
            oldfn(inst, playanim)
        end
    end

    sg.states["showbait"].onenter = new_onenter
end)
