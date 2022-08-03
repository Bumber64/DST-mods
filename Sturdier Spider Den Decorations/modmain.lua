
local _G = GLOBAL
if not _G.TheNet:GetIsServer() then
    return
end

local UpvalueHacker = require("tools/upvaluehacker") --Rezecib's upvalue hacker

local function modprint(s)
    print("[Sturdier Spider Den Decorations] "..s)
end

-------------------------------------------
---------- Find Existing Stuff ------------
-------------------------------------------

local my_IsDefender
local my_SPIDERDEN_TAGS

local function find_upvalues(inst)
    if my_SPIDERDEN_TAGS then
        return
    elseif not my_IsDefender then
        modprint("Upvalue hacking Prefabs.spiderden.fn -> OnHit -> SpawnDefenders for IsDefender...")
        local fn = UpvalueHacker.GetUpvalue(_G.Prefabs.spiderden.fn, "OnHit")
        if fn then
            fn = UpvalueHacker.GetUpvalue(fn, "SpawnDefenders")
            if fn then
                my_IsDefender = UpvalueHacker.GetUpvalue(fn, "IsDefender")
            end
        end
    end

    if not my_IsDefender then
        modprint("IsDefender not found in Prefabs.spiderden.fn -> OnHit -> SpawnDefenders! Using default.")
        my_IsDefender = function(child) return child.prefab == "spider_warrior" end
    end

    if inst.components.combat.onhitfn then
        modprint("Upvalue hacking inst.components.combat.onhitfn for SPIDERDEN_TAGS...")
        my_SPIDERDEN_TAGS = UpvalueHacker.GetUpvalue(inst.components.combat.onhitfn, "SPIDERDEN_TAGS")
    end

    if not my_SPIDERDEN_TAGS then
        modprint("SPIDERDEN_TAGS not found in (".._G.tostring(inst)..")! Using default.")
        my_SPIDERDEN_TAGS = {"spiderden"}
    end
end

-------------------------------------------
------------- Changed Stuff ---------------
-------------------------------------------

local function SpawnDefenders(inst, attacker) --modified from prefabs/spider.lua
    if not inst.components.health:IsDead() then
        inst.SoundEmitter:PlaySound("dontstarve/creatures/spider/spiderLair_hit")

        if inst.components.childspawner ~= nil then
            local max_release_per_stage = { 2, 4, 6 }
            local num_to_release = math.min(max_release_per_stage[inst.data.stage] or 1, inst.components.childspawner.childreninside)
            local num_warriors = math.min(num_to_release, TUNING.SPIDERDEN_WARRIORS[inst.data.stage])

            num_to_release = math.floor(_G.SpringCombatMod(num_to_release))
            num_warriors = math.floor(_G.SpringCombatMod(num_warriors))
            num_warriors = num_warriors - inst.components.childspawner:CountChildrenOutside(my_IsDefender)

            for k = 1, num_to_release do
                inst.components.childspawner.childname =
                            (TUNING.SPAWN_SPIDER_WARRIORS and k <= num_warriors and not inst:HasTag("bedazzled")) and
                            "spider_warrior" or "spider"

                local spider = inst.components.childspawner:SpawnChild()
                if spider ~= nil and attacker ~= nil and spider.components.combat ~= nil then
                    spider.components.combat:SetTarget(attacker)
                    spider.components.combat:BlankOutAttacks(1.5 + math.random() * 2)
                end
            end

            inst.components.childspawner.childname = "spider"
            if not inst:HasTag("bedazzled") then
                inst.AnimState:PlayAnimation(inst.anims.hit_combat) --moved this here because bedazzled shows decorations falling off
                inst.AnimState:PushAnimation(inst.anims.idle)

                local emergencyspider = inst.components.childspawner:TrySpawnEmergencyChild()
                if emergencyspider ~= nil then
                    emergencyspider.components.combat:SetTarget(attacker)
                    emergencyspider.components.combat:BlankOutAttacks(1.5 + math.random() * 2)
                end
            end
        end
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
        SpawnDefenders(den, attacker)
    end
end

-------------------------------------------
---------------- Finally ------------------
-------------------------------------------

for _, v in pairs({"spider", "spider_warrior", "spider_hider", "spider_spitter", "spider_dropper", "spider_moon", "spider_healer", "spider_water"}) do
    AddPrefabPostInit(v, function(inst)
        find_upvalues(inst)
        inst.components.combat:SetOnHit(SummonFriends)
    end)
end
