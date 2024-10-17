
Assets =
{
    Asset("ATLAS", "images/inventoryimages/spore_moon.xml"),
}

local _G = GLOBAL
if not _G.TheNet:GetIsServer() then
    return
end

local function modprint(s)
    print("[Improved Mushroom Planters] "..s)
end

local HackUtil = require("tools/hackutil")

-------------------------------------------
---------------- Settings -----------------
-------------------------------------------

local cfg_name =
{
    --"max_harvests", --0: default, -1: unlimited
    "easy_fert", --allow regular fertilizers
    "snow_grow", --grow instead of pausing in snow
    "spore_harvest", --wait until player harvests to release
    "moon_ok", --everyone can grow moon shrooms from cap
    "moon_spore", --allow catching and planting lunar spores
}

local cfg = { MAX_HARVESTS = GetModConfigData("max_harvests") }
for _,s in ipairs(cfg_name) do --these are boolean
    cfg[string.upper(s)] = (GetModConfigData(s) == true)
end

cfg_name = nil --don't need table anymore

if cfg.MAX_HARVESTS > 0 then
    TUNING.MUSHROOMFARM_MAX_HARVESTS = cfg.MAX_HARVESTS
end

local fert_values = { livinglog = TUNING.MUSHROOMFARM_MAX_HARVESTS }
if cfg.EASY_FERT then
    local fd = require("prefabs/fertilizer_nutrient_defs").FERTILIZER_DEFS
    for k, v in pairs(fd) do --fertilizers restore harvests by 1/8 of total nutrients
        local sum = v.nutrients[1] + v.nutrients[2] + v.nutrients[3]
        fert_values[k] = math.max(1, sum/8)
    end
end

-------------------------------------------
------ Planter: Find Existing Stuff -------
-------------------------------------------

local levels
local spore_to_cap
local StartGrowing
local old_onsnowcover

local function find_mfarm_upvalues(inst)
    if old_onsnowcover then
        return true --already succeeded
    end

    modprint("Upvalue hacking (".._G.tostring(inst)..") for required values.")
    if not inst.components.trader.onaccept then
        modprint("inst.components.trader.onaccept not defined!")
        return false
    end

    local err_msg
    StartGrowing, err_msg = HackUtil.GetUpvalue(inst.components.trader.onaccept, "StartGrowing")
    if not StartGrowing then
        modprint("inst.components.trader.onaccept"..err_msg)
        return false
    end

    levels, err_msg = HackUtil.GetUpvalue(StartGrowing, "levels")
    if not levels then
        modprint("inst.components.trader.onaccept -> StartGrowing"..err_msg)
        return false
    end

    spore_to_cap, err_msg = HackUtil.GetUpvalue(StartGrowing, "spore_to_cap")
    if spore_to_cap then
        spore_to_cap.spore_moon = "moon_cap" --allow lunar spores to be planted
    else
        modprint("inst.components.trader.onaccept -> StartGrowing"..err_msg)
        return false
    end

    old_onsnowcover, err_msg = HackUtil.GetUpvalue(_G.Prefabs.mushroom_farm.fn, "onsnowcoveredchagned")
    if not old_onsnowcover then
        modprint("Prefabs.mushroom_farm.fn"..err_msg)
        return false
    end

    return true
end

-------------------------------------------
------------- Changed Stuff ---------------
-------------------------------------------

local function my_setlevel(inst, level, dotransition) --accept items when snowy if SNOW_GROW
    if inst:HasTag("burnt") then
        return
    end
    if inst.anims == nil then
        inst.anims = {}
    end
    if inst.anims.idle == level.idle then
        dotransition = false
    end

    inst.anims.idle = level.idle
    inst.anims.hit = level.hit

    if inst.remainingharvests == 0 then
        inst.anims.idle = "expired"
        inst.components.trader:Enable()
        inst.components.harvestable:SetGrowTime(nil)
        inst.components.workable:SetWorkLeft(1)
    elseif not cfg.SNOW_GROW and _G.TheWorld.state.issnowcovered then
        inst.components.trader:Disable()
    elseif inst.components.harvestable:CanBeHarvested() then
        inst.components.trader:Disable()
    else
        inst.components.trader:Enable()
        inst.components.harvestable:SetGrowTime(nil)
    end

    if dotransition then
        inst.AnimState:PlayAnimation(level.grow)
        inst.AnimState:PushAnimation(inst.anims.idle, false)
        inst.SoundEmitter:PlaySound(level ~= levels[1] and "dontstarve/common/together/mushroomfarm/grow" or
            "dontstarve/common/together/mushroomfarm/spore_grow")
    else
        inst.AnimState:PlayAnimation(inst.anims.idle)
    end
end

local function my_updatelevel(inst, dotransition) --keep growing when snowy if SNOW_GROW, else pause
    if inst:HasTag("burnt") then
        return
    end

    local h = inst.components.harvestable
    if h:CanBeHarvested() then
        if not cfg.SNOW_GROW and _G.TheWorld.state.issnowcovered then
            if h.growtime then
                h:SetGrowTime(nil)
                h:PauseGrowing() --put it on hold instead of rotting
            end
        elseif h.pausetime then
            h:SetGrowTime(h.pausetime)
            h:StartGrowing()
        end
    else
        h.pausetime = nil --clear this when harvested or ignited
    end

    for k, v in pairs(levels) do
        if h.produce >= v.amount then
            my_setlevel(inst, v, dotransition)
            break
        end
    end
end

local function my_onharvest(inst, picker, produce) --support unlimited harvests
    if inst:HasTag("burnt") then
        return
    elseif cfg.MAX_HARVESTS >= 0 then
        inst.remainingharvests = inst.remainingharvests - 1
    end

    if cfg.SPORE_HARVEST and produce == levels[1].amount then --do spore release here
        if math.random() <= TUNING.MUSHROOMFARM_SPAWN_SPORE_CHANCE then
            for k, v in pairs(spore_to_cap) do
                if v == inst.components.harvestable.product then
                    inst.components.lootdropper:SpawnLootPrefab(k)
                    break
                end
            end
        end
    end

    my_updatelevel(inst)
end

local function my_accepttest(inst, item, giver) --accept items in fert_values, accept moonmushroom if MOON_OK
    if item == nil then
        return false
    elseif inst.remainingharvests == 0 and not fert_values[item.prefab] then --only accepting fertilizer
        return false, "MUSHROOMFARM_NEEDSLOG"
    elseif inst.remainingharvests < TUNING.MUSHROOMFARM_MAX_HARVESTS and fert_values[item.prefab] then --try to accept fertilizer
        return true
    elseif not (item:HasTag("mushroom") or item:HasTag("spore")) then --only mushrooms and spores past this point
        return false, "MUSHROOMFARM_NEEDSSHROOM"
    elseif item:HasTag("moonmushroom") then --check if we grow moon shrooms
        if cfg.MOON_OK then
            return true
        end

        local grower_skilltreeupdater = giver.components.skilltreeupdater
        if grower_skilltreeupdater and grower_skilltreeupdater:IsActivated("wormwood_moon_cap_eating") then
            return true
        else
            return false, "MUSHROOMFARM_NOMOONALLOWED"
        end
    else
        return true
    end
end

local function my_onacceptitem(inst, giver, item) --apply fert value; handle item removal
    if fert_values[item.prefab] then
        inst.remainingharvests = math.min(inst.remainingharvests + fert_values[item.prefab], TUNING.MUSHROOMFARM_MAX_HARVESTS)
        inst.components.workable:SetWorkLeft(3) --local FULLY_REPAIRED_WORKLEFT = 3
        my_updatelevel(inst)
    else
        StartGrowing(inst, giver, item)
    end

    if item.components.fertilizer then
        inst:DoTaskInTime(0, function()
            item.components.fertilizer:OnApplied(giver, inst) --handles finiteuses, etc.
            if not item then
                return --item used up
            elseif giver and giver.components.inventory then
                giver.components.inventory:GiveItem(item) --give item back
            else
                item.Transform:SetPosition(inst.Transform:GetWorldPosition()) --drop it
            end
        end)
    else
        item:Remove()
    end
end

-------------------------------------------
----------------- Finally -----------------
-------------------------------------------

local function my_ongrow(inst, produce) --don't release spores
    my_updatelevel(inst, true)
end

local function my_onsnowcover(inst, covered) --don't rot
    my_updatelevel(inst)
end

AddPrefabPostInit("mushroom_farm", function(inst)
    if not find_mfarm_upvalues(inst) then
        return
    end

    local t = inst.components.harvestable
    if cfg.SPORE_HARVEST then --spores released on harvest instead
        t:SetOnGrowFn(my_ongrow)
    elseif not HackUtil.SetUpvalue(t.ongrowfn, my_updatelevel, "updatelevel") then
        modprint("inst.components.harvestable.ongrowfn -> updatelevel not found!")
    end

    local b = inst.components.burnable
    if b and b.onignite then --someone might remove onignite to protect mushrooms
        if not HackUtil.SetUpvalue(b.onignite, my_updatelevel, "updatelevel") then
            modprint("inst.components.burnable.onignite -> updatelevel not found!")
        end
    end

    if b and b.onextinguish then
        if not HackUtil.SetUpvalue(b.onextinguish, my_updatelevel, "updatelevel") then
            modprint("inst.components.burnable.onextinguish -> updatelevel not found!")
        end
    end

    if not HackUtil.SetUpvalue(inst.OnLoad, my_updatelevel, "updatelevel") then
        modprint("inst.OnLoad -> updatelevel not found!")
    end

    t:SetOnHarvestFn(my_onharvest) --support unlimited harvests, spore release

    t = inst.components.trader
    t.deleteitemonaccept = false --handled in my_onacceptitem
    t:SetAbleToAcceptTest(my_accepttest)
    t.onaccept = my_onacceptitem

    inst:StopWatchingWorldState("issnowcovered", old_onsnowcover)
    inst:WatchWorldState("issnowcovered", my_onsnowcover)
end)

-------------------------------------------
------- Spore: Find Existing Stuff --------
-------------------------------------------

local checkforcrowding
local schedule_testing
local stop_testing

local function find_spore_upvalues(inst)
    if stop_testing then
        return true --already succeeded
    end

    modprint("Upvalue hacking (".._G.tostring(inst)..") for required values.")
    if not inst.OnEntityWake then
        modprint("inst.OnEntityWake not defined!")
        return false
    end

    local err_msg
    checkforcrowding, err_msg = HackUtil.GetUpvalue(_G.Prefabs.spore_moon.fn, "checkforcrowding")
    if not checkforcrowding then
        modprint("Prefabs.spore_moon.fn"..err_msg)
        return false
    end

    schedule_testing, err_msg = HackUtil.GetUpvalue(inst.OnEntityWake, "schedule_testing")
    if not schedule_testing then
        modprint("inst.OnEntityWake"..err_msg)
        return false
    end

    stop_testing, err_msg = HackUtil.GetUpvalue(schedule_testing, "stop_testing")
    if not stop_testing then
        modprint("inst.OnEntityWake -> schedule_testing"..err_msg)
        return false
    end

    return true
end

-------------------------------------------
------------- Changed Stuff ---------------
-------------------------------------------

local function depleted(inst) --explode in inventory
    local holder = inst.components.inventoryitem and inst.components.inventoryitem:GetContainer()
    if holder then --need to drop before exploding
        --holder:DropItem(inst, true) --NOTE: doesn't work for containers, need to do ourself!
        local item = holder:RemoveItem(inst, true)
        if item then
            item.Transform:SetPosition(holder.inst.Transform:GetWorldPosition())
            item.components.inventoryitem:OnDropped()

            item.prevcontainer = nil
            item.prevslot = nil
            holder.inst:PushEvent("dropitem", {item = item})
        else
            inst.Remove() --shadow container, etc.
        end
    else
        stop_testing(inst)

        inst:AddTag("NOCLICK")
        inst.persists = false
        inst.components.workable:SetWorkable(false)
        inst:PushEvent("pop")
        inst:RemoveTag("spore")
        inst:DoTaskInTime(3, inst.Remove)
    end
end

local function onworked(inst, worker) --give item instead of popping
    if worker.components.inventory then
        worker.components.inventory:GiveItem(inst, nil, inst:GetPosition())
        worker.SoundEmitter:PlaySound("dontstarve/common/butterfly_trap")
    end
end

-------------------------------------------
----------------- Finally -----------------
-------------------------------------------

local function onpickup(inst) --same as regular spores, but need to stop testing
    inst.components.perishable:SetLocalMultiplier( TUNING.SEG_TIME*3 / TUNING.PERISH_SLOW )
    stop_testing(inst) --stop looking for targets
    if inst.crowdingtask then
        inst.crowdingtask:Cancel()
        inst.crowdingtask = nil
    end
end

local function ondropped(inst) --same as regular spores, but we need to resume targeting and use transform
    inst.components.perishable:SetLocalMultiplier(1)

    if inst.components.workable then
        inst.components.workable:SetWorkLeft(1)
    end

    if inst.components.stackable then
        while inst.components.stackable:StackSize() > 1 do
            local item = inst.components.stackable:Get()
            if item then
                local x, y, z = inst.Transform:GetWorldPosition() --lunar spore doesn't have physics, need to handle spread ourselves
                x = x + math.random()*2 - 1
                z = z + math.random()*2 - 1
                item.Transform:SetPosition(x, y, z)

                item.components.inventoryitem:OnDropped()
            end
        end
    end

    if inst.components.perishable.perishremainingtime <= 0 then
        depleted(inst) --explode immediately
        return
    elseif not inst.crowdingtask then
        inst.crowdingtask = inst:DoTaskInTime(TUNING.MUSHSPORE_DENSITY_CHECK_TIME +
            math.random()*TUNING.MUSHSPORE_DENSITY_CHECK_VAR, checkforcrowding)
    end
    inst.sg:GoToState("takeoff") --give player time to get away
    schedule_testing(inst) --start looking for targets
end

AddPrefabPostInit("spore_moon", function(inst)
    if not find_spore_upvalues(inst) then
        return
    end
    --we need to support existing inventory spores even if MOON_SPORE is false
    inst:AddTag("show_spoilage")
    inst:AddComponent("tradable")
    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.atlasname = "images/inventoryimages/spore_moon.xml"
    inst.components.inventoryitem.canbepickedup = false

    if cfg.MOON_SPORE then
        inst.components.workable:SetOnFinishCallback(onworked) --collect instead of explode
    end

    inst.components.perishable:SetOnPerishFn(depleted) --drop from inventory and explode

    inst:ListenForEvent("onputininventory", onpickup) --stop proximity testing
    inst:ListenForEvent("ondropped", ondropped) --spread out stack and resume testing

    inst:DoTaskInTime(1, function(inst)
        if inst:IsInLimbo() then
            stop_testing(inst) --undo original prefab's testing if loaded in inventory
        end
    end)
end)
