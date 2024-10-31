
local _G = GLOBAL
if not _G.TheNet:GetIsServer() then
    return
end

local TheSim = _G.TheSim
local ACTIONS = _G.ACTIONS
local EQUIPSLOTS = _G.EQUIPSLOTS
local FOODTYPE = _G.FOODTYPE
local FRAMES = _G.FRAMES
local BufferedAction = _G.BufferedAction
local FindEntity = _G.FindEntity
local Prefabs = _G.Prefabs
local ts = _G.tostring

local function modprint(s)
    print("[Don't Fumble] "..s)
end

local empty_fn = function() end

local function is_player_follower(inst)
    local f = inst.components.follower
    return f and f.leader and (f.leader.components.inventoryitem or f.leader:HasTag("player"))
end

local HackUtil = require("tools/hackutil")

-------------------------------------------
---------------- Settings -----------------
-------------------------------------------

local cfg_name =
{
    "all_nofumble", --0:Default, 1:stronggrip
    "wet_nofumble", --0:Default, 1:Wet, 2:Drown
    "cutless_nosteal", --0:Default, 1:ProtectPlayers, 2:ProtectFollowers, 3:ProtectAll
    "cutless_player", --0:Default, 1:ProtectPlayers, 2:ProtectFollowers, 3:ProtectAll

    "moose_nofumble", --0:Default, 1:NoFumble

    "bearger_nofumble", --0:Default, 1:NoFumble
    "bearger_nosmash", --0:Default, 1:Containers, 2:Trampling, 3:Beehives
    "bearger_nosteal", --0:Default, 1:Containers, 2:Structures, 3:Pickables

    "gdw_nocreature", --0:Default, 1:NoCreature, 2:NoSmall
    "gdw_noitem", --0:Default, 1:NoMisc, 2:NoEdible
    "gdw_noplayer", --0:Default, 1:NoPlayer, 2:NoOther
    "gdw_nosmash", --0:Default, 1:NoSmash

    "icker_nofumble", --0:Default, 1:NoFumble
    "icker_nosteal", --0:Default, 1:Backpack, 2:Armor

    "frog_nosteal", --0:Default, 1:ProtectPlayers, 2:ProtectFollowers, 3:ProtectAll

    "krampus_nochest", --0:Default, 1:NoSmash, 2:Ignore
    "krampus_noexit", --0:Default, 1:NoExit
    "krampus_nosteal", --0:Default, 1:FoodOnly, 2:Ignore

    "marotter_nochest", --0:Default, 1:MeatOnly, 2:Containers
    "marotter_noharvest", --0:Default, 1:NoFish, 2:NoKelp
    "marotter_nosteal", --0:Default, 1:NoPlayer, 2:MeatOnly, 3:JustEat

    "pmonkey_nosmash", --0:Default, 1:Mast, 2:NoEmptyChest, 3:Ignore
    "pmonkey_nosteal", --0:Default, 1:ProtectPlayers, 2:ProtectFollowers, 3:ProtectAll
    "pmonkey_nosteal_ground", --0:Default, 1:NoWearHat, 2:Misc, 3:Bananas

    "slurper_nosteal", --0:Default, 1:Unequip, 2:Protect

    "slurtle_nosteal", --0:Default, 1:Containers, 2:Players

    "splumonkey_nochest", --0:Default, 1:Containers
    "splumonkey_nosteal", --0:Default, 1:Misc, 2:Hats, 3:Pickables, 4:Food
}

local cfg = {}
for _,s in ipairs(cfg_name) do
    local n = GetModConfigData(s)
    cfg[string.upper(s)] = type(n) == "number" and n or 0
end

cfg_name = nil --don't need table anymore

-------------------------------------------
------------------ Debug ------------------
-------------------------------------------

--[[
Fixing misaligned brains:
1. Uncomment variables "_G.brain_exam" and "_G.surgery_table" to enable those functions in console.
2. Run "brain_exam(c_select(), {"fn","getactionfn"})" on desired creature. Brain takes time to start, so don't use "brain_exam(c_spawn("bearger"))".

3. Compare result with the commented "surgery_table" commands located before each surgery table (e.g., "bearger_surgery"), looking for any numbered paths that are wrong.
   Refer to Klei's brain script for the creature (e.g., "/scripts/brains/beargerbrain.lua") for the actual getactionfn names rather than memory addresses.

4. Fix up the numbered paths on the commented commands and run those to generate an updated table.
5. Replace the existing table (e.g., "bearger_surgery") with the printed output in the log.
--]]

--_G.surgery_table = HackUtil.surgery_table
--_G.brain_exam = HackUtil.brain_exam

-------------------------------------------
----------------- General -----------------
-------------------------------------------

if cfg.ALL_NOFUMBLE > 0 then
    cfg.BEARGER_NOFUMBLE = 0 --skip hacking
    cfg.MOOSE_NOFUMBLE = 0
    cfg.ICKER_NOFUMBLE = 0

    AddPlayerPostInit(function(inst)
        inst:AddTag("stronggrip")
    end)
end

if cfg.WET_NOFUMBLE > 0 then
    local function hack_DropWetTool(inst) --remove DropWetTool (prefabs/player_common.lua)
        modprint("Upvalue hacking ("..ts(inst)..") for \"DropWetTool\".")
        local t = inst.event_listening.onattackother
        t = t and t[inst] or nil --all listeners where player is listening to themself attack others

        if not t then
            modprint("Player isn't listening for their own \"onattackother\" events!")
            return
        end

        local DWT_INDEX = 1 --DropWetTool should be at this index in OnAttackOther, don't search entire fns
        for _,fn in ipairs(t) do
            local name, val = _G.debug.getupvalue(fn, DWT_INDEX)
            if name and name == "DropWetTool" then
                inst:RemoveEventCallback("working", val) --remove working listener for DropWetTool
                _G.debug.setupvalue(fn, DWT_INDEX, empty_fn) --replace with empty function in OnAttackOther
                return
            end
        end
        modprint("Couldn't find DropWetTool in player's \"onattackother\" listeners!")
    end

    local function my_OnFallInOcean(self, shore_x, shore_y, shore_z) --don't drop hand equipment or active item
        self.src_x, self.src_y, self.src_z = self.inst.Transform:GetWorldPosition()

        if shore_x == nil then
            shore_x, shore_y, shore_z = _G.FindRandomPointOnShoreFromOcean(self.src_x, self.src_y, self.src_z)
        end

        self.dest_x, self.dest_y, self.dest_z = shore_x, shore_y, shore_z

        if self.inst.components.sleeper then
            self.inst.components.sleeper:WakeUp()
        end
    end

    AddPlayerPostInit(function(inst)
        if cfg.ALL_NOFUMBLE == 0 then
            hack_DropWetTool(inst)
        end

        local d = inst.components.drownable
        if d and cfg.WET_NOFUMBLE > 1 then --need to protect active cursor item regardless of stronggrip
            d.shoulddropitemsfn = empty_fn --don't drop half of items
            d.OnFallInOcean = my_OnFallInOcean --don't drop hand equipment or active item
        end
    end)
end

if cfg.CUTLESS_NOSTEAL > 0 or cfg.CUTLESS_PLAYER > 0 then --0:Default, 1:ProtectPlayers, 2:ProtectFollowers, 3:ProtectAll
    local function my_OnAttack(oldfn, inst, attacker, target)
        local nosteal_level = attacker:HasTag("player") and cfg.CUTLESS_PLAYER or cfg.CUTLESS_NOSTEAL

        if not (nosteal_level > 2 or
            (nosteal_level > 0 and target:HasTag("player")) or
            (nosteal_level > 1 and is_player_follower(target))) then

            oldfn(inst, attacker, target)
        end
    end

    AddPrefabPostInit("cutless", function(inst)
        local oldattackfn = inst.components.weapon.onattack
        if oldattackfn then
            inst.components.weapon.onattack = function(inst, attacker, target)
                my_OnAttack(oldattackfn, inst, attacker, target)
            end
        end
    end)
end

-------------------------------------------
--------------- Moose/Goose ---------------
-------------------------------------------

if cfg.MOOSE_NOFUMBLE > 0 then
    local function no_disarm(self)
        for _,v in ipairs(self.states.disarm.timeline) do
            if v.time == 15*FRAMES then --disarm fn located here
                v.fn = empty_fn
                return
            end
        end
        modprint("Failed to find moose/goose disarm fn in SGmoose!")
    end

    AddStategraphPostInit("moose", function(self)
        no_disarm(self)
    end)
end

-------------------------------------------
----------------- Bearger -----------------
-------------------------------------------

if cfg.BEARGER_NOFUMBLE > 0 or cfg.BEARGER_NOSMASH > 1 then
    local OnHitOther
    local OnDestroyOther
    local hack_success --complete success, don't try again

    --square of the speed used by SGbearger when aggroed, subtract a little to make it less finicky
    local ANGRYWALK_SQ = TUNING.BEARGER_ANGRY_WALK_SPEED * TUNING.BEARGER_ANGRY_WALK_SPEED - 0.01
    local function my_OnCollide(inst, other) --don't trample stuff except trees and boulders while not angry
        if other and other:IsValid() and
            other.components.workable and
            other.components.workable:CanBeWorked() and
            other.components.workable.action ~= ACTIONS.NET then

            local speed_sq = _G.Vector3(inst.Physics:GetVelocity()):LengthSq()
            if speed_sq >= 1 and (speed_sq >= ANGRYWALK_SQ or other:HasTag("tree") or other:HasTag("boulder")) and
                not inst.recentlycharged[other] then

                inst:DoTaskInTime(2*FRAMES, OnDestroyOther, other)
            end
        end
    end

    local function find_bearger_upvalues(inst) --lunar uses same bearger fns
        if hack_success then
            return true --already succeeded
        end

        modprint("Upvalue hacking ("..ts(inst)..") for required values.")
        local commonfn, err_msg = HackUtil.GetUpvalue(Prefabs.bearger.fn, "commonfn")
        if not commonfn then
            modprint("Prefabs.bearger.fn"..err_msg)
            return false
        end

        hack_success = nil --clear any previous false
        if cfg.BEARGER_NOFUMBLE > 0 then
            OnHitOther, err_msg = HackUtil.GetUpvalue(my_commonfn, "OnHitOther")
            if not OnHitOther then
                modprint("Prefabs.bearger.fn -> commonfn"..err_msg)
                hack_success = false
            end
        end

        if cfg.BEARGER_NOSMASH > 1 then --Trampling
            OnDestroyOther, err_msg = HackUtil.GetUpvalue(my_commonfn, "OnCollide", "OnDestroyOther")
            if not OnDestroyOther then
                modprint("Prefabs.bearger.fn -> commonfn"..err_msg)
                hack_success = false
            end
        end

        hack_success = hack_success ~= false --didn't fail required
        return hack_success
    end

    for _,v in pairs({"bearger", "mutatedbearger"}) do
        AddPrefabPostInit(v, function(inst)
            find_bearger_upvalues(inst) --we'll accept partial success

            if OnHitOther then --prevent fumbling from swipe attack
                inst:RemoveEventCallback("onhitother", OnHitOther)
            end

            if OnDestroyOther then --prevent trampling
                inst.Physics:SetCollisionCallback(my_OnCollide)
            end
        end)
    end
end

if cfg.BEARGER_NOSTEAL > 0 or cfg.BEARGER_NOSMASH > 0 then
    local chest_action --correct action for config
    if cfg.BEARGER_NOSMASH == 0 then
        chest_action = ACTIONS.HAMMER
    else
        chest_action = ACTIONS.EMPTY_CONTAINER
        AddStategraphActionHandler("bearger", _G.ActionHandler(ACTIONS.EMPTY_CONTAINER, "steal"))
    end

    local function hfood_fn(item, inst) --return first honeyed edible or nil
        return item.components.container:FindItem(function(food) return inst.components.eater:CanEat(food) and food:HasTag("honeyed") end)
    end

    local function food_fn(item, inst) --return first edible or nil
        return item.components.container:FindItem(function(food) return inst.components.eater:CanEat(food) end)
    end

    local SEE_STRUCTURE_DIST = 30 --defaults from beargerbrain.lua
    local NO_TAGS = {"FX", "NOCLICK", "DECOR", "INLIMBO", "burnt", "outofreach" }
    local PICKABLE_FOODS = {berries = true, cave_banana = true, carrot = true, red_cap = true, blue_cap = true, green_cap = true}

    local function my_StealFoodAction(inst) --limit actions based on config, allow stealing from chests instead of hammering
        if inst.sg:HasStateTag("busy") or inst.components.inventory == nil or inst.components.inventory:IsFull()then
            return
        end

        local x, y, z = inst.Transform:GetWorldPosition()
        local ents = TheSim:FindEntities(x, y, z, SEE_STRUCTURE_DIST, nil, NO_TAGS)
        local targets = {}

        for _,item in ipairs(ents) do
            if item:IsValid() and item:IsOnValidGround() then
                if item.components.stewer then
                    if targets.stewer == nil and item.components.stewer:IsDone() then
                        targets.stewer = item
                    end
                elseif item.components.dryer then
                    if targets.harvestable == nil and item.components.dryer:IsDone() then
                        targets.harvestable = item
                    end
                elseif item.components.crop then
                    if targets.harvestable == nil and item.components.crop:IsReadyForHarvest() then
                        targets.harvestable = item
                    end
                elseif item:HasTag("beebox") then
                    if targets.beebox == nil and item.components.harvestable and item.components.harvestable:CanBeHarvested() then
                        targets.beebox = item
                    end
                elseif item:HasTag("mushroom_farm") then
                    if targets.mushroom_farm == nil and item.components.harvestable and item.components.harvestable:CanBeHarvested() then
                        targets.mushroom_farm = item
                    end
                elseif item.components.container then
                    if not item.components.container:IsEmpty() then
                        if item:HasTag("fridge") and item.components.workable then
                            if targets.honeyed_fridge == nil then
                                if hfood_fn(item, inst) then
                                    targets.honeyed_fridge = item
                                    targets.fridge = nil
                                elseif food_fn(item, inst) then
                                    targets.fridge = item
                                end
                            end
                        elseif item:HasTag("chest") and item.components.workable then
                            if targets.honeyed_chest == nil then
                                if hfood_fn(item, inst) then
                                    targets.honeyed_chest = item
                                    targets.chest = nil
                                elseif food_fn(item, inst) then
                                    targets.chest = item
                                end
                            end
                        elseif item:HasTag("backpack") then
                            if targets.honeyed_backpack == nil then
                                targets.honeyed_backpack = hfood_fn(item, inst)
                                if targets.honeyed_backpack then
                                    targets.backpack = nil
                                elseif targets.backpack == nil then
                                    targets.backpack = food_fn(item, inst)
                                end
                            end
                        end
                    end
                elseif item.components.pickable then
                    if targets.pickable == nil and item.components.pickable.caninteractwith and
                        item.components.pickable:CanBePicked() and PICKABLE_FOODS[item.components.pickable.product] then
                            targets.pickable = item
                    end
                end
            end
        end

        if targets.stewer and cfg.BEARGER_NOSTEAL < 2 then --0:Default, 1:Containers, 2:Structures, 3:Pickables
            return BufferedAction(inst, targets.stewer, ACTIONS.HARVEST)
        elseif targets.beebox and cfg.BEARGER_NOSTEAL < 2 then
            return BufferedAction(inst, targets.beebox, ACTIONS.HARVEST)
        elseif targets.honeyed_fridge and cfg.BEARGER_NOSTEAL < 1 then
            return BufferedAction(inst, targets.honeyed_fridge, chest_action)
        elseif targets.honeyed_chest and cfg.BEARGER_NOSTEAL < 1 then
            return BufferedAction(inst, targets.honeyed_chest, chest_action)
        elseif targets.honeyed_backpack and cfg.BEARGER_NOSTEAL < 1 then
            return BufferedAction(inst, targets.honeyed_backpack, ACTIONS.STEAL)
        elseif targets.harvestable and cfg.BEARGER_NOSTEAL < 2 then
            return BufferedAction(inst, targets.harvestable, ACTIONS.HARVEST)
        elseif targets.mushroom_farm and cfg.BEARGER_NOSTEAL < 2 then
            return BufferedAction(inst, targets.mushroom_farm, ACTIONS.HARVEST)
        elseif targets.fridge and cfg.BEARGER_NOSTEAL < 1 then
            return BufferedAction(inst, targets.fridge, chest_action)
        elseif targets.chest and cfg.BEARGER_NOSTEAL < 1 then
            return BufferedAction(inst, targets.chest, chest_action)
        elseif targets.backpack and cfg.BEARGER_NOSTEAL < 1 then
            return BufferedAction(inst, targets.backpack, ACTIONS.STEAL)
        elseif targets.pickable and cfg.BEARGER_NOSTEAL < 3 then
            return BufferedAction(inst, targets.pickable, ACTIONS.PICK)
        end
    end

    --surgery_table(c_select(), {{1,2,4,2,2,"getactionfn = my_StealFoodAction"}, {1,2,6,"getactionfn = my_StealFoodAction"}, {1,2,7,"getactionfn = empty_fn, cond = function() return cfg.BEARGER_NOSMASH > 2 end"}})
    local bearger_surgery =
    {name = "Priority", child =
        {num = 1, name = "Parallel", child =
            {num = 2, name = "Priority", children =
                {{num = 4, name = "Parallel", child =
                    {num = 2, name = "Priority", child =
                        {num = 2, name = "DoAction", getactionfn = my_StealFoodAction}
                    }
                },
                {num = 6, name = "DoAction", getactionfn = my_StealFoodAction},
                {num = 7, name = "AttackHive", getactionfn = empty_fn, cond = function() return cfg.BEARGER_NOSMASH > 2 end}}
            }
        }
    }

    AddBrainPostInit("beargerbrain", function(self)
        local err_msg = HackUtil.perform_surgery(self.bt.root, bearger_surgery)
        if err_msg then
            modprint("Error ("..ts(self.inst).."): "..err_msg)
        end
    end)
end

-------------------------------------------
------------ Great Depths Worm ------------
-------------------------------------------

if cfg.GDW_NOSMASH > 0 then
    AddPrefabPostInit("worm_boss_dirt", function(inst)
        if inst.components.groundpounder then
            inst.components.groundpounder.destroyer = false
        end
    end)
end

if cfg.GDW_NOCREATURE > 0 or cfg.GDW_NOPLAYER > 0 or cfg.GDW_NOITEM > 0 then
    local WORMBOSS_UTILS = require("prefabs/worm_boss_util")
    local SpDamageUtil = require("components/spdamageutil")

    local OnThingExitDevouredState
    local TransferCreatureInventory

    local function combine_hits(attacker, target) --instant 40 hits of damage
        local dmg, spdmg = attacker.components.combat:CalcDamage(target)
        if spdmg then --in case of planar damage
            spdmg = SpDamageUtil.ApplyMult(spdmg, 40)
        end
        target.components.combat:GetAttacked(attacker, dmg*40, nil, nil, spdmg)
    end

    local function undo_nonlethal(inst) --allow target to be killed
        if inst and inst.components.health then
            inst.components.health:SetMinHealth(0)
        end
    end

    --defaults from worm_boss_util.lua
    local FOOD_CANT_TAGS = { "INLIMBO", "NOCLICK", "FX", "DECOR", "largecreature", "worm_boss_piece", "noattack", "notarget", "playerghost" }
    local FOOD_ONEOF_TAGS = { "_inventoryitem", "character", "smallcreature"}

    local function my_CollectThingsToEat(inst, source) --limit targets by cfg, fix item stack bug
        local pt = source:GetPosition()
        local ents = TheSim:FindEntities(pt.x, 0, pt.z, TUNING.WORM_BOSS_EAT_RANGE, nil, FOOD_CANT_TAGS, FOOD_ONEOF_TAGS)

        if _G.next(ents) == nil then
            return false --empty
        end

        local ate = false
        local calories = 0
        for _,ent in ipairs(ents) do
            local health = ent.components.health
            if not health or not health:IsDead() then --not dead
                if inst.components.combat.target == ent then
                    inst.components.combat:DropTarget()
                end

                if ent.components.inventoryitem and not (health and cfg.GDW_NOCREATURE > 1) then --0:Default, 1:NoCreature, 2:NoSmall; "smallcreature" as item
                    if (cfg.GDW_NOITEM == 0 or (cfg.GDW_NOITEM == 1 and ent.components.edible) or --0:Default, 1:NoMisc, 2:NoEdible; permitted item
                        health or ent:HasTag("irreplaceable")) and --overrule cfg if indestructible or "smallcreature" item
                        not inst.components.inventory:IsFull() then --can fit item

                        if ent.components.edible then
                            local stack = ent.components.stackable and ent.components.stackable.stacksize or 1
                            calories = calories + ent.components.edible.hungervalue * stack --fix ignoring stacked calories
                        end

                        inst.components.inventory:GiveItem(ent)
                        ate = true
                    else --fling or ignore
                        if inst.head then
                            inst.head.components.lootdropper:FlingItem(ent)
                        end
                    end
                else --creature (we've permitted "smallcreature")
                    local was_devoured
                    if ent.sg and not ent.sg:HasStateTag("knockback") and ent:IsValid() and --near enough and not in knockback
                        ent:GetDistanceSqToPoint(pt) < TUNING.WORM_BOSS_EAT_CREATURE_RANGE * TUNING.WORM_BOSS_EAT_CREATURE_RANGE then

                        if inst.devoured == nil then
                            inst.devoured = {}
                        end

                        was_devoured = true --presume ent will be eaten at this point
                        if ent:HasOneOfTags("player", "devourable") then --player, Hutch, etc.
                            local minhealth = health and health.minhealth or nil
                            if minhealth == 0 then
                                health:SetMinHealth(1)
                            end

                            if cfg.GDW_NOPLAYER > 1 or (cfg.GDW_NOPLAYER > 0 and ent:HasTag("player")) then --0:Default, 1:NoPlayer, 2:NoOther
                                --instant 40 hits of nonlethal damage and sanity
                                combine_hits(inst, ent)

                                if minhealth == 0 then --act like OnThingExitDevouredState
                                    if ent.components.oldager then
                                        ent.components.oldager:FastForwardDamageOverTime()
                                    end
                                    ent:DoTaskInTime(27*FRAMES, undo_nonlethal) --protect until knockback done
                                end
                                if ent.components.sanity then
                                    ent.components.sanity:DoDelta(-TUNING.SANITY_SUPERTINY*40)
                                end
                                was_devoured = false --not eaten, no table insert, do knockback
                            else --default devour behaviour
                                ent.sg:HandleEvent("devoured", { attacker = inst, ignoresetcamdist = true })
                                if minhealth == 0 then
                                    ent:ListenForEvent("newstate", OnThingExitDevouredState)
                                end
                                table.insert(inst.devoured, ent)
                            end
                        elseif not ent:HasTag("irreplaceable") then --any killable creature without "devourable"
                            if cfg.GDW_NOCREATURE == 0 then --0:Default, 1:NoCreature, 2:NoSmall
                                TransferCreatureInventory(inst, ent)
                                ent:Remove()
                                table.insert(inst.devoured, { blankfiller = true })
                            else --instant 40 hits of damage
                                combine_hits(inst, ent)

                                if health and health:IsDead() then --dead, act like eaten
                                    if not ent.components.inventoryitem then --only large creatures count
                                        table.insert(inst.devoured, { blankfiller = true })
                                    end
                                else --still alive, do knockback
                                    was_devoured = false
                                end
                            end
                        end --else irreplaceable creature

                        ate = true
                    end --end near enough and not in knockback

                    if not was_devoured then
                        WORMBOSS_UTILS.Knockback(source, ent)
                    end
                end --end item/creature
            end --end not dead
        end --end loop

        if calories > 0 then
            inst.chews = math.min(math.ceil(calories/20),4)
        end
        return ate
    end

    local function do_gdw_hack()
        local old_fn, err_msg = HackUtil.GetUpvalue(WORMBOSS_UTILS.EmergeHead, "CollectThingsToEat")
        if not old_fn then
            modprint("WORMBOSS_UTILS.EmergeHead"..err_msg)
            return
        end

        OnThingExitDevouredState, err_msg = HackUtil.GetUpvalue(old_fn, "OnThingExitDevouredState")
        if not OnThingExitDevouredState then
            modprint("WORMBOSS_UTILS.EmergeHead -> CollectThingsToEat"..err_msg)
            return
        end

        TransferCreatureInventory, err_msg = HackUtil.GetUpvalue(old_fn, "TransferCreatureInventory")
        if not TransferCreatureInventory then
            modprint("WORMBOSS_UTILS.EmergeHead -> CollectThingsToEat"..err_msg)
            return
        end

        if not HackUtil.SetUpvalue(WORMBOSS_UTILS.EmergeHead, my_CollectThingsToEat, "CollectThingsToEat") then
            modprint("WORMBOSS_UTILS.EmergeHead -> CollectThingsToEat not found! (This shouldn't happen!)")
        end

        if not HackUtil.SetUpvalue(WORMBOSS_UTILS.MoveSegmentUnderGround, my_CollectThingsToEat, "CollectThingsToEat") then
            modprint("WORMBOSS_UTILS.MoveSegmentUnderGround -> CollectThingsToEat not found!")
        end
    end

    AddSimPostInit(do_gdw_hack) --modify worm_boss_util
end

-------------------------------------------
------------------ Icker ------------------
-------------------------------------------

if cfg.ICKER_NOFUMBLE > 0 or cfg.ICKER_NOSTEAL > 0 then
    local function my_CollectEquip(item, inst, ret) --protect items based on cfg
        local e = item.components.equippable
        if e.equipslot == EQUIPSLOTS.HANDS then --weapon/tool
            if cfg.ICKER_NOFUMBLE > 0 or inst._suspendedplayer:HasTag("stronggrip") then
                return --can't fumble
            end
        else --wearable; --0:Default, 1:Backpack, 2:Armor
            if cfg.ICKER_NOSTEAL > 1 or (cfg.ICKER_NOSTEAL > 0 and item:HasTag("_container")) then
                return --protected armor or backpack
            end
        end

        if e:ShouldPreventUnequipping() or e:IsRestricted(inst) or item:HasTag("nosteal") then
            return --special item
        end

        table.insert(ret, item)
    end

    AddPrefabPostInit("gelblob", function(inst)
        local scope_fn, err_msg = HackUtil.GetUpvalue(Prefabs.gelblob.fn, "OnSuspendedPlayerDied", "StealSuspendedEquip")
        if not scope_fn then
            modprint("Prefabs.gelblob.fn"..err_msg)
            return
        end

        if not HackUtil.SetUpvalue(scope_fn, my_CollectEquip, "CollectEquip") then
            modprint("Prefabs.gelblob.fn -> OnSuspendedPlayerDied -> StealSuspendedEquip -> CollectEquip not found!")
        end
    end)
end

-------------------------------------------
------------------ Frogs ------------------
-------------------------------------------

if cfg.FROG_NOSTEAL > 0 then --0:Default, 1:ProtectPlayers, 2:ProtectFollowers, 3:ProtectAll
    local function my_OnHitOther(oldfn, inst, other, ...)
        if not (cfg.FROG_NOSTEAL > 2 or
            (cfg.FROG_NOSTEAL > 0 and other:HasTag("player")) or
            (cfg.FROG_NOSTEAL > 1 and is_player_follower(other))) then

            oldfn(inst, other, ...)
        elseif inst.islunar then --just add groginess
            local grog = other.components.grogginess
            if grog and (grog.grog_amount + TUNING.LUNARFROG_ONATTACK_GROGGINESS) < grog:GetResistance() then
                grog:AddGrogginess(TUNING.LUNARFROG_ONATTACK_GROGGINESS)
            end
        end
    end

    for _,v in pairs({"frog", "lunarfrog"}) do
        AddPrefabPostInit(v, function(inst)
            local oldhitfn = inst.components.combat.onhitotherfn
            if oldhitfn then
                inst.components.combat.onhitotherfn = function(inst, other, ...)
                    my_OnHitOther(oldhitfn, inst, other, ...)
                end
            end
        end)
    end
end

-------------------------------------------
----------------- Krampus -----------------
-------------------------------------------

if cfg.KRAMPUS_NOCHEST > 0 or cfg.KRAMPUS_NOEXIT > 0 or cfg.KRAMPUS_NOSTEAL > 0 then
    local chest_action --correct action for config
    if cfg.KRAMPUS_NOCHEST == 1 then --NoSmash
        chest_action = ACTIONS.EMPTY_CONTAINER
        AddStategraphActionHandler("krampus", _G.ActionHandler(ACTIONS.EMPTY_CONTAINER, "hammer"))
    else
        chest_action = ACTIONS.HAMMER --won't be used if set to Ignore
    end

    local function allow_steal(item) --filter item by type
        if cfg.KRAMPUS_NOSTEAL == 0 then
            return true --anything goes
        end

        local e = item.components.edible --krampus prefab suggests he eats meat, we'll also steal candy
        return e and (e.foodtype == FOODTYPE.MEAT or e.foodtype == FOODTYPE.GOODIES)
    end

    local SEE_DIST = 30 --defaults from krampusbrain.lua
    local TOOCLOSE = 6

    local function my_CanSteal(item) --limit targets based on cfg
        return item.components.inventoryitem and
            item.components.inventoryitem.canbepickedup and
            allow_steal(item) and --apply restrictions
            item:IsOnValidGround() and
            not item:IsNearPlayer(TOOCLOSE)
    end

    local STEAL_MUST_TAGS = { "_inventoryitem" }
    local STEAL_CANT_TAGS = { "INLIMBO", "catchable", "fire", "irreplaceable", "heavy", "prey", "bird", "outofreach", "_container" }

    local function my_StealAction(inst) --limit targets based on cfg
        if cfg.KRAMPUS_NOSTEAL > 1 or inst.components.inventory:IsFull() then
            return nil --ignoring all items or inventory full
        end

        local target = FindEntity(inst, SEE_DIST, my_CanSteal, STEAL_MUST_TAGS, STEAL_CANT_TAGS)
        return target and BufferedAction(inst, target, ACTIONS.PICKUP) or nil
    end

    local function CanHammer(item) --from krampusbrain.lua
        return item.prefab == "treasurechest" and
            item.components.container and
            not item.components.container:IsEmpty() and
            not item:IsNearPlayer(TOOCLOSE) and
            item:IsOnValidGround()
    end

    local EMPTYCHEST_MUST_TAGS = { "structure", "_container", "HAMMER_workable" }
    local function my_EmptyChest(inst) --ignore or don't hammer based on cfg
        if cfg.KRAMPUS_NOCHEST > 1 and not inst.components.inventory:IsFull() then
            return nil --ignoring chests or inventory full
        end

        local target = FindEntity(inst, SEE_DIST, CanHammer, EMPTYCHEST_MUST_TAGS)
        return target and BufferedAction(inst, target, chest_action) or nil
    end

    --surgery_table(c_select(), {{3,1,"fn = empty_fn, cond = function() return cfg.KRAMPUS_NOEXIT > 0 end"}, {4,1,1,"getactionfn = my_StealAction"}, {4,1,2,"getactionfn = my_EmptyChest"}})
    local krampus_surgery =
    {name = "Priority", children =
        {{num = 3, name = "Sequence", child =
            {num = 1, name = "donestealing", fn = empty_fn, cond = function() return cfg.KRAMPUS_NOEXIT > 0 end}
        },
        {num = 4, name = "MinPeriod", child =
            {num = 1, name = "Priority", children =
                {{num = 1, name = "steal", getactionfn = my_StealAction},
                {num = 2, name = "emptychest", getactionfn = my_EmptyChest}}
            }
        }}
    }

    AddBrainPostInit("krampusbrain", function(self)
        local err_msg = HackUtil.perform_surgery(self.bt.root, krampus_surgery)
        if err_msg then
            modprint("Error ("..ts(self.inst).."): "..err_msg)
        end
    end)
end

-------------------------------------------
---------------- Marotter -----------------
-------------------------------------------

if cfg.MAROTTER_NOCHEST > 0 or cfg.MAROTTER_NOHARVEST > 0 or cfg.MAROTTER_NOSTEAL > 0 then
    local function GetHomeLocation(inst) --from otterbrain.lua
        local home = (inst.components.homeseeker and inst.components.homeseeker:GetHome()) or nil
        return (home and home:GetPosition()) or inst.components.knownlocations:GetLocation("home")
    end

    local INTERACT_COOLDOWN_NAME = "picked_something_up_recently" --defaults from otterbrain.lua
    local FINDITEMS_CANT_TAGS = { "FX", "INLIMBO", "DECOR", "outofreach" }
    local SEE_ITEM_DISTANCE = 20
    local BOAT_SIZE_SQ = (TUNING.BOAT.GRASS_BOAT.RADIUS * TUNING.BOAT.GRASS_BOAT.RADIUS)

    local function my_FindGroundItemAction(inst) --skip or meat only
        if cfg.MAROTTER_NOSTEAL > 2 or --0:Default, 1:NoPlayer, 2:MeatOnly, 3:JustEat
            inst.sg:HasStateTag("busy") or
            inst.components.timer:TimerExists(INTERACT_COOLDOWN_NAME) then

            return
        end

        local home_position = GetHomeLocation(inst)
        local test_ground_item_for_food = function(item)
            return item:GetTimeAlive() >= 1 and
                item.prefab ~= "mandrake" and
                item.components.edible and
                (cfg.MAROTTER_NOSTEAL < 2 or item.components.edible.foodtype == FOODTYPE.MEAT) and
                item.components.inventoryitem and
                (not home_position or item:GetDistanceSqToPoint(home_position) > BOAT_SIZE_SQ)
        end
        local target = FindEntity(inst, SEE_ITEM_DISTANCE, test_ground_item_for_food, nil, FINDITEMS_CANT_TAGS)
        if not target then return end

        local buffered_action = BufferedAction(inst, target, ACTIONS.PICKUP)

        inst._start_interact_cooldown_callback = inst._start_interact_cooldown_callback or function()
            inst.components.timer:StartTimer(INTERACT_COOLDOWN_NAME, _G.GetRandomWithVariance(5, 2))
        end
        buffered_action:AddSuccessAction(inst._start_interact_cooldown_callback)
        buffered_action.validfn = function()
            return not (target.components.inventoryitem and target.components.inventoryitem:IsHeld())
        end
        return buffered_action
    end

    local CONTAINER_MUST_TAGS = {"_container"} --defaults from otterbrain.lua
    local CONTAINER_CANT_TAGS = { "INLIMBO", "catchable", "fire", "irreplaceable", "heavy", "outofreach", "spider" }
    local STEAL_COOLDOWN_NAME = "steallootcooldown"

    local function my_LootContainerFood(inst) --skip or meat only
        if cfg.MAROTTER_NOCHEST > 1 or --0:Default, 1:MeatOnly, 2:Containers
            inst.sg:HasStateTag("busy") or
            inst.components.timer:TimerExists(STEAL_COOLDOWN_NAME) then

            return
        end

        local ix, iy, iz = inst.Transform:GetWorldPosition()
        local containers = TheSim:FindEntities(
            ix, iy, iz, SEE_ITEM_DISTANCE,
            CONTAINER_MUST_TAGS, CONTAINER_CANT_TAGS)

        local items = {}
        local item_found_count = 0
        for _,container in ipairs(containers) do
            if container.components.container.canbeopened and
                not container.components.container:IsOpen() then

                for k = 1, container.components.container.numslots do
                    local item = container.components.container.slots[k]
                    if item and item.components.edible and
                        item.components.edible.foodtype == FOODTYPE.MEAT and
                        inst.components.eater:CanEat(item) then

                        table.insert(items, item)
                        item_found_count = item_found_count + 1
                    end
                end

                if item_found_count > 20 then
                    break
                end
            end
        end

        if #items == 0 then return end

        local item = items[math.random(#items)]
        local buffered_action = BufferedAction(inst, item, ACTIONS.STEAL)

        buffered_action.validfn = function() --tidied this up a bit
            local owner = item.components.inventoryitem and item.components.inventoryitem.owner or nil
            local c = owner and owner.components.container or nil

            return c and c.canbeopened and not c:IsOpen() and
                not (owner.components.inventoryitem and owner.components.inventoryitem:IsHeld()) and
                not (owner.components.burnable and owner.components.burnable:IsBurning())
        end
        inst._start_steal_cooldown_callback = inst._start_steal_cooldown_callback or function()
            inst.components.timer:StartTimer(STEAL_COOLDOWN_NAME, _G.GetRandomWithVariance(5, 2))
        end
        buffered_action:AddSuccessAction(inst._start_steal_cooldown_callback)
        return buffered_action
    end

    --[[ --won't fit in a single copy-paste, define these two strings first!
    player_str = "getactionfn = empty_fn, cond = function() return cfg.MAROTTER_NOSTEAL > 0 end"
    chest_str = "getactionfn = my_LootContainerFood, cond = function() return cfg.MAROTTER_NOCHEST > 0 end"

    surgery_table(c_select(), {{4,2,3, chest_str}, {4,2,4, player_str}, {7,2,1,"getactionfn = my_FindGroundItemAction, cond = function() return cfg.MAROTTER_NOSTEAL > 1 end"},
        {7,2,2, chest_str}, {7,2,3, player_str}, {7,2,4,1,"fn = empty_fn, cond = function() return cfg.MAROTTER_NOHARVEST > 0 end"},
        {7,2,5,"fn = empty_fn, cond = function() return cfg.MAROTTER_NOHARVEST > 1 end"}})
    --]]
    local otter_surgery =
    {name = "Priority", children =
        {{num = 4, name = "Parallel", child =
            {num = 2, name = "Priority", children =
                {{num = 3, name = "Look For Container Food", getactionfn = my_LootContainerFood, cond = function() return cfg.MAROTTER_NOCHEST > 0 end},
                {num = 4, name = "Look For Character Food", getactionfn = empty_fn, cond = function() return cfg.MAROTTER_NOSTEAL > 0 end}}
            }
        },
        {num = 7, name = "Parallel", child =
            {num = 2, name = "Priority", children =
                {{num = 1, name = "Look For Ground Edibles", getactionfn = my_FindGroundItemAction, cond = function() return cfg.MAROTTER_NOSTEAL > 1 end},
                {num = 2, name = "Look For Container Food", getactionfn = my_LootContainerFood, cond = function() return cfg.MAROTTER_NOCHEST > 0 end},
                {num = 3, name = "Look For Character Food", getactionfn = empty_fn, cond = function() return cfg.MAROTTER_NOSTEAL > 0 end},
                {num = 4, name = "Parallel", child =
                    {num = 1, name = "Try Fishing", fn = empty_fn, cond = function() return cfg.MAROTTER_NOHARVEST > 0 end}
                },
                {num = 5, name = "Harvest Kelp", fn = empty_fn, cond = function() return cfg.MAROTTER_NOHARVEST > 1 end}}
            }
        }}
    }

    AddBrainPostInit("otterbrain", function(self)
        local err_msg = HackUtil.perform_surgery(self.bt.root, otter_surgery)
        if err_msg then
            modprint("Error ("..ts(self.inst).."): "..err_msg)
        end
    end)
end

-------------------------------------------
-------------- Powder Monkey --------------
-------------------------------------------

if cfg.PMONKEY_NOSTEAL_GROUND == 1 then --0:Default, 1:NoWearHat, 2:Misc, 3:Bananas
    local OnPickup

    local function find_pmonkey_upvalues(inst)
        if OnPickup then
            return true --already succeeded
        end

        modprint("Upvalue hacking ("..ts(inst)..") for \"OnPickup\".")
        local err_msg
        OnPickup, err_msg = HackUtil.GetUpvalue(Prefabs.powder_monkey.fn, "OnPickup")
        if not OnPickup then
            modprint("Prefabs.powder_monkey.fn"..err_msg)
            return false
        end

        return true
    end

    AddPrefabPostInit("powder_monkey", function(inst)
        if find_pmonkey_upvalues(inst) then
            inst:RemoveEventCallback("onpickupitem", OnPickup) --don't equip hats that we pick up
        end
    end)
end

if cfg.PMONKEY_NOSMASH > 0 or cfg.PMONKEY_NOSTEAL > 0 or cfg.PMONKEY_NOSTEAL_GROUND > 1 then

    local function reversemastcheck(ent) --from powdermonkeybrain.lua
        return ent.components.mast and ent.components.mast.inverted and
            ent:HasTag("saillowered") and not ent:HasTag("sail_transitioning")
    end

    local function anchorcheck(ent) --from powdermonkeybrain.lua
        return ent.components.anchor and ent:HasTag("anchor_raised") and
            not ent:HasTag("anchor_transitioning")
    end

    local DOTINKER_MUST_HAVE = {"structure"}
    local function my_DoTinker(inst) --limit targets based on config, streamline function
        if cfg.PMONKEY_NOSMASH > 2 or --0:Default, 1:Mast, 2:NoEmptyChest, 3:Ignore
            inst.sg:HasStateTag("busy") or
            inst.components.timer and
            inst.components.timer:TimerExists("reactiondelay") then

            return
        end

        local bc = inst.components.crewmember
        bc = bc and bc.boat and bc.boat.components.boatcrew
        if not bc then
            return
        end

        local x, y, z = inst.Transform:GetWorldPosition()
        local ents = TheSim:FindEntities(x, y, z, 10, DOTINKER_MUST_HAVE)

        for _,ent in ipairs(ents) do
            if anchorcheck(ent) then
                inst.tinkertarget = ent
                bc:reserveinkertarget(ent)
                return BufferedAction(inst, ent, ACTIONS.LOWER_ANCHOR)
            elseif reversemastcheck(ent) then
                inst.tinkertarget = ent
                bc:reserveinkertarget(ent)
                return BufferedAction(inst, ent, ACTIONS.RAISE_SAIL)
            end
        end
    end

    local function pmonkey_targetfn(inst, guy) --who powder monkeys can target for theft
        if not guy.components.inventory or guy.components.inventory:NumItems() == 0 or
            guy:HasTag("monkey") or not inst.components.combat:CanTarget(guy) or
            (cfg.PMONKEY_NOSTEAL > 0 and guy:HasTag("player")) or --0:Default, 1:ProtectPlayers, 2:ProtectFollowers, 3:ProtectAll
            (cfg.PMONKEY_NOSTEAL > 1 and is_player_follower(guy)) then

            return
        end --this fn isn't called when cfg.PMONKEY_NOSTEAL > 2

        local target_ok
        for _,v in pairs(guy.components.inventory.itemslots) do
            if not v:HasTag("nosteal") then
                target_ok = true
                break
            end
        end

        if target_ok then
            local targetplatform = guy:GetCurrentPlatform()
            local instplatform = inst:GetCurrentPlatform()

            if targetplatform and instplatform then
                local radius = targetplatform.components.walkableplatform.platform_radius +
                    instplatform.components.walkableplatform.platform_radius + 4
                return targetplatform:GetDistanceSqToInst(instplatform) <= radius * radius
            end
        end
    end

    local ITEM_MUST = {"_inventoryitem"} --defaults from powdermonkeybrain.lua
    local ITEM_MUSTNOT = {"INLIMBO", "NOCLICK", "knockbackdelayinteraction", "catchable",
        "fire", "minesprung", "mineactive", "spider", "nosteal", "irreplaceable"}
    local RETARGET_MUST_TAGS = {"_combat"}
    local RETARGET_CANT_TAGS = {"playerghost"}
    local RETARGET_ONEOF_TAGS = {"character", "monster"}

    local CHEST_MUST_TAGS = { "chest", "_container" }
    local CHEST_CANT_TAGS = { "outofreach" }

    local function my_ShouldSteal(inst) --limit targets based on config, streamline function
        if inst.sg:HasStateTag("busy") or inst.components.timer:TimerExists("hit") then
            return
        end

        inst.nothingtosteal = nil
        inst.itemtosteal = nil

        if inst.components.inventory:IsFull() or
            inst.components.combat.target and not inst.components.combat:InCooldown() then

            return
        end

        local crewboat = inst.components.crewmember and inst.components.crewmember.boat
        local bc = crewboat and crewboat.components.boatcrew
        local current_platform = inst:GetCurrentPlatform()

        if not (bc and bc.target) and current_platform and current_platform == crewboat then
            return --on own boat and no boat target
        end

        local x, y, z = inst.Transform:GetWorldPosition()

        if cfg.PMONKEY_NOSTEAL_GROUND < 3 then --0:Default, 1:NoWearHat, 2:Misc, 3:Bananas
            local ents = TheSim:FindEntities(x, y, z, 15, ITEM_MUST, ITEM_MUSTNOT)
            for _,ent in ipairs(ents) do
                local inv_item = ent.components.inventoryitem
                if inv_item and inv_item.canbepickedup and inv_item.cangoincontainer and
                    not ent.components.sentientaxe and not inv_item:IsHeld() and not ent:IsOnWater() then

                    if ent.prefab == "cave_banana" or ent.prefab == "cave_banana_cooked" then
                        inst.itemtosteal = ent
                        return BufferedAction(inst, ent, ACTIONS.PICKUP) --steal banana
                    elseif cfg.PMONKEY_NOSTEAL_GROUND < 2 and inst.itemtosteal == nil then
                        inst.itemtosteal = ent --steal this if no banana
                    end
                end
            end
        end

        if inst.itemtosteal then --found misc item and no bananas
            return BufferedAction(inst, inst.itemtosteal, ACTIONS.PICKUP)
        end

        if bc and cfg.PMONKEY_NOSMASH < 2 then --0:Default, 1:Mast, 2:NoEmptyChest, 3:Ignore
            local chests = TheSim:FindEntities(x, y, z, 10, CHEST_MUST_TAGS, CHEST_CANT_TAGS)
            for _,chest in ipairs(chests) do
                if chest.components.container and
                    not chest.components.container:IsEmpty() and
                    not bc:checktinkertarget(chest) then

                    return BufferedAction(inst, chest, ACTIONS.EMPTY_CONTAINER)
                end
            end
        end

        if cfg.PMONKEY_NOSTEAL < 3 then --0:Default, 1:ProtectPlayers, 2:ProtectFollowers, 3:ProtectAll
            if inst.components.combat.target then
                return --don't set nothingtosteal
            end

            local q = _G.TheWorld.components.piratespawner
            q = q and q.queen and q.queen.components.timer
            q = q and q:TimerExists("right_of_passage")

            if not q then
                local target = FindEntity(inst, 10,
                    function(guy) return pmonkey_targetfn(inst, guy) end, --moved target logic to separate fn
                    RETARGET_MUST_TAGS, RETARGET_CANT_TAGS, RETARGET_ONEOF_TAGS)
                if target then
                    return BufferedAction(inst, target, ACTIONS.STEAL)
                end
            end
        end

        inst.nothingtosteal = true
    end

    --surgery_table(c_select(), {{11,"getactionfn = my_DoTinker"}, {14,1,"getactionfn = my_ShouldSteal"}})
    local powder_monkey_surgery =
    {name = "Priority", children =
        {{num = 11, name = "tinker", getactionfn = my_DoTinker},
        {num = 14, name = "ChattyNode", child =
            {num = 1, name = "steal", getactionfn = my_ShouldSteal}
        }}
    }

    AddBrainPostInit("powdermonkeybrain", function(self)
        local err_msg = HackUtil.perform_surgery(self.bt.root, powder_monkey_surgery)
        if err_msg then
            modprint("Error ("..ts(self.inst).."): "..err_msg)
        end
    end)
end

-------------------------------------------
----------------- Slurper -----------------
-------------------------------------------

if cfg.SLURPER_NOSTEAL == 1 then --0:Default, 1:Unequip, 2:Protect
    local function equip_fn(inst)
        local target = inst.components.combat.target
        if target and target:IsValid() and inst:IsNear(target, 2) and
            inst.HatTest and inst:HatTest(target) then

            local oldhat = target.components.inventory:GetEquippedItem(EQUIPSLOTS.HEAD)
            if oldhat then
                if target:HasTag("player") then
                    target.components.inventory:GiveItem(oldhat) --give or drop
                else --don't get stuck in follower inventory
                    target.components.inventory:DropItem(oldhat)
                end
            end
            target.components.inventory:Equip(inst)
        end
    end

    local function no_drop_hat(self)
        for _,v in ipairs(self.states.headslurp.timeline) do
            if v.time == 24*FRAMES then --equip fn located here
                v.fn = equip_fn
                return
            end
        end
        modprint("Failed to find slurper equip fn in SGslurper!")
    end

    AddStategraphPostInit("slurper", function(self)
        no_drop_hat(self)
    end)
elseif cfg.SLURPER_NOSTEAL > 1 then
    local function CanHatTarget(inst, target) --fail if existing hat
        if target and target.components.inventory and
            (target.components.inventory.isopen or
            target:HasTag("pig") or target:HasTag("manrabbit") or target:HasTag("equipmentmodel") or
            (inst._loading and target:HasTag("player"))) then

            return not target.components.inventory:GetEquippedItem(EQUIPSLOTS.HEAD)
        end
        return false
    end

    AddPrefabPostInit("slurper", function(inst)
        inst.HatTest = CanHatTarget
    end)
end

-------------------------------------------
------------- Slurtle/Snurtle -------------
-------------------------------------------

if cfg.SLURTLE_NOSTEAL > 0 then

    local SEE_FOOD_DIST = 13 --defaults from slurtlebrain.lua and slurtlesnailbrain.lua
    local STEALFOOD_CANT_TAGS = {"playerghost", "fire", "burnt", "INLIMBO", "outofreach"}
    local STEALFOOD_ONEOF_TAGS = {"player"} --removed "_container" since we're always protecting chests

    local function my_StealFoodAction(inst) --limit targets based on config
        if cfg.SLURTLE_NOSTEAL > 1 or inst.sg:HasStateTag("busy") then --0:Default, 1:Containers, 2:Players
            return
        end

        local x, y, z = inst.Transform:GetWorldPosition()
        local ents = TheSim:FindEntities(x, y, z, SEE_FOOD_DIST, nil, STEALFOOD_CANT_TAGS, STEALFOOD_ONEOF_TAGS)

        for _,v in ipairs(ents) do
            if not v:HasDebuff("healingsalve_acidbuff") then
                local inv = v.components.inventory
                if inv and v:IsOnValidGround() then
                    local pack = inv:GetEquippedItem(EQUIPSLOTS.BODY)
                    local validfood = {}
                    if pack and pack.components.container then
                        for k = 1, pack.components.container.numslots do
                            local item = pack.components.container.slots[k]
                            if item and item.components.edible and inst.components.eater:CanEat(item) then
                                table.insert(validfood, item)
                            end
                        end
                    end

                    for k = 1, inv.maxslots do
                        local item = inv.itemslots[k]
                        if item and item.components.edible and inst.components.eater:CanEat(item) then
                            table.insert(validfood, item)
                        end
                    end

                    if #validfood > 0 then
                        local itemtosteal = validfood[math.random(1, #validfood)]
                        if itemtosteal then
                            local act = BufferedAction(inst, itemtosteal, ACTIONS.STEAL)
                            act.validfn = function() return (itemtosteal.components.inventoryitem and
                                itemtosteal.components.inventoryitem:IsHeld()) end
                            act.attack = true
                            return act
                        end
                    end
                end
            end
        end
    end

    --surgery_table(c_select(), {{5,"getactionfn = my_StealFoodAction"}})
    local slurtle_surgery =
    {name = "Priority", child =
        {num = 5, name = "DoAction", getactionfn = my_StealFoodAction}
    }

    AddBrainPostInit("slurtlebrain", function(self)
        local err_msg = HackUtil.perform_surgery(self.bt.root, slurtle_surgery)
        if err_msg then
            modprint("Error ("..ts(self.inst).."): "..err_msg)
        end
    end)

    --Reuse table since snurtle's brain layout is almost identical to slurtle's
    AddBrainPostInit("slurtlesnailbrain", function(self)
        local err_msg = HackUtil.perform_surgery(self.bt.root, slurtle_surgery)
        if err_msg then
            modprint("Error ("..ts(self.inst).."): "..err_msg)
        end
    end)
end

-------------------------------------------
---------------- Splumonkey ---------------
-------------------------------------------

if cfg.SPLUMONKEY_NOSTEAL > 0 or cfg.SPLUMONKEY_NOCHEST > 0 then

    local SEE_ITEM_DISTANCE = 10 --defaults from monkeybrain.lua
    local TIME_BETWEEN_EATING = 30
    local PICKUP_ONEOF_TAGS = {"_inventoryitem", "pickable", "readyforharvest"}
    local NO_LOOTING_TAGS = {"INLIMBO", "catchable", "fire", "irreplaceable", "heavy", "outofreach", "spider"}
    local NO_PICKUP_TAGS = _G.deepcopy(NO_LOOTING_TAGS)
    table.insert(NO_PICKUP_TAGS, "_container")

    --modified from monkeybrain.lua, efficient like beargerbrain.lua
    local ValidFoodsToPick = {berries = true, cave_banana = true, carrot = true, red_cap = true, blue_cap = true, green_cap = true}

    local function my_EatFoodAction(inst) --limit targets based on config, streamline function
        if inst.sg:HasStateTag("busy") or
            (inst.components.eater:TimeSinceLastEating() and inst.components.eater:TimeSinceLastEating() < TIME_BETWEEN_EATING) or
            (inst.components.inventory and inst.components.inventory:IsFull()) or
            math.random() < .75 then
                return
        elseif inst.components.inventory and inst.components.eater then --eat from inventory
            local target = inst.components.inventory:FindItem(function(item) return inst.components.eater:CanEat(item) end)
            if target then
                return BufferedAction(inst, target, ACTIONS.EAT)
            end
        end

        if cfg.SPLUMONKEY_NOSTEAL > 3 then
            return --don't acquire new items
        end

        local x, y, z = inst.Transform:GetWorldPosition()
        local ents = TheSim:FindEntities(x, y, z, SEE_ITEM_DISTANCE, nil, NO_PICKUP_TAGS, PICKUP_ONEOF_TAGS)

        local targets = {} --do in one pass like bearger
        local wants_hat = cfg.SPLUMONKEY_NOSTEAL < 2 and inst.components.inventory and
            not inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HEAD)

        for _,item in ipairs(ents) do
            if wants_hat and item.components.equippable and --Hats
                item.components.equippable.equipslot == EQUIPSLOTS.HEAD and
                item.components.inventoryitem and
                item.components.inventoryitem.canbepickedup and
                item:IsOnValidGround() then

                return BufferedAction(inst, item, ACTIONS.PICKUP)
            elseif not targets.food and item:GetTimeAlive() > 8 and --Food
                item.components.inventoryitem and
                item.components.inventoryitem.canbepickedup and
                inst.components.eater:CanEat(item) and
                item:IsOnValidGround() then

                targets.food = item
            elseif cfg.SPLUMONKEY_NOSTEAL < 3 then --Pickables (and pre-RWYS crops)
                if item.components.pickable then
                    if not targets.pickable and item.components.pickable.caninteractwith and
                        item.components.pickable:CanBePicked() and
                        (item.prefab == "worm" or ValidFoodsToPick[item.components.pickable.product]) then

                        targets.pickable = item
                    end
                elseif not targets.crop and item.components.crop and
                    item.components.crop:IsReadyForHarvest() then

                    targets.crop = item
                end
            end
        end

        if targets.food then
            return BufferedAction(inst, targets.food, ACTIONS.PICKUP)
        elseif targets.pickable then
            return BufferedAction(inst, targets.pickable, ACTIONS.PICK)
        elseif targets.crop then
            return BufferedAction(inst, targets.crop, ACTIONS.HARVEST)
        end --never do curious stealing
    end

    local function OnLootingCooldown(inst) --from monkeybrain.lua
        inst._canlootcheststask = nil
        inst.canlootchests = true
    end

    local my_AnnoyLeader = empty_fn --default to empty, replace if below condition true

    if cfg.SPLUMONKEY_NOCHEST == 0 or cfg.SPLUMONKEY_NOSTEAL == 0 then --allow some stealing

        local ANNOY_ONEOF_TAGS = { "_inventoryitem", "_container" } --defaults from monkeybrain.lua
        local ANNOY_ALT_MUST_TAG = { "_inventoryitem" }
        local CANT_PICKUP_TAGS = {"heavy", "irreplaceable", "outofreach"}

        my_AnnoyLeader = function(inst) --limit targets based on config
            if inst.sg:HasStateTag("busy") then
                return
            end

            local lootchests = cfg.SPLUMONKEY_NOCHEST == 0 and inst.canlootchests ~= false
            local px, py, pz = inst.harassplayer.Transform:GetWorldPosition()
            local mx, my, mz = inst.Transform:GetWorldPosition()
            local ents = lootchests and TheSim:FindEntities(mx, 0, mz, 30, nil, NO_LOOTING_TAGS, ANNOY_ONEOF_TAGS) or
                TheSim:FindEntities(mx, 0, mz, 30, ANNOY_ALT_MUST_TAG, NO_PICKUP_TAGS)

            if cfg.SPLUMONKEY_NOSTEAL == 0 then --Misc not protected
                for _,v in ipairs(ents) do --recent drops
                    if v.components.inventoryitem and
                        v.components.inventoryitem.canbepickedup and
                        not v.components.container and
                        v:GetTimeAlive() < 5 then

                        return BufferedAction(inst, v, ACTIONS.PICKUP)
                    end
                end

                local ba = inst.harassplayer:GetBufferedAction()
                if ba and ba.action.id == "PICKUP" then --targeted item
                    local tar = ba.target
                    if tar and tar:IsValid() and tar.components.inventoryitem and not tar.components.inventoryitem:IsHeld() and
                        not tar.components.container and not tar:HasAnyTag(CANT_PICKUP_TAGS) and
                        not (tar.components.burnable and tar.components.burnable:IsBurning()) and
                        not (tar.components.projectile and tar.components.projectile.cancatch and tar.components.projectile.target) then

                        local tx, ty, tz = tar.Transform:GetWorldPosition()
                        return _G.distsq(px, pz, tx, tz) > _G.distsq(mx, mz, tx, tz) and BufferedAction(inst, tar, ACTIONS.PICKUP) or nil
                    end
                end
            end

            if lootchests then
                local items = {}
                for _,v in ipairs(ents) do
                    if v.components.container and
                        v.components.container.canbeopened and
                        not v.components.container:IsOpen() and
                        v:GetDistanceSqToPoint(px, 0, pz) < 225 then

                        for k = 1, v.components.container.numslots do
                            local item = v.components.container.slots[k]
                            if item then
                                table.insert(items, item)
                            end
                        end
                    end
                end

                if #items > 0 then
                    inst.canlootchests = false
                    if inst._canlootcheststask then
                        inst._canlootcheststask:Cancel()
                    end

                    inst._canlootcheststask = inst:DoTaskInTime(math.random(15, 30), OnLootingCooldown)
                    local item = items[math.random(#items)]
                    local act = BufferedAction(inst, item, ACTIONS.STEAL)
                    act.validfn = function()
                        local owner = item.components.inventoryitem and item.components.inventoryitem.owner or nil
                        return owner and
                            not (owner.components.inventoryitem and owner.components.inventoryitem:IsHeld()) and
                            not (owner.components.burnable and owner.components.burnable:IsBurning()) and
                            owner.components.container and owner.components.container.canbeopened and
                            not owner.components.container:IsOpen()
                    end
                    return act
                end
            end
        end
    end

    local function monkeybrain_check(root) --double check some nodes because some look identical in smooth monkey brain
        local node = root.children and root.children[7]
        node = node and node.children and node.children[1]
        node = node and node.name and node.name == "Should Eat"
        if not node then
            return
        end

        node = root.children and root.children[10]
        node = node and node.children and node.children[1]
        node = node and node.name and node.name == "Annoy Leader"
        return node
    end

    --surgery_table(c_select(), {{7,2,"getactionfn = my_EatFoodAction, cond = function() return cfg.SPLUMONKEY_NOSTEAL > 0 end"}, {10,2,"getactionfn = my_AnnoyLeader"}})
    local monkey_surgery =
    {name = "Priority", children =
        {{num = 7, name = "Parallel", child =
            {num = 2, name = "DoAction", getactionfn = my_EatFoodAction, cond = function() return cfg.SPLUMONKEY_NOSTEAL > 0 end}
        },
        {num = 10, name = "Parallel", child =
            {num = 2, name = "DoAction", getactionfn = my_AnnoyLeader}
        }}
    }

    AddBrainPostInit("monkeybrain", function(self)
        if monkeybrain_check(self.bt.root) then
            local err_msg = HackUtil.perform_surgery(self.bt.root, monkey_surgery)
            if err_msg then
                modprint("Error ("..ts(self.inst).."): "..err_msg)
            end
        else
            modprint("Splumonkey brain surgery failed pre-check!")
        end
    end)
end
