
local _G = GLOBAL
if not _G.TheNet:GetIsServer() then
    return
end

local UpvalueHacker = require("tools/upvaluehacker") --Rezecib's upvalue hacker

local function modprint(s)
    print("[Sturdier Spider Den Decorations] "..s)
end

local function modassert(v, s)
    _G.assert(v, "[Sturdier Spider Den Decorations] "..s)
end

-------------------------------------------
---------- Find Existing Stuff ------------
-------------------------------------------

local my_SPIDERDEN_TAGS
local my_SpawnDefenders

local function find_upvalues(inst)
    if not my_SpawnDefenders then
        modprint("Upvalue hacking Prefabs.spiderden.fn -> OnHit for SpawnDefenders...")
        my_SpawnDefenders = UpvalueHacker.GetUpvalue(_G.Prefabs.spiderden.fn, "OnHit", "SpawnDefenders")
        modassert(my_SpawnDefenders, "SpawnDefenders not found in Prefabs.spiderden.fn -> OnHit!")
    end

    if my_SPIDERDEN_TAGS then
        return
    elseif inst.components.combat.onhitfn then
        modprint("Upvalue hacking inst.components.combat.onhitfn for SPIDERDEN_TAGS...")
        my_SPIDERDEN_TAGS = UpvalueHacker.GetUpvalue(inst.components.combat.onhitfn, "SPIDERDEN_TAGS")
    end

    if not my_SPIDERDEN_TAGS then
        modprint("SPIDERDEN_TAGS not found in (".._G.tostring(inst)..")! Using default.")
        my_SPIDERDEN_TAGS = {"spiderden"}
    end
end

local function SummonFriends(inst, attacker) --modified from prefabs/spider.lua
    local radius = (inst.prefab == "spider" or inst.prefab == "spider_warrior") and
        _G.SpringCombatMod(TUNING.SPIDER_SUMMON_WARRIORS_RADIUS) or
        TUNING.SPIDER_SUMMON_WARRIORS_RADIUS

    local den = _G.GetClosestInstWithTag(my_SPIDERDEN_TAGS, inst, radius)
    if not den or not den.components.combat or not den.components.combat.onhitfn then
        return
    end

    if inst.bedazzled and attacker:HasTag("player") then
        den.components.combat.onhitfn(den, attacker) --this breaks den bedazzlement
    else
        my_SpawnDefenders(den, attacker)
    end
end

for _, v in pairs({"spider", "spider_warrior", "spider_hider", "spider_spitter", "spider_dropper", "spider_moon", "spider_healer", "spider_water"}) do
    AddPrefabPostInit(v, function(inst)
        find_upvalues(inst)
        inst.components.combat:SetOnHit(SummonFriends)
    end)
end
