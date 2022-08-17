
local _G = GLOBAL
if not _G.TheNet:GetIsServer() then
    return
end

local TheSim = _G.TheSim
local EQUIPSLOTS = _G.EQUIPSLOTS
local ACTIONS = _G.ACTIONS
local BufferedAction = _G.BufferedAction

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

local cfg = --pmonkey, pmate, SGslurper (hat, compan), cutless
{
    ALL_NOFUMBLE = 0, --0:Default, 1:stronggrip
    BEARGER_NOFUMBLE = 0, --0:Default, 1:NoFumble
    BEARGER_NOSMASH = 0, --0:Default, 1:Containers, 2:CalmWalk, 3:Beehives
    BEARGER_NOSTEAL = 0, --0:Default, 1:Containers, 2:Structures, 3:Pickables
    FROG_PLAYER_NOSTEAL = 0, --0:Default, 1:NoSteal
    FROG_NOSTEAL = 0, --0:Default, 1:Followers, 2:All(lureplant, catcoon)
    MOOSE_NOFUMBLE = 0, --0:Default, 1:NoFumble
    SLURTLE_NOSTEAL = 0, --0:Default, 1:Containers(chester, unworn pack), 2:Players(no attack)
    SPLUMONKEY_CHEST_NOSTEAL = 0, --0:Default, 1:Containers(hutch)
    SPLUMONKEY_NOSTEAL = 0, --0:Default, 1:Misc(drops, targeted), 2:Hats, 3:Pickables, 4:Food
    WET_NOFUMBLE = 0, --0:Default, 1:Tool, 2:Drown(stronggrip active item)
}

--Watch: brains/beargerbrain.lua, monkeybrain.lua, slurtlebrain.lua, slurtlesnailbrain.lua; components/drownable.lua; prefabs/bearger.lua, player_common.lua; stategraph/SGmoose.lua

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
            other.components.workable.action ~= ACTIONS.NET then
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

    local chest_action = cfg.BEARGER_NOSMASH == 0 and ACTIONS.HAMMER or ACTIONS.STEAL

    local SEE_STRUCTURE_DIST = 30 --defaults from beargerbrain.lua
    local NO_TAGS = {"FX", "NOCLICK", "DECOR", "INLIMBO", "burnt"}
    local PICKABLE_FOODS = {berries = true, cave_banana = true, carrot = true, red_cap = true, blue_cap = true, green_cap = true}

    local function StealFoodAction(inst) --limit actions based on config, allow stealing from chests instead of hammering
        if inst.sg:HasStateTag("busy") or (inst.components.inventory and inst.components.inventory:IsFull()) then
            return
        end

        local x, y, z = inst.Transform:GetWorldPosition()
        local ents = TheSim:FindEntities(x, y, z, SEE_STRUCTURE_DIST, nil, NO_TAGS)
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
            return BufferedAction(inst, targets.stewer, ACTIONS.HARVEST)
        elseif targets.beebox and cfg.BEARGER_NOSTEAL < 2 then
            return BufferedAction(inst, targets.beebox, ACTIONS.HARVEST)
        elseif targets.honeyed_fridge and cfg.BEARGER_NOSTEAL < 1 then
            return BufferedAction(inst, targets.honeyed_fridge, chest_action) --target and action depends on cfg.BEARGER_NOSMASH
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
------------------ Frogs ------------------
-------------------------------------------

if cfg.FROG_NOSTEAL > 0 then --0:Default, 1:Players, 2:Followers, 3:All
    local function OnHitOther(inst, other, damage, oldfn)
        if cfg.FROG_NOSTEAL > 2 or other:HasTag("player") then
            return
        elseif cfg.FROG_NOSTEAL == 2 then
            local f = other.components.follower
            if f and f.leader and (f.leader.components.inventoryitem or f.leader:HasTag("player")) then
                return
            end
        end
        oldfn(inst, other, damage)
    end

    AddPrefabPostInit("frog", function(inst)
        local oldhitfn = inst.components.combat.onhitotherfn
        if oldhitfn then
            inst.components.combat.onhitotherfn = function(inst, other, damage)
                OnHitOther(inst, other, damage, oldhitfn)
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

-------------------------------------------
------------- Slurtle/Snurtle -------------
-------------------------------------------

if cfg.SLURTLE_NOSTEAL > 0 then --0:Default, 1:Containers, 2:Players

    local SEE_FOOD_DIST = 13 --defaults from slurtlebrain.lua and slurtlesnailbrain.lua
    local STEALFOOD_CANT_TAGS = {"playerghost", "fire", "burnt", "INLIMBO", "outofreach"}
    local STEALFOOD_ONEOF_TAGS = {"player"} --removed "_container" since we wouldn't be here otherwise

    local function StealFoodAction(inst) --limit targets based on config
        if cfg.SLURTLE_NOSTEAL > 1 or inst.sg:HasStateTag("busy") then
            return
        end

        local x, y, z = inst.Transform:GetWorldPosition()
        local ents = TheSim:FindEntities(x, y, z, SEE_FOOD_DIST, nil, STEALFOOD_CANT_TAGS, STEALFOOD_ONEOF_TAGS)

        for i, v in ipairs(ents) do
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
                        act.validfn = function() return (itemtosteal.components.inventoryitem and itemtosteal.components.inventoryitem:IsHeld()) end
                        act.attack = true
                        return act
                    end
                end
            end
        end
    end

    AddBrainPostInit("slurtlebrain", function(self)
        local node = self.bt.root.children[5]
        if node and node.name == "DoAction" then
            node.getactionfn = StealFoodAction
        else
            modprint("Slurtle brain surgery failed!")
        end
        node = nil
    end)

    AddBrainPostInit("slurtlesnailbrain", function(self)
        local node = self.bt.root.children[5]
        if node and node.name == "DoAction" then
            node.getactionfn = StealFoodAction
        else
            modprint("Snurtle brain surgery failed!")
        end
        node = nil
    end)
end

-------------------------------------------
---------------- Splumonkey ---------------
-------------------------------------------

if cfg.SPLUMONKEY_NOSTEAL > 0 or cfg.SPLUMONKEY_CHEST_NOSTEAL > 0 then

    local SEE_FOOD_DIST = 10 --defaults from monkeybrain.lua
    local TIME_BETWEEN_EATING = 30
    local PICKUP_ONEOF_TAGS = {"_inventoryitem", "pickable", "readyforharvest"}
    local NO_LOOTING_TAGS = {"INLIMBO", "catchable", "fire", "irreplaceable", "heavy", "outofreach", "spider"}
    local NO_PICKUP_TAGS = _G.deepcopy(NO_LOOTING_TAGS)
    table.insert(NO_PICKUP_TAGS, "_container")

    local ValidFoodsToPick = --modified from monkeybrain.lua for efficiency
    {
        berries = true,
        cave_banana = true,
        carrot = true,
        red_cap = true,
        blue_cap = true,
        green_cap = true,
    }

    local function EatFoodAction(inst) --limit targets based on config, streamline function
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
        local ents = TheSim:FindEntities(x, y, z, SEE_FOOD_DIST, nil, NO_PICKUP_TAGS, PICKUP_ONEOF_TAGS)

        local targets = {} --do in one pass like bearger
        local wants_hat = cfg.SPLUMONKEY_NOSTEAL < 2 and inst.components.inventory and not inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HEAD)

        for i, item in ipairs(ents) do
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
                elseif not targets.crop and item.components.crop and item.components.crop:IsReadyForHarvest() then
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

    local ANNOY_ONEOF_TAGS = { "_inventoryitem", "_container" }
    local ANNOY_ALT_MUST_TAG = { "_inventoryitem" }
    local function AnnoyLeader(inst) --limit targets based on config
        if inst.sg:HasStateTag("busy") then
            return
        end

        local lootchests = cfg.SPLUMONKEY_CHEST_NOSTEAL == 0 and inst.canlootchests ~= false
        local px, py, pz = inst.harassplayer.Transform:GetWorldPosition()
        local mx, my, mz = inst.Transform:GetWorldPosition()
        local ents = lootchests and TheSim:FindEntities(mx, 0, mz, 30, nil, NO_LOOTING_TAGS, ANNOY_ONEOF_TAGS) or
            TheSim:FindEntities(mx, 0, mz, 30, ANNOY_ALT_MUST_TAG, NO_PICKUP_TAGS)

        if cfg.SPLUMONKEY_NOSTEAL == 0 then --Misc not protected
            for i, v in ipairs(ents) do --recent drops
                if v.components.inventoryitem and
                    v.components.inventoryitem.canbepickedup and
                    v.components.container == nil and
                    v:GetTimeAlive() < 5 then
                        return BufferedAction(inst, v, ACTIONS.PICKUP)
                end
            end

            local ba = inst.harassplayer:GetBufferedAction()
            if ba and ba.action.id == "PICKUP" then --targeted item
                local tar = ba.target
                if tar and tar:IsValid() and tar.components.inventoryitem and not tar.components.inventoryitem:IsHeld() and
                    tar.components.container == nil and not (tar:HasTag("irreplaceable") or tar:HasTag("heavy") or tar:HasTag("outofreach")) and
                    not (tar.components.burnable and tar.components.burnable:IsBurning()) and
                    not (tar.components.projectile and tar.components.projectile.cancatch and tar.components.projectile.target) then
                        local tx, ty, tz = tar.Transform:GetWorldPosition()
                        return _G.distsq(px, pz, tx, tz) > _G.distsq(mx, mz, tx, tz) and BufferedAction(inst, tar, ACTIONS.PICKUP) or nil
                end
            end
        end

        if lootchests then
            local items = {}
            for i, v in ipairs(ents) do
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

    local function splumonkey_surgery(root)
        if cfg.SPLUMONKEY_NOSTEAL > 0 then
            local node = root.children[7]
            if node and node.children and node.children[1] and node.children[2] and
                node.children[1].name == "Should Eat" and
                node.children[2].name == "DoAction" then
                    node.children[2].getactionfn = EatFoodAction
            else
                modprint("Splumonkey brain surgery #1 failed!")
                return
            end
        end

        local node = root.children[10]
        if node and node.children and node.children[1] and node.children[2] and
            node.children[1].name == "Annoy Leader" and
            node.children[2].name == "DoAction" then
                if cfg.SPLUMONKEY_CHEST_NOSTEAL == 0 or cfg.SPLUMONKEY_NOSTEAL == 0 then
                    node.children[2].getactionfn = AnnoyLeader
                else --no looting chests or stealing misc items
                    node.children[2].getactionfn = function(inst) end
                end
        else
            modprint("Splumonkey brain surgery #2 failed!")
        end
    end

    AddBrainPostInit("monkeybrain", function(self)
        splumonkey_surgery(self.bt.root)
    end)
end
