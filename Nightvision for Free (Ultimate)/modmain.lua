
local _G = GLOBAL

local MOGGLES_EQUIP = GetModConfigData("MOGGLES_EQUIP") --0=AlwaysToggle, 1=ToggleOff, 2=NoToggle, 3=AutoToggleOff
local WX_ACTIVATE = GetModConfigData("WX_ACTIVATE") --0=AlwaysToggle, 1=ToggleOff, 2=NoToggle, 3=AutoToggleOff
local AUTO_DARK = GetModConfigData("AUTO_DARK") --0=Disabled, 1=Night, 2=NightCaves, 3=Dark
local AUTO_LIGHT = GetModConfigData("AUTO_LIGHT") --0=Disabled, 1=Day, 2=Light

local DUSK_IS_DAY = GetModConfigData("DUSK_IS_DAY") --Boolean
local DAY_CC = GetModConfigData("DAY_CC") --Filename or false
local NIGHT_CC = GetModConfigData("NIGHT_CC") --Filename or false

local GRUE_ALERT = GetModConfigData("GRUE_ALERT") --0=Disabled, 1=WarnVulnerable, 2=AlwaysWarn
local GRUE_ALERT_NV_ONLY = GetModConfigData("GRUE_ALERT_NV_ONLY") --Boolean
local NV_ICON = GetModConfigData("NV_ICON") --Boolean

----------------------------------------
------------- Manual Toggle ------------
----------------------------------------

local function is_circuit_on(inst) --True if WX circuit exists and active
    return inst._forced_nightvision and inst._forced_nightvision:value()
end

local function set_nv(inst, enable) --Set nightvision, accounting for WX's circuit
    if not enable == not inst._free_nightvision then
        inst._free_nightvision = enable
        if NV_ICON or GRUE_ALERT == 1 then
            inst:PushEvent("nv_change")
        end
    else --Already in correct state
        return
    end

    local pv = inst.components.playervision
    if not pv then
        return
    elseif enable then
        pv:ForceNightVision(true) --Does nothing if circuit active
    elseif not is_circuit_on(inst) then
        pv:ForceNightVision(false) --Turn off if circuit not active
    end
end

if GetModConfigData("TOGGLEKEY") ~= 0 then --Manual toggle enabled
    local function in_game()
        return _G.TheWorld and _G.ThePlayer and _G.ThePlayer.HUD and not _G.ThePlayer.HUD:HasInputFocus()
    end

    _G.TheInput:AddKeyDownHandler(GetModConfigData("TOGGLEKEY"), function()
        if not in_game() then
            return
        end

        local p = _G.ThePlayer
        local mog_vis = p.components.playervision and p.components.playervision.nightvision

        if MOGGLES_EQUIP > 1 and mog_vis or WX_ACTIVATE > 1 and is_circuit_on(p) then
            return --Can't toggle right now
        elseif p._free_nightvision then
            set_nv(p, false)
        elseif (MOGGLES_EQUIP == 0 or not mog_vis) and (WX_ACTIVATE == 0 or not is_circuit_on(p)) then
            set_nv(p, true)
        end
    end)
end
----------------------------------------
--------------- Grue Alert -------------
----------------------------------------

local grue_fns = {} --Functions for grue alerts

if GRUE_ALERT > 0 then
    local SpawnGrueAlert = require("prefabs/grue_alert")
    local GrueAlertTask --Periodic task for spawning alerts
    local grue_protect = {} --Sources of grue protection

    local function eval_grue_protect() --Alert if no protections remain
        if #grue_protect > 0 or GRUE_ALERT_NV_ONLY and not _G.ThePlayer._free_nightvision then
            if GrueAlertTask then
                GrueAlertTask:Cancel()
                GrueAlertTask = nil
            end
        else
            if GrueAlertTask == nil then
                GrueAlertTask = inst:DoPeriodicTask(0.25, SpawnGrueAlert)
            end
        end
    end

    grue_fns.ResetGrueAlert = function() --Reset alerts on character swap
        grue_protect = {}
        if GrueAlertTask then
            GrueAlertTask:Cancel()
            GrueAlertTask = nil
        end
    end

    grue_fns.OnInvincible = function(inst, data)
        if data.invincible then
            grue_protect.invincible = true
        else
            grue_protect.invincible = nil
        end
        eval_grue_protect()
    end

    grue_fns.OnDeath = function()
        grue_protect.dead = true
        eval_grue_protect()
    end

    grue_fns.OnAlive = function()
        grue_protect.dead = nil
        eval_grue_protect()
    end

    grue_fns.OnEnterState = function(inst, data)
        local state = data.statename
        if state == "bedroll" or state == "tent" or state == "knockout" then
            grue_protect.asleep = true
        else
            grue_protect.asleep = nil
        end
        eval_grue_protect()
    end

    grue_fns.OnNightvision = function(inst)
        if inst._free_nightvision and inst.components.grue then
            grue_protect.freenv = true --If grue then is solo caveless and free nv protects
        else
            grue_protect.freenv = nil
        end

        if is_circuit_on(inst) then
            grue_protect.circuit = true
        else
            grue_protect.circuit = nil
        end

        local pv = inst.components.playervision
        if pv and pv.nightvision then
            grue_protect.mole = true
        else
            grue_protect.mole = nil
        end
        eval_grue_protect()
    end

    grue_fns.OnEnterLight = function()
        grue_protect.light = true
        eval_grue_protect()
    end

    grue_fns.OnEnterDark = function()
        grue_protect.light = nil
        eval_grue_protect()
    end
end

----------------------------------------
-------------- Auto Toggle -------------
----------------------------------------

local function OnEnterDark(inst)
    set_nv(inst, true)
end

local function OnEnterLight(inst)
    set_nv(inst, false)
end

local function OnPhaseChanged(inst, phase)
    local pv = inst.components.playervision
    if not pv or DUSK_IS_DAY and phase == "dusk" then
        return --If DUSK_IS_DAY and called from listener, then ignore day -> dusk
    end

    local state = _G.TheWorld.state
    if inst._free_nightvision then
        if AUTO_LIGHT == 1 and --AUTO_LIGHT: 1=Day
            (state.isday or state.isfullmoon or
            state.isdusk and DUSK_IS_DAY) then
                set_nv(inst, false)
        end
    elseif (AUTO_DARK == 1 or AUTO_DARK == 2) and --AUTO_DARK: 1=Night, 2=NightCaves
        (state.isdusk and not DUSK_IS_DAY or
        state.isnight and not state.isfullmoon) then
            set_nv(inst, true)
    end
end

local function OnMoleVision(inst, enabled)
    if enabled then
        if MOGGLES_EQUIP > 2 then --MOGGLES_EQUIP: 3=AutoToggleOff
            set_nv(inst, false)
        end
    elseif _G.TheWorld:HasTag("cave") then
        if AUTO_DARK == 2 then --Auto enable for caves
            set_nv(inst, true)
        end
    else --Set based on auto light/dark settings
        OnPhaseChanged(inst)
    end

    if NV_ICON or GRUE_ALERT == 1 then
        inst:PushEvent("nv_change")
    end
end

local function MogglesOn(inst, data)
    if data and data.item and data.item:HasTag("nightvision") then
        inst:DoTaskInTime(0, OnMoleVision, true)
    end
end

local function MogglesOff(inst, data)
    if data and data.item and data.item:HasTag("nightvision") then
        inst:DoTaskInTime(0, OnMoleVision, inst.replica.inventory:EquipHasTag("nightvision"))
    end
end

----------------------------------------
-------------- PlayerVision ------------
----------------------------------------

if DAY_CC or NIGHT_CC or NV_ICON or WX_ACTIVATE > 2 or GRUE_ALERT == 1 then --Need WX circuit stuff or colorcubes
    local function find_cc(fn) --Upvalue hack PlayerVision.UpdateCCTable
        if not fn then
            return false
        end

        local i = 1
        local name, value = _G.debug.getupvalue(fn, i)

        while name and name ~= "NIGHTVISION_COLOURCUBES" do
            i = i + 1
            name, value = _G.debug.getupvalue(fn, i)
        end

        return name == "NIGHTVISION_COLOURCUBES" and value
    end

    AddComponentPostInit("playervision", function(self)
        if self.ForceNightVision and (NV_ICON or WX_ACTIVATE > 2 or
            GRUE_ALERT == 1 and not (GRUE_ALERT_NV_ONLY and self.inst.components.grue)) then --Make sure absolutely necessary
                local old_fn = self.ForceNightVision

                function self:ForceNightVision(force) --Track WX circuit
                    local prev_circuit = (is_circuit_on(self.inst) == true) --Force boolean
                    old_fn(self, force)

                    if prev_circuit == not is_circuit_on(self.inst) then --Circuit was toggled
                        self.inst:PushEvent("nv_change")

                        if WX_ACTIVATE > 2 and not prev_circuit then --WX_ACTIVATE: 3=AutoToggleOff
                            set_nv(inst, false)
                        end
                    end
                end
        end

        if not (DAY_CC or NIGHT_CC) then
            return --Don't touch colorcubes
        end

        local cc_table = find_cc(self.UpdateCCTable)
        if not cc_table then
            return --Somebody messed with UpdateCCTable!
        end

        if DAY_CC then --Filename or false
            cc_table.day = "images/colour_cubes/"..DAY_CC
            cc_table.full_moon = "images/colour_cubes/"..DAY_CC
            if DUSK_IS_DAY then
                cc_table.dusk = "images/colour_cubes/"..DAY_CC
            end
        end

        if NIGHT_CC then --Filename or false
            cc_table.night = "images/colour_cubes/"..NIGHT_CC
            if not DUSK_IS_DAY then
                cc_table.dusk = "images/colour_cubes/"..NIGHT_CC
            end
        end
    end)
end

----------------------------------------
------------- Initialization -----------
----------------------------------------

local function init_client_lightwatcher(inst) --Push "enterlight" and "enterdark" events if needed
    if not inst.components.grue and --If grue then is solo caveless and events already pushed
        (GRUE_ALERT > 0 or AUTO_DARK > 2 or AUTO_LIGHT > 1) then
            inst:AddComponent("client_lightwatcher")
    end
end

local function init_grue_alert(inst)
    if GRUE_ALERT == 1 then --GRUE_ALERT: 1=WarnVulnerable, 2=AlwaysWarn
        if GRUE_ALERT_NV_ONLY and inst.components.grue then
            return --If grue then is solo caveless and free nv always protecting
        end

        inst:ListenForEvent("invincibletoggle", grue_fns.OnInvincible)
        inst:ListenForEvent("death", grue_fns.OnDeath)
        inst:ListenForEvent("ms_respawnedfromghost", grue_fns.OnAlive)
        inst:ListenForEvent("newstate", grue_fns.OnEnterState)
        inst:ListenForEvent("nv_change", grue_fns.OnNightvision)

        if not inst.components.health or inst.components.health.invincible then
            --Health:IsInvincible() would track temp_invincible states, which doesn't pause grue
            grue_fns.OnInvincible(inst, {invincible = true})
        end

        if inst:HasTag("playerghost") then
            grue_fns.OnDeath()
        end
    end

    inst:ListenForEvent("enterlight", grue_fns.OnEnterLight)
    inst:ListenForEvent("enterdark", grue_fns.OnEnterDark)

    if inst:IsInLight() then
        grue_fns.OnEnterLight()
    end

    inst:ListenForEvent("ms_playerdespawn", grue_fns.ResetGrueAlert) --"ms_playerdespawnanddelete", "ms_playerseamlessswaped"? check inst before and after
end

local function init_nv_icon(hud)
    if not hud or hud.nightvisionicon then
        return
    end

    local icon_x = GetModConfigData("ICON_X_ONES") + GetModConfigData("ICON_X_TENS") + GetModConfigData("ICON_X_HUNDREDS")
    local icon_y = GetModConfigData("ICON_Y_ONES") + GetModConfigData("ICON_Y_TENS") + GetModConfigData("ICON_Y_HUNDREDS")
    local params =
    {
        scale = GetModConfigData("ICON_SCALE"),
        h_anchor = GetModConfigData("ICON_HANCHOR"),
        v_anchor = GetModConfigData("ICON_VANCHOR"),
        x = icon_x,
        y = icon_y,
    }

    local NVIcon = require("widgets/nightvisionicon")
    hud.nightvisionicon = NVIcon(hud, params)
end

local function init_fn(inst)
    if inst ~= _G.ThePlayer then
        return
    else
        init_client_lightwatcher(inst)
    end

    if GRUE_ALERT > 0 then --GRUE_ALERT: 1=WarnVulnerable, 2=AlwaysWarn
        init_grue_alert(inst)
    end

    if NV_ICON then
        init_nv_icon(inst.HUD)
    end

    if NV_ICON or GRUE_ALERT == 1 or MOGGLES_EQUIP > 2 or AUTO_DARK > 0 or AUTO_LIGHT > 0 then --MOGGLES_EQUIP: 3=AutoToggleOff
        inst:ListenForEvent("equip", MogglesOn)
        inst:ListenForEvent("unequip", MogglesOff)

        local pv = inst.components.playervision
        OnMoleVision(inst, pv and not pv.nightvision) --Check caves/night now if applicable, push nv_change
    end

    if AUTO_DARK > 2 then --AUTO_DARK: 1=Night, 2=NightCaves, 3=Dark
        inst:ListenForEvent("enterdark", OnEnterDark)

        inst:DoTaskInTime(0.25, function(inst) --We might already be in darkness
            if not inst:IsInLight() then
                OnEnterDark(inst) --Player entered the shard in darkness
            end
        end)
    end

    if AUTO_LIGHT > 1 then --AUTO_LIGHT: 1=Day, 2=Light
        inst:ListenForEvent("enterlight", OnEnterLight)
        --We start off disabled by default, so no need to check for light immediately
    end

    if not _G.TheWorld:HasTag("cave") and (AUTO_LIGHT == 1 or AUTO_DARK == 1 or AUTO_DARK == 2) then
        inst:ListenForEvent("phasechanged", function(world, phase) inst:DoTaskInTime(0, OnPhaseChanged, phase) end, _G.TheWorld)
        --We already checked night in OnMoleVision and we start off disabled for day
    end
end

AddPlayerPostInit(function(inst)
    inst:DoTaskInTime(0, init_fn)
end)
