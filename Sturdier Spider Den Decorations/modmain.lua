
local _G = GLOBAL
if not _G.TheNet:GetIsServer() then
    return
end

local SpringCombatMod = _G.SpringCombatMod

-------------------------------------------
--------------- Spiderden -----------------
-------------------------------------------

local function IsDefender(child) --default from prefabs/spiderden.lua
    return child.prefab == "spider_warrior"
end

local function SpawnDefenders(inst, attacker, do_break) --modified from prefabs/spiderden.lua
    if inst.components.health:IsDead() then
        return
    end

    inst.SoundEmitter:PlaySound("dontstarve/creatures/spider/spiderLair_hit")

    local not_bedazzled = not inst:HasTag("bedazzled")
    if not_bedazzled or do_break then --hit_combat anim on bedazzled shows breaking
        inst.AnimState:PlayAnimation(inst.anims.hit_combat)
        inst.AnimState:PushAnimation(inst.anims.idle)
    end

    if not inst.components.childspawner then
        return
    end

    local max_release_per_stage = {2, 4, 6}
    local num_to_release = math.min(max_release_per_stage[inst.data.stage] or 1, inst.components.childspawner.childreninside)
    local num_warriors = math.min(num_to_release, TUNING.SPIDERDEN_WARRIORS[inst.data.stage])

    num_to_release = math.floor(SpringCombatMod(num_to_release))
    num_warriors = math.floor(SpringCombatMod(num_warriors))
    num_warriors = num_warriors - inst.components.childspawner:CountChildrenOutside(IsDefender)

    for k = 1, num_to_release do
        inst.components.childspawner.childname =
            (TUNING.SPAWN_SPIDER_WARRIORS and k <= num_warriors and not_bedazzled) and
            "spider_warrior" or "spider"

        local spider = inst.components.childspawner:SpawnChild()
        if spider and attacker and spider.components.combat then
            spider.components.combat:SetTarget(attacker)
            spider.components.combat:BlankOutAttacks(1.5 + math.random() * 2)
        end
    end

    inst.components.childspawner.childname = "spider"
    if not_bedazzled then
        local emergencyspider = inst.components.childspawner:TrySpawnEmergencyChild()
        if emergencyspider then
            emergencyspider.components.combat:SetTarget(attacker)
            emergencyspider.components.combat:BlankOutAttacks(1.5 + math.random() * 2)
        end
    end
end

local function OnHit(inst, attacker) --modified from prefabs/spiderden.lua
    local do_break = not (attacker and attacker:HasTag("quakedebris"))

    SpawnDefenders(inst, attacker, do_break)
    if inst.components.sleepingbag then
        inst.components.sleepingbag:DoWakeUp()
    end

    if do_break and inst:HasTag("bedazzled") then
        inst:DoTaskInTime(inst.anims.bedazzle_drop_timing * _G.FRAMES, function() inst.components.bedazzlement:Stop() end)
    end
end

-------------------------------------------
---------------- Spiders ------------------
-------------------------------------------

local SPIDERDEN_TAGS = {"spiderden"} --default from prefabs/spider.lua

local function SummonFriends(inst, attacker) --modified from prefabs/spider.lua
    local radius = (inst.prefab == "spider" or inst.prefab == "spider_warrior") and
        SpringCombatMod(TUNING.SPIDER_SUMMON_WARRIORS_RADIUS) or
        TUNING.SPIDER_SUMMON_WARRIORS_RADIUS

    local den = _G.GetClosestInstWithTag(SPIDERDEN_TAGS, inst, radius)
    if not den or not den.components.combat or not den.components.combat.onhitfn then
        return
    end

    if inst.bedazzled and attacker:HasTag("player") then
        den.components.combat.onhitfn(den, attacker) --break den bedazzlement
    else
        SpawnDefenders(den, attacker)
    end
end

-------------------------------------------
---------------- Finally ------------------
-------------------------------------------

AddPrefabPostInit("spiderden", function(inst)
    inst.components.combat:SetOnHit(OnHit)
end)

for _, v in pairs({"spider", "spider_warrior", "spider_hider", "spider_spitter", "spider_dropper", "spider_moon", "spider_healer", "spider_water"}) do
    AddPrefabPostInit(v, function(inst)
        inst.components.combat:SetOnHit(SummonFriends)
    end)
end
