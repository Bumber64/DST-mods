
local _G = GLOBAL
if not _G.TheNet:GetIsServer() then
    return
end

local UpvalueHacker = require("tools/upvaluehacker") --Rezecib's upvalue hacker

local function modprint(s)
    print("[Don't Fumble] "..s)
end

local function modassert(v, s)
    if not v then
        _G.error("[Don't Fumble] "..s)
    end
    return v
end

-------------------------------------------
---------------- Settings -----------------
-------------------------------------------
local ts = _G.tostring --DEBUG
local sf = string.format --DEBUG

local cfg =
{
    ALL_NOFUMBLE = 0, --0:Default, 1:stronggrip
    BEARGER_NOFUMBLE = 0, --0:Default, 1:NoFumble
    BEARGER_NOSMASH = 0, --0:Default, 1:Containers, 2:CalmWalk, 3:Beehives
    BEARGER_NOSTEAL = 0, --0:Default, 1:Containers, 2:Structures, 3:Pickables
    MOOSE_NOFUMBLE = 0, --0:Default, 1:NoFumble
    WET_NOFUMBLE = 0, --0:Default, 1:Tool, 2:Drown
}

--Watch: brains/beargerbrain.lua; components/drownable.lua; prefabs/bearger.lua, player_common.lua; stategraph/SGmoose.lua

-------------------------------------------
----------------- Players -----------------
-------------------------------------------

if cfg.ALL_NOFUMBLE > 0 then
    cfg.BEARGER_NOFUMBLE = 0
    cfg.MOOSE_NOFUMBLE = 0

    AddPlayerPostInit(function(inst)
        inst:AddTag("stronggrip")
    end)
end

if cfg.WET_NOFUMBLE > 0 then
    local function hack_DropWetTool(inst) --remove DropWetTool (prefabs/player_common.lua)
        modprint("Upvalue hacking (".._G.tostring(inst)..") for DropWetTool")
        local t = inst.event_listening.onattackother
        t = t and t[inst] or nil --all listeners where player is listening to themself attack others

        if not t then
            modprint("Player isn't listening for their own \"onattackother\" events!")
            return
        end

        local DWT_INDEX = 1 --DropWetTool should be at this index in OnAttackOther, don't search entire function
        for _, fn in ipairs(t) do
            local name, val = _G.debug.getupvalue(fn, DWT_INDEX)
            if name and name == "DropWetTool" then
                inst:RemoveEventCallback("working", val) --remove working listener for DropWetTool
                _G.debug.setupvalue(fn, DWT_INDEX, function(inst, data) end) --replace with empty function in OnAttackOther
                return
            end
        end
        modprint("Couldn't find DropWetTool in player's \"onattackother\" listeners!")
    end

    local function OnFallInOcean(self, shore_x, shore_y, shore_z) --don't drop hand equipment or active item
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

        if cfg.WET_NOFUMBLE > 1 and inst.components.drownable then
            local d = inst.components.drownable
            d.shoulddropitemsfn = function(inst) return false end --don't drop half of items
            d.OnFallInOcean = OnFallInOcean --don't drop hand equipment or active item
        end
    end)
end

-------------------------------------------
----------------- Bearger -----------------
-------------------------------------------

if cfg.BEARGER_NOFUMBLE > 0 or cfg.BEARGER_NOSMASH > 1 then
    local my_OnDestroyOther

    local ANGRYWALK_SQ = TUNING.BEARGER_ANGRY_WALK_SPEED * TUNING.BEARGER_ANGRY_WALK_SPEED - 0.01
    local function OnCollide(inst, other) --don't trample stuff except trees and boulders while not angry
        if other and other:IsValid() and
            other.components.workable and
            other.components.workable:CanBeWorked() and
            other.components.workable.action ~= _G.ACTIONS.NET then
                local speed_sq = _G.Vector3(inst.Physics:GetVelocity()):LengthSq()
                if speed_sq >= 1 and (speed_sq >= ANGRYWALK_SQ or other:HasTag("tree") or other:HasTag("boulder")) and
                    not inst.recentlycharged[other] then
                        inst:DoTaskInTime(2*_G.FRAMES, my_OnDestroyOther, other)
                end
        end
    end

    AddPrefabPostInit("bearger", function(inst)
        if cfg.BEARGER_NOFUMBLE > 0 then --prevent fumbling from swipe attack
            modprint("Upvalue hacking Prefabs.bearger.fn -> OnHitOther")
            local OnHitOther = UpvalueHacker.GetUpvalue(_G.Prefabs.bearger.fn, "OnHitOther")
            if OnHitOther then
                inst:RemoveEventCallback("onhitother", OnHitOther)
            else
                modprint("Prefabs.bearger.fn -> OnHitOther not found!")
            end
        end

        if cfg.BEARGER_NOSMASH > 1 then --CalmWalk
            if my_OnDestroyOther == nil then
                modprint("Upvalue hacking Prefabs.bearger.fn -> OnCollide -> OnDestroyOther")
                local collide = UpvalueHacker.GetUpvalue(_G.Prefabs.bearger.fn, "OnCollide")
                if collide then
                    my_OnDestroyOther = UpvalueHacker.GetUpvalue(collide, "OnDestroyOther")
                end
                if not my_OnDestroyOther then
                    modprint("Prefabs.bearger.fn -> OnCollide -> OnDestroyOther not found!")
                    my_OnDestroyOther = false --skip future hacking
                end
            end

            if my_OnDestroyOther then
                inst.Physics:SetCollisionCallback(OnCollide)
            else
                modprint("Bearger OnDestroyOther not found. Don't change collision callback.")
            end
        end
    end)
end

if cfg.BEARGER_NOSTEAL > 0 or cfg.BEARGER_NOSMASH > 0 then
    local function hfood_fn(item, inst) --return first honeyed edible or nil
        return item.components.container:FindItem(function(food) return inst.components.eater:CanEat(food) and food:HasTag("honeyed") end)
    end

    local function food_fn(item, inst) --return first edible or nil
        return item.components.container:FindItem(function(food) return inst.components.eater:CanEat(food) end)
    end

    local function chest_fn(item, inst, targets) --handle fridges and chests; return true if isn't either
        if cfg.BEARGER_NOSMASH == 0 then --target container for hammering
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
            else
                return true --move on to backpack check
            end
        else --target an item for stealing from container
            if item:HasTag("fridge") then
                if targets.honeyed_fridge == nil then
                    targets.honeyed_fridge = hfood_fn(item, inst)
                    if targets.honeyed_fridge then
                        targets.fridge = nil
                    elseif targets.fridge == nil then
                        targets.fridge = food_fn(item, inst)
                    end
                end
            elseif item:HasTag("chest") then
                if targets.honeyed_chest == nil then
                    targets.honeyed_chest = hfood_fn(item, inst)
                    if targets.honeyed_chest then
                        targets.chest = nil
                    elseif targets.chest == nil then
                        targets.chest = food_fn(item, inst)
                    end
                end
            else
                return true --move on to backpack check
            end
        end
    end

    local chest_action = cfg.BEARGER_NOSMASH == 0 and _G.ACTIONS.HAMMER or _G.ACTIONS.STEAL

    local SEE_STRUCTURE_DIST = 30 --defaults from beargerbrain.lua
    local NO_TAGS = {"FX", "NOCLICK", "DECOR", "INLIMBO", "burnt"}
    local PICKABLE_FOODS = {berries = true, cave_banana = true, carrot = true, red_cap = true, blue_cap = true, green_cap = true}

    local function StealFoodAction(inst) --limit actions based on config, allow stealing from chests instead of hammering
        if inst.sg:HasStateTag("busy") or (inst.components.inventory and inst.components.inventory:IsFull()) then
            return
        end

        local x, y, z = inst.Transform:GetWorldPosition()
        local ents = _G.TheSim:FindEntities(x, y, z, SEE_STRUCTURE_DIST, nil, NO_TAGS)
        local targets = {}

        for i, item in ipairs(ents) do
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
                    if not item.components.container:IsEmpty() and
                        chest_fn(item, inst, targets) and --handle fridges and chests
                        item:HasTag("backpack") then
                            if targets.honeyed_backpack == nil then
                                targets.honeyed_backpack = hfood_fn(item, inst)
                                if targets.honeyed_backpack then
                                    targets.backpack = nil
                                elseif targets.backpack == nil then
                                    targets.backpack = food_fn(item, inst)
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
            return _G.BufferedAction(inst, targets.stewer, _G.ACTIONS.HARVEST)
        elseif targets.beebox and cfg.BEARGER_NOSTEAL < 2 then
            return _G.BufferedAction(inst, targets.beebox, _G.ACTIONS.HARVEST)
        elseif targets.honeyed_fridge and cfg.BEARGER_NOSTEAL < 1 then
            return _G.BufferedAction(inst, targets.honeyed_fridge, chest_action) --target and action depends on cfg.BEARGER_NOSMASH
        elseif targets.honeyed_chest and cfg.BEARGER_NOSTEAL < 1 then
            return _G.BufferedAction(inst, targets.honeyed_chest, chest_action)
        elseif targets.honeyed_backpack and cfg.BEARGER_NOSTEAL < 1 then
            return _G.BufferedAction(inst, targets.honeyed_backpack, _G.ACTIONS.STEAL)
        elseif targets.harvestable and cfg.BEARGER_NOSTEAL < 2 then
            return _G.BufferedAction(inst, targets.harvestable, _G.ACTIONS.HARVEST)
        elseif targets.mushroom_farm and cfg.BEARGER_NOSTEAL < 2 then
            return _G.BufferedAction(inst, targets.mushroom_farm, _G.ACTIONS.HARVEST)
        elseif targets.fridge and cfg.BEARGER_NOSTEAL < 1 then
            return _G.BufferedAction(inst, targets.fridge, chest_action)
        elseif targets.chest and cfg.BEARGER_NOSTEAL < 1 then
            return _G.BufferedAction(inst, targets.chest, chest_action)
        elseif targets.backpack and cfg.BEARGER_NOSTEAL < 1 then
            return _G.BufferedAction(inst, targets.backpack, _G.ACTIONS.STEAL)
        elseif targets.pickable and cfg.BEARGER_NOSTEAL < 3 then
            return _G.BufferedAction(inst, targets.pickable, _G.ACTIONS.PICK)
        end
    end

    AddBrainPostInit("beargerbrain", function(self) --has 2 DoAction nodes for stealing, 1 for attacking beehives
        local node = self.bt.root.children
        if node[7] and node[7].name == "AttackHive" then --easy way to check node alignment
            if cfg.BEARGER_NOSMASH > 2 then
                node[7].getactionfn = function(inst) end
            end

            if node[6] and node[6].name == "DoAction" then
                node[6].getactionfn = StealFoodAction

                node = node[4]
                if node and node.children then
                    node = node.children[2]
                end
                if node and node.children then
                    node = node.children[2]
                end
                if node and node.name == "DoAction" then
                    node.getactionfn = StealFoodAction
                else
                    modprint("Bearger brain surgery #3 failed!")
                end
            else
                modprint("Bearger brain surgery #2 failed!")
            end
        else
            modprint("Bearger brain surgery #1 failed!")
        end
        node = nil
    end)
end

-------------------------------------------
--------------- Moose/Goose ---------------
-------------------------------------------

if cfg.MOOSE_NOFUMBLE > 0 then
    local function no_disarm(self)
        for _,v in ipairs(self.states.disarm.timeline) do
            if v.time == 15*_G.FRAMES then --disarm fn located here
                v.fn = function(inst) end
                return
            end
        end
        modprint("Failed to find moose/goose disarm fn in SGmoose!")
    end

    AddStategraphPostInit("moose", function(self)
        no_disarm(self)
    end)
end
