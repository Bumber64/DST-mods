
local _G = GLOBAL
if not _G.TheNet:GetIsServer() then
    return
end

local ts = _G.tostring

local function modprint(s)
    print("[Companion Configurator] "..s)
end

local function set_invincible(inst)
    inst.components.health:SetInvincible(true)
end

local HackUtil = require("tools/hackutil")

-------------------------------------------
---------------- Settings -----------------
-------------------------------------------

local cfg_name =
{
    "chester_health", --0:Default, 1:10k, 2:InstantRegen, 3:Invincible
    "chester_notarget", --0:Default, 1:notarget
    "hutch_fridge", --0:Default, 1:fridge
    "shadow_fridge", --0:Default, 1:fridge 2:fridge-no-spoiler
    "chester_mass", --0:Default

    "glommer_health", --0:Default, 1:10k, 2:InstantRegen, 3:Invincible
    "glommer_notarget", --0:Default, 1:notarget
    "glommer_mass", --0:Default

    "polly_health", --0:Default, 1:10k, 2:InstantRegen, 3:Invincible
    "polly_notarget", --0:Default, 1:notarget
    "polly_mass", --0:Default

    "fffly_health", --0:Default, 1:10k, 2:InstantRegen, 3:Invincible
    "fffly_notarget", --0:Default, 1:notarget
    "fffly_nofreeze", --0:Default, 1:Immune
    "fffly_mass", --0:Default

    "lavae_pet_health", --0:Default, 1:10k, 2:InstantRegen, 3:Invincible
    "lavae_pet_notarget", --0:Default, 1:notarget
    "lavae_pet_nofreeze", --0:Default, 1:Protect, 2:Immune
    "lavae_pet_nofire", --0:Default, 1:Prevent
    "lavae_pet_mass", --0:Default

    "beefalo_health", --0:Default, 1:10k, 2:InstantRegen, 3:Invincible
    "beefalo_notarget", --0:Default, 1:notarget
    "beefalo_mass", --0:Default
    "beefalo_ride", --0:Suspend, 1:Enabled

    "spiders_notrap", --0:Default, 1:notraptrigger
    "spiders_deadleader", --0:Default, 1:keepdeadleader
    "spiders_mass", --0:Default

    "pigmermbun_notrap", --0:Default, 1:notraptrigger
    "pigmermbun_loyalty", --0:Default, 1:neverexpire
    "pigmermbun_deadleader", --0:Default, 1:keepdeadleader
    "pigmermbun_mass", --0:Default

    "rocky_loyalty", --0:Default, 1:neverexpire
    "rocky_epicscare", --0:Default, 1:RemainLoyal
    "rocky_deadleader", --0:Default, 1:keepdeadleader
    "rocky_speed", --0:Default
    "rocky_mass", --0:Default

    "smallbird_deadleader", --0:Default, 1:keepdeadleader
    "smallbird_mass", --0:Default

    "follow_ghost", --0:No, 1:Yes
}

local cfg = {}
for _, s in ipairs(cfg_name) do
    local n = GetModConfigData(s)
    cfg[string.upper(s)] = type(n) == "number" and n or 0
end

cfg_name = nil --don't need table anymore

if not _G.GetGameModeProperty("ghost_enabled") then
    cfg.FOLLOW_GHOST = 1 --skip needless code
end

-------------------------------------------
------------------ Debug ------------------
-------------------------------------------

--[[
Fixing misaligned brains:
1. Uncomment variables "_G.brain_exam" and "_G.surgery_table" to enable those functions in console.
2. Run "brain_exam(c_select(), {"target","homepos"})" on desired creature. Brain takes time to start, so don't use "brain_exam(c_spawn("smallbird"))".
3. Compare result with the nodes being modified in existing surgery table (e.g., "smallbird_surgery",) looking for any numbered paths that are wrong.
4. Fix up the numbered paths on the commented "surgery_table" commands located before each surgery table and run those to generate an updated table.
5. Replace the existing table (e.g., "smallbird_surgery") with the output in the log.
--]]

--_G.brain_exam = HackUtil.brain_exam
--_G.surgery_table = HackUtil.surgery_table

----------------------------------------
----------- Chester and Hutch ----------
----------------------------------------

if cfg.SHADOW_FRIDGE > 0 then
    AddPrefabPostInit("shadow_container", function(inst)
        inst:AddTag("fridge")

        if cfg.SHADOW_FRIDGE > 1 then
            inst:RemoveTag("spoiler")
        end
    end)
end

if cfg.CHESTER_HEALTH > 0 or cfg.CHESTER_NOTARGET > 0 or cfg.HUTCH_FRIDGE > 0 or cfg.CHESTER_MASS > 0 then
    AddPrefabPostInit("chester", function(inst)
        if cfg.CHESTER_HEALTH > 0 and inst.components.health then
            inst.components.health:SetMaxHealth(10000)
            if cfg.CHESTER_HEALTH == 2 then
                inst.components.health:StartRegen(10000, 1)
            elseif cfg.CHESTER_HEALTH > 2 then
                inst.components.health:SetInvincible(true)
                inst:ListenForEvent("teleported", set_invincible)
            end
        end

        if cfg.CHESTER_NOTARGET > 0 then
            inst:AddTag("notarget")
            inst.components.locomotor:SetTriggersCreep(false)
        end

        if cfg.CHESTER_MASS > 0 then
            inst.Physics:SetMass(cfg.CHESTER_MASS)
        end
    end)

    AddPrefabPostInit("hutch", function(inst)
        if cfg.CHESTER_HEALTH > 0 and inst.components.health then
            inst.components.health:SetMaxHealth(10000)
            if cfg.CHESTER_HEALTH == 2 then
                inst.components.health:StartRegen(10000, 1)
            elseif cfg.CHESTER_HEALTH > 2 then
                inst.components.health:SetInvincible(true)
                inst:ListenForEvent("teleported", set_invincible)
            end
        end

        if cfg.CHESTER_NOTARGET > 0 then
            inst:AddTag("notarget")
            inst.components.locomotor:SetTriggersCreep(false)
        end

        if cfg.HUTCH_FRIDGE > 0 then
            inst:AddTag("fridge")
        end

        if cfg.CHESTER_MASS > 0 then
            inst.Physics:SetMass(cfg.CHESTER_MASS)
        end
    end)
end

----------------------------------------
---------------- Glommer ---------------
----------------------------------------

if cfg.GLOMMER_HEALTH > 0 or cfg.GLOMMER_NOTARGET > 0 or cfg.GLOMMER_MASS > 0 then
    AddPrefabPostInit("glommer", function(inst)
        if cfg.GLOMMER_HEALTH > 0 and inst.components.health then
            inst.components.health:SetMaxHealth(10000)
            if cfg.GLOMMER_HEALTH == 2 then
                inst.components.health:StartRegen(10000, 1)
            elseif cfg.GLOMMER_HEALTH > 2 then
                inst.components.health:SetInvincible(true)
                inst:ListenForEvent("teleported", set_invincible)
            end
        end

        if cfg.GLOMMER_NOTARGET > 0 then
            inst:AddTag("notarget")
        end

        if cfg.GLOMMER_MASS > 0 then
            inst.Physics:SetMass(cfg.GLOMMER_MASS)
        end
    end)
end

----------------------------------------
------------- Polly Rogers -------------
----------------------------------------

if cfg.POLLY_HEALTH > 0 or cfg.POLLY_NOTARGET > 0 or cfg.POLLY_MASS > 0 then
    AddPrefabPostInit("polly_rogers", function(inst)
        if cfg.POLLY_HEALTH > 0 and inst.components.health then
            inst.components.health:SetMaxHealth(10000)
            if cfg.POLLY_HEALTH == 2 then
                inst.components.health:StartRegen(10000, 1)
            elseif cfg.POLLY_HEALTH > 2 then
                inst.components.health:SetInvincible(true)
                inst:ListenForEvent("teleported", set_invincible)
            end
        end

        if cfg.POLLY_NOTARGET > 0 then
            inst:AddTag("notarget")
        end

        if cfg.POLLY_MASS > 0 then
            inst.Physics:SetMass(cfg.POLLY_MASS)
        end
    end)
end

----------------------------------------
---------- Friendly Fruit Fly ----------
----------------------------------------

if cfg.FFFLY_HEALTH > 0 or cfg.FFFLY_NOTARGET > 0 or cfg.FFFLY_NOFREEZE > 0 or cfg.FFFLY_MASS > 0 then
    AddPrefabPostInit("friendlyfruitfly", function(inst)
        if cfg.FFFLY_HEALTH > 0 and inst.components.health then
            inst.components.health:SetMaxHealth(10000)
            if cfg.FFFLY_HEALTH == 2 then
                inst.components.health:StartRegen(10000, 1)
            elseif cfg.FFFLY_HEALTH > 2 then
                inst.components.health:SetInvincible(true)
                inst:ListenForEvent("teleported", set_invincible)
            end
        end

        if cfg.FFFLY_NOTARGET > 0 then
            inst:AddTag("notarget")
        end

        if cfg.FFFLY_NOFREEZE > 0 then
            inst:RemoveComponent("freezable")
        end

        if cfg.FFFLY_MASS > 0 then
            inst.Physics:SetMass(cfg.FFFLY_MASS)
        end
    end)
end

----------------------------------------
--------- Extra-adorable Lavae ---------
----------------------------------------

if cfg.LAVAE_PET_HEALTH > 0 or cfg.LAVAE_PET_NOTARGET > 0 or cfg.LAVAE_PET_NOFREEZE > 0 or cfg.LAVAE_PET_NOFIRE > 0 or cfg.LAVAE_PET_MASS > 0 then
    AddPrefabPostInit("lavae_pet", function(inst)
        if cfg.LAVAE_PET_HEALTH > 0 and inst.components.health then
            inst.components.health:SetMaxHealth(10000)
            if cfg.LAVAE_PET_HEALTH == 2 then
                inst.components.health:StartRegen(10000, 1)
            elseif cfg.LAVAE_PET_HEALTH > 2 then
                if inst.components.hunger then
                    inst.components.hunger:SetPercent(100) --can't restore hunger with food while invincible
                end
                inst.components.health:SetInvincible(true)
                inst:ListenForEvent("teleported", set_invincible)

                local freezable = inst.components.freezable
                if freezable then
                    local old_onfreezefn = freezable.onfreezefn
                    freezable.onfreezefn = function(inst, ...)
                        inst.components.health:SetInvincible(false)
                        return old_onfreezefn and old_onfreezefn(inst, ...) or nil
                    end
                end
            end
        end

        if cfg.LAVAE_PET_NOTARGET > 0 then
            inst:AddTag("notarget")
            inst.components.locomotor:SetTriggersCreep(false)
        end

        if cfg.LAVAE_PET_NOFREEZE == 1 then --just prevent Freezable:AddColdness from freezing
            for _, v in pairs(inst.sg.sg.states) do
                v.tags["nofreeze"] = true
            end
            inst.sg.tags["nofreeze"] = true
        elseif cfg.LAVAE_PET_NOFREEZE > 1 then
            inst:RemoveComponent("freezable")
        end

        if cfg.LAVAE_PET_NOFIRE > 0 and inst.components.propagator then
            inst.components.propagator:StopSpreading()
        end

        if (cfg.LAVAE_PET_NOFREEZE > 0 or cfg.LAVAE_PET_NOTARGET > 0) and inst.components.trader then
            local old_testfn = inst.components.trader.test
            inst.components.trader:SetAcceptTest(function(inst, item, ...)
                if item.prefab == "icestaff" then
                    if item.components.finiteuses then
                        item.components.finiteuses:Use()
                    end

                    if inst.components.freezable then
                        inst.components.freezable:Freeze()
                    elseif inst.components.lootdropper then
                        inst.components.lootdropper:SpawnLootPrefab("lavae_cocoon")
                    end
                else
                    return old_testfn and old_testfn(inst, item, ...) or nil
                end
            end)
        end

        if cfg.LAVAE_PET_MASS > 0 then
            inst.Physics:SetMass(cfg.LAVAE_PET_MASS)
        end
    end)
end

----------------------------------------
---------------- Beefalo ---------------
----------------------------------------

if cfg.BEEFALO_HEALTH > 0 or cfg.BEEFALO_NOTARGET > 0 or cfg.BEEFALO_MASS > 0 then
    local function beef_enable(inst, enable)
        local c = (cfg.BEEFALO_HEALTH > 0 or cfg.BEEFALO_NOTARGET > 0) and inst.components.combat

        if enable then
            if c then --disable beefalo combat
                c:SetShouldAggroFn(function() end)
                c:DropTarget()
            end

            if cfg.BEEFALO_HEALTH > 0 and inst.components.health then
                inst.components.health:SetMaxHealth(10000)
                if cfg.BEEFALO_HEALTH == 2 then
                    inst.components.health:StartRegen(10000, 1)
                elseif cfg.BEEFALO_HEALTH > 2 then
                    inst.components.health:SetInvincible(true)
                    inst:ListenForEvent("teleported", set_invincible)
                end
            end

            if cfg.BEEFALO_NOTARGET > 0 then
                inst:AddTag("notarget")
            end

            if cfg.BEEFALO_MASS > 0 then
                if not inst._default_mass then
                    inst._default_mass = inst.Physics:GetMass()
                end
                inst.Physics:SetMass(cfg.BEEFALO_MASS)
            end
        else
            if c then --restart beefalo combat
                c:SetShouldAggroFn(nil)
            end

            if cfg.BEEFALO_HEALTH > 0 and inst.components.health then
                inst.components.health:SetMaxHealth(TUNING.BEEFALO_HEALTH)
                if cfg.BEEFALO_HEALTH == 2 then
                    inst.components.health:StartRegen(TUNING.BEEFALO_HEALTH_REGEN, TUNING.BEEFALO_HEALTH_REGEN_PERIOD)
                elseif cfg.BEEFALO_HEALTH > 2 then
                    inst:RemoveEventCallback("teleported", set_invincible)
                    inst.components.health:SetInvincible(false)
                end
            end

            if cfg.BEEFALO_NOTARGET > 0 then
                inst:RemoveTag("notarget")
            end

            if inst._default_mass then
                inst.Physics:SetMass(inst._default_mass)
                inst._default_mass = nil
            end
        end
    end

    local function check_mount(inst, data)
        local new = data.newrider and data.newrider:HasTag("player")
        local old = data.oldrider and data.oldrider:HasTag("player")

        if cfg.BEEFALO_RIDE > 0 then
            if new and (cfg.BEEFALO_HEALTH > 0 or cfg.BEEFALO_NOTARGET > 0) then
                data.newrider.components.combat.redirectdamagefn = nil
            end
        elseif new and not old then
            beef_enable(inst, false)
        elseif old and not new then
            beef_enable(inst, true)
        end
    end

    local function bell_on(inst, bell)
        local r = inst.components.rideable and inst.components.rideable:GetRider()

        if r and r:HasTag("player") then
            if cfg.BEEFALO_RIDE > 0 then
                if cfg.BEEFALO_HEALTH > 0 or cfg.BEEFALO_NOTARGET > 0 then
                    r.components.combat.redirectdamagefn = nil
                end

                beef_enable(inst, true)
            end
        else
            beef_enable(inst, true)
        end

        inst:ListenForEvent("riderchanged", check_mount)
    end

    local function bell_off(inst)
        inst:RemoveEventCallback("riderchanged", check_mount)
        beef_enable(inst, false)
    end

    AddPrefabPostInit("beefalo", function(inst)
        inst:ListenForEvent("startfollowing", bell_on)
        inst:ListenForEvent("stopfollowing", bell_off)
    end)
end

----------------------------------------
------------- Follower fns -------------
----------------------------------------

local function NoHoles(pt)
    return not _G.TheWorld.Map:IsPointNearHole(pt)
end

local function follower_tele(inst, leader_pos) --modified from follower TryPorting
    local init_pos = inst:GetPosition()

    if _G.distsq(leader_pos, init_pos) > TUNING.FOLLOWER_REFOLLOW_DIST_SQ then
        if inst.components.combat then
            inst.components.combat:SetTarget(nil)
        end

        local success
        local new_pos = _G.Point(leader_pos:Get())

        local REFOLLOW_DIST = math.sqrt(TUNING.FOLLOWER_REFOLLOW_DIST_SQ)
        local angle = math.atan2(leader_pos.z - init_pos.z, init_pos.x - leader_pos.x) --leader:GetAngleToPoint(init_pos) * DEGREES
        if inst.components.locomotor:CanPathfindOnWater() then
            local offset = _G.FindSwimmableOffset(leader_pos, angle, REFOLLOW_DIST, 10, false, true, NoHoles, false)
            if offset then
                new_pos.x = leader_pos.x + offset.x
                new_pos.z = leader_pos.z + offset.z
            end
            new_pos.y = 0

            if _G.TheWorld.Map:IsOceanAtPoint(new_pos:Get()) then
                success = true
            end
        end

        if not success and inst.components.locomotor:CanPathfindOnLand() then
            local offset = _G.FindWalkableOffset(leader_pos, angle, REFOLLOW_DIST, 10, false, true, NoHoles)
            if offset then
                new_pos.x = leader_pos.x + offset.x
                new_pos.z = leader_pos.z + offset.z
            else
                new_pos.x = leader_pos.x
                new_pos.z = leader_pos.z
            end
            new_pos.y = 0

            if not _G.TheWorld.Map:IsOceanAtPoint(new_pos.x, new_pos.y, new_pos.z, true) then
                success = true
            end
        end

        if success then
            if inst.Physics then
                inst.Physics:Teleport(new_pos:Get())
            else
                inst.Transform:SetPosition(new_pos:Get())
            end
        end
    end
end

local function deadleaderfn(self, player) --stop teleporting to player ghost
    local f = self.components.follower
    if f.leader and f.leader == player then
        f.noleashing = true --disable wormhole teleport
        f:StopLeashing()
    end
end

local function reviveleaderfn(self, player) --start teleporting to player again
    local f = self.components.follower
    if not f.leader or f.leader ~= player then
        return
    elseif self:IsAsleep() then --leashing won't teleport if already asleep
        follower_tele(self, player:GetPosition())
    end

    f.noleashing = nil --enable wormhole teleport
    f:StartLeashing()
end

local function despawnleaderfn(self, data) --make sure followers are ready to rejoin player
    local player = data
    if data.player then
        player = data.player
    end

    local f = self.components.follower
    if not f.leader or f.leader ~= player then
        return
    elseif _G.distsq(self:GetPosition(), player:GetPosition()) > TUNING.FOLLOWER_REFOLLOW_DIST_SQ then
        follower_tele(self, player:GetPosition())
    end

    f.noleashing = nil --enable wormhole teleport
    f:StartLeashing() --player may come back alive from caves, deadleaderfn will undo this if not
end

local function manage_leader_events(inst, player_new, player_old)
    if inst._despawnleaderfn then
        inst:RemoveEventCallback("ms_becameghost", inst._deadleaderfn, player_old)
        inst:RemoveEventCallback("ms_respawnedfromghost", inst._reviveleaderfn, player_old)
        inst:RemoveEventCallback("ms_playerdespawnandmigrate", inst._despawnleaderfn, _G.TheWorld)
        inst:RemoveEventCallback("ms_playerdespawnanddelete", inst._despawnleaderfn, _G.TheWorld)

        inst._deadleaderfn = nil
        inst._reviveleaderfn = nil
        inst._despawnleaderfn = nil
    end

    if player_new and inst.components.follower.keepdeadleader then
        inst._deadleaderfn = function(player) deadleaderfn(inst, player) end
        inst._reviveleaderfn = function(player) reviveleaderfn(inst, player) end
        inst._despawnleaderfn = function(world, data) despawnleaderfn(inst, data) end

        inst:ListenForEvent("ms_becameghost", inst._deadleaderfn, player_new) --also triggers when rejoining as ghost
        inst:ListenForEvent("ms_respawnedfromghost", inst._reviveleaderfn, player_new)
        inst:ListenForEvent("ms_playerdespawnandmigrate", inst._despawnleaderfn, _G.TheWorld)
        inst:ListenForEvent("ms_playerdespawnanddelete", inst._despawnleaderfn, _G.TheWorld)
    end
end

local function followleaderfn(inst) --don't follow player ghost
    local leader = inst.components.follower.leader
    return (leader and not leader:HasTag("playerghost")) and leader or nil
end

----------------------------------------
---------------- Spiders ---------------
----------------------------------------

if cfg.SPIDERS_NOTRAP > 0 or cfg.SPIDERS_DEADLEADER > 0 or cfg.SPIDERS_MASS > 0 then
    local function spider_leadfn(inst, new_leader, prev_leader)
        local player_new = (new_leader and new_leader:HasTag("player")) and new_leader
        local player_old = (prev_leader and prev_leader:HasTag("player")) and prev_leader

        if player_new and not player_old then
            if cfg.SPIDERS_NOTRAP > 0 then
                inst:AddTag("notraptrigger")
            end

            if cfg.SPIDERS_MASS > 0 then
                if not inst._default_mass then
                    inst._default_mass = inst.Physics:GetMass()
                end
                inst.Physics:SetMass(cfg.SPIDERS_MASS)
            end
        elseif player_old and not player_new then
            if cfg.SPIDERS_NOTRAP > 0 then
                inst:RemoveTag("notraptrigger")
            end

            if inst._default_mass then
                inst.Physics:SetMass(inst._default_mass)
                inst._default_mass = nil
            end
        end

        if cfg.FOLLOW_GHOST == 0 then
            manage_leader_events(inst, player_new, player_old)
        end
    end

    if cfg.SPIDERS_DEADLEADER > 0 and cfg.FOLLOW_GHOST == 0 then
        --surgery_table(c_select(), {{4,1,2,1,"target = followleaderfn"}, {4,2,2,2,"target = followleaderfn"}})
        local spider_surgery =
        {name = "Priority", child =
            {num = 4, name = "Priority", children =
                {{num = 1, name = "Sequence", child =
                    {num = 2, name = "Priority", child =
                        {num = 1, name = "Follow", target = followleaderfn}
                    }
                },
                {num = 2, name = "Sequence", child =
                    {num = 2, name = "Priority", child =
                        {num = 2, name = "Follow", target = followleaderfn}
                    }
                }}
            }
        }

        AddBrainPostInit("spiderbrain", function(self)
            local err_msg = HackUtil.perform_surgery(self.bt.root, spider_surgery)
            if err_msg then
                modprint("Error ("..ts(self.inst).."): "..err_msg)
            end
        end)

        --surgery_table(c_select(), {{5,2,"target = followleaderfn"}, {6,2,3,"target = followleaderfn"}})
        local spider_water_surgery =
        {name = "Priority", children =
            {{num = 5, name = "Sequence", child =
                {num = 2, name = "Follow", target = followleaderfn}
            },
            {num = 6, name = "Sequence", child =
                {num = 2, name = "Priority", child =
                    {num = 3, name = "Follow", target = followleaderfn}
                }
            }}
        }

        AddBrainPostInit("spider_waterbrain", function(self)
            local err_msg = HackUtil.perform_surgery(self.bt.root, spider_water_surgery)
            if err_msg then
                modprint("Error ("..ts(self.inst).."): "..err_msg)
            end
        end)
    end

    for _, v in pairs({"spider", "spider_warrior", "spider_hider", "spider_spitter", "spider_dropper", "spider_moon", "spider_healer", "spider_water"}) do
        AddPrefabPostInit(v, function(inst)
            local f = inst.components.follower
            local old_leadfn = f.OnChangedLeader
            f.OnChangedLeader = function(inst, new_leader, prev_leader, ...)
                spider_leadfn(inst, new_leader, prev_leader)
                return old_leadfn and old_leadfn(inst, new_leader, prev_leader, ...) or nil
            end

            if cfg.SPIDERS_DEADLEADER > 0 then
                f.keepdeadleader = true
            end
        end)
    end
end

----------------------------------------
------- Pigs, Merms, and Bunnymen ------
----------------------------------------

local function cancel_loyaltasks(inst) --cancel the tasks that make followers stop following based on timer
    local f = inst.components.follower
    f:CancelLoyaltyTask()
    f.cached_player_leader_timeleft = nil
    if f.cached_player_leader_task then
        f.cached_player_leader_task:Cancel()
        f.cached_player_leader_task = nil
    end
end

if cfg.PIGMERMBUN_NOTRAP > 0 or cfg.PIGMERMBUN_LOYALTY > 0 or cfg.PIGMERMBUN_DEADLEADER > 0 or cfg.PIGMERMBUN_MASS > 0 then
    local function pigmermbun_leadfn(inst, new_leader, prev_leader)
        local player_new = (new_leader and new_leader:HasTag("player")) and new_leader
        local player_old = (prev_leader and prev_leader:HasTag("player")) and prev_leader

        if player_new and not player_old then
            if cfg.PIGMERMBUN_NOTRAP > 0 then
                inst:AddTag("notraptrigger")
            end

            if cfg.PIGMERMBUN_MASS > 0 then
                if not inst._default_mass then
                    inst._default_mass = inst.Physics:GetMass()
                end
                inst.Physics:SetMass(cfg.PIGMERMBUN_MASS)
            end
        elseif player_old and not player_new then
            if cfg.PIGMERMBUN_NOTRAP > 0 then
                inst:RemoveTag("notraptrigger")
            end

            if inst._default_mass then
                inst.Physics:SetMass(inst._default_mass)
                inst._default_mass = nil
            end
        end

        if cfg.FOLLOW_GHOST == 0 then
            manage_leader_events(inst, player_new, player_old)
        end
    end

    if cfg.PIGMERMBUN_DEADLEADER > 0 and cfg.FOLLOW_GHOST == 0 then
        --surgery_table(c_select(), {{14,2,3,1,"target = followleaderfn"}})
        local pigman_surgery =
        {name = "Priority", child =
            {num = 14, name = "Parallel", child =
                {num = 2, name = "Priority", child =
                    {num = 3, name = "ChattyNode", child =
                        {num = 1, name = "Follow", target = followleaderfn}
                    }
                }
            }
        }

        AddBrainPostInit("pigbrain", function(self)
            local err_msg = HackUtil.perform_surgery(self.bt.root, pigman_surgery)
            if err_msg then
                modprint("Error ("..ts(self.inst).."): "..err_msg)
            end
        end)

        --surgery_table(c_select(), {{1,2,18,1,"target = followleaderfn"}})
        local merm_surgery =
        {name = "Priority", child =
            {num = 1, name = "Parallel", child =
                {num = 2, name = "Priority", child =
                    {num = 18, name = "ChattyNode", child =
                        {num = 1, name = "Follow", target = followleaderfn}
                    }
                }
            }
        }

        AddBrainPostInit("mermbrain", function(self)
            local err_msg = HackUtil.perform_surgery(self.bt.root, merm_surgery)
            if err_msg then
                modprint("Error ("..ts(self.inst).."): "..err_msg)
            end
        end)

        --surgery_table(c_select(), {{1,2,14,1,"target = followleaderfn"}})
        local mermguard_surgery =
        {name = "Priority", child =
            {num = 1, name = "Parallel", child =
                {num = 2, name = "Priority", child =
                    {num = 14, name = "ChattyNode", child =
                        {num = 1, name = "Follow", target = followleaderfn}
                    }
                }
            }
        }

        AddBrainPostInit("mermguardbrain", function(self)
            local err_msg = HackUtil.perform_surgery(self.bt.root, mermguard_surgery)
            if err_msg then
                modprint("Error ("..ts(self.inst).."): "..err_msg)
            end
        end)

        --surgery_table(c_select(), {{11,"target = followleaderfn"}})
        local bunnyman_surgery =
        {name = "Priority", child =
            {num = 11, name = "Follow", target = followleaderfn}
        }

        AddBrainPostInit("bunnymanbrain", function(self)
            local err_msg = HackUtil.perform_surgery(self.bt.root, bunnyman_surgery)
            if err_msg then
                modprint("Error ("..ts(self.inst).."): "..err_msg)
            end
        end)
    end

    for _, v in pairs({"pigman", "bunnyman", "merm", "mermguard",
        "merm_shadow", "merm_lunar", "mermguard_shadow", "mermguard_lunar"}) do
        AddPrefabPostInit(v, function(inst)
            local f = inst.components.follower
            local old_leadfn = f.OnChangedLeader
            f.OnChangedLeader = function(inst, new_leader, prev_leader, ...)
                pigmermbun_leadfn(inst, new_leader, prev_leader)
                return old_leadfn and old_leadfn(inst, new_leader, prev_leader, ...) or nil
            end

            if cfg.PIGMERMBUN_LOYALTY > 0 then
                f.neverexpire = true
            end

            if cfg.PIGMERMBUN_DEADLEADER > 0 then
                f.keepdeadleader = true
            end
        end)
    end
end

----------------------------------------
------------- Rock Lobsters ------------
----------------------------------------

if cfg.ROCKY_LOYALTY > 0 or cfg.ROCKY_DEADLEADER > 0 or cfg.ROCKY_SPEED > 0 or cfg.ROCKY_MASS > 0 then
    local function rocky_leadfn(inst, new_leader, prev_leader)
        local player_new = (new_leader and new_leader:HasTag("player")) and new_leader
        local player_old = (prev_leader and prev_leader:HasTag("player")) and prev_leader

        if player_new and not player_old then
            if cfg.ROCKY_SPEED > 0 then
                if inst.components.scaler then
                    inst.components.scaler.OnApplyScale(inst, inst.components.scaler.scale)
                else --somebody removed scaler component
                    if not inst._default_speed then
                        inst._default_speed = inst.components.locomotor.walkspeed
                    end
                    inst.components.locomotor.walkspeed = cfg.ROCKY_SPEED
                end
            end

            if cfg.ROCKY_MASS > 0 then
                if not inst._default_mass then
                    inst._default_mass = inst.Physics:GetMass()
                end
                inst.Physics:SetMass(cfg.ROCKY_MASS)
            end
        elseif player_old and not player_new then
            if inst._default_speed then --only when lacking scaler component
                inst.components.locomotor.walkspeed = inst._default_speed
                inst._default_speed = nil
            end

            if inst._default_mass then
                inst.Physics:SetMass(inst._default_mass)
                inst._default_mass = nil
            end
        end

        if cfg.FOLLOW_GHOST == 0 then
            manage_leader_events(inst, player_new, player_old)
        end
    end

    if cfg.ROCKY_DEADLEADER > 0 and cfg.FOLLOW_GHOST == 0 then
        --surgery_table(c_select(), {{5,"target = followleaderfn"}})
        local rocky_surgery =
        {name = "Priority", child =
            {num = 5, name = "Follow", target = followleaderfn}
        }

        AddBrainPostInit("rockybrain", function(self)
            local err_msg = HackUtil.perform_surgery(self.bt.root, rocky_surgery)
            if err_msg then
                modprint("Error ("..ts(self.inst).."): "..err_msg)
            end
        end)
    end

    AddPrefabPostInit("rocky", function(inst)
        local f = inst.components.follower
        local old_leadfn = f.OnChangedLeader
        f.OnChangedLeader = function(inst, new_leader, prev_leader, ...)
            rocky_leadfn(inst, new_leader, prev_leader)
            return old_leadfn and old_leadfn(inst, new_leader, prev_leader, ...) or nil
        end

        if cfg.ROCKY_LOYALTY > 0 then
            f.neverexpire = true --this also protects against epicscare due to a loyalty percent check in rockybrain
        end

        if cfg.ROCKY_DEADLEADER > 0 then
            f.keepdeadleader = true
        end

        if cfg.ROCKY_SPEED > 0 and inst.components.scaler then
            local old_scalefn = inst.components.scaler.OnApplyScale
            inst.components.scaler.OnApplyScale = function(inst, scale, ...)
                if old_scalefn then
                    old_scalefn(inst, scale, ...)
                end

                local leader = inst.components.follower.leader
                if leader and leader:HasTag("player") then
                    inst.components.locomotor.walkspeed = cfg.ROCKY_SPEED / scale
                end
            end
        end
    end)
end

----------------------------------------
--- Smallbirds and Smallish Tallbirds --
----------------------------------------

if cfg.SMALLBIRD_DEADLEADER > 0 or cfg.SMALLBIRD_MASS > 0 then
    local function smallbird_leadfn(inst, new_leader, prev_leader)
        local player_new = (new_leader and new_leader:HasTag("player")) and new_leader
        local player_old = (prev_leader and prev_leader:HasTag("player")) and prev_leader

        if player_new and not player_old then
            if cfg.SMALLBIRD_MASS > 0 then
                if not inst._default_mass then
                    inst._default_mass = inst.Physics:GetMass()
                end
                inst.Physics:SetMass(cfg.SMALLBIRD_MASS)
            end
        elseif player_old and not player_new then
            if inst._default_mass then
                inst.Physics:SetMass(inst._default_mass)
                inst._default_mass = nil
            end
        end

        if cfg.FOLLOW_GHOST == 0 then
            manage_leader_events(inst, player_new, player_old)
        end
    end

    if cfg.SMALLBIRD_DEADLEADER > 0 and cfg.FOLLOW_GHOST == 0 then
        local function wanderleaderfn(inst) --don't wander towards player ghost
            local leader = inst.components.follower.leader
            if leader and not leader:HasTag("playerghost") then
                return _G.Vector3(leader.Transform:GetWorldPosition())
            end
        end

        --surgery_table(c_select(), {{3,2,2,2,"target = followleaderfn"}, {6,2,2,2,"target = followleaderfn"}, {7,2,"target = followleaderfn"}, {8,"homepos = wanderleaderfn"}})
        local smallbird_surgery =
        {name = "Priority", children =
            {{num = 3, name = "Sequence", child =
                {num = 2, name = "Parallel(Any)", child =
                    {num = 2, name = "Priority", child =
                        {num = 2, name = "Follow", target = followleaderfn}
                    }
                }
            },
            {num = 6, name = "Sequence", child =
                {num = 2, name = "Parallel(Any)", child =
                    {num = 2, name = "Priority", child =
                        {num = 2, name = "Follow", target = followleaderfn}
                    }
                }
            },
            {num = 7, name = "Priority", child =
                {num = 2, name = "Follow", target = followleaderfn}
            },
            {num = 8, name = "Wander", homepos = wanderleaderfn}}
        }

        AddBrainPostInit("smallbirdbrain", function(self)
            local err_msg = HackUtil.perform_surgery(self.bt.root, smallbird_surgery)
            if err_msg then
                modprint("Error ("..ts(self.inst).."): "..err_msg)
            end
        end)
    end

    for _, v in pairs({"smallbird", "teenbird"}) do
        AddPrefabPostInit(v, function(inst)
            local f = inst.components.follower
            local old_leadfn = f.OnChangedLeader
            f.OnChangedLeader = function(inst, new_leader, prev_leader, ...)
                smallbird_leadfn(inst, new_leader, prev_leader)
                return old_leadfn and old_leadfn(inst, new_leader, prev_leader, ...) or nil
            end

            if cfg.SMALLBIRD_DEADLEADER > 0 then
                f.keepdeadleader = true
            end
        end)
    end
end
