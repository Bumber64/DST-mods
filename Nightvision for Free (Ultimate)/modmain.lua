
local _G = GLOBAL

local ts = _G.tostring --DEBUG
local function dprint(inst, s) --DEBUG
    if inst.components.talker then
        inst.components.talker:Say(ts(s))
    end
end

local ToggleNightvisionKey = GetModConfigData("FREENIGHTVISION_TOGGLEKEY") --Keycode
local FREENIGHTVISION_GRUEALERT = GetModConfigData("FREENIGHTVISION_GRUEALERT") --Boolean

local MOGGLES_EQUIP = GetModConfigData("MOGGLES_EQUIP") --0=AlwaysToggle, 1=ToggleOff, 2=NoToggle, 3=AutoToggleOff
local AUTO_DARK = GetModConfigData("AUTO_DARK") --0=Disabled, 1=Night, 2=NightCaves, 3=Dark
local AUTO_LIGHT = GetModConfigData("AUTO_LIGHT") --0=Disabled, 1=Day, 2=Light

local DUSK_IS_DAY = GetModConfigData("DUSK_IS_DAY") --Boolean
local DAY_CC = GetModConfigData("DAY_CC") --Filename or false
local NIGHT_CC = GetModConfigData("NIGHT_CC") --Filename or false

local NV_ICON = GetModConfigData("NV_ICON") --Boolean

_G.t = --DEBUG
{
    dark = 0,
    light = 0,
    phase = 0,
    nv = 0,
}

----------------------------------------
------------- Manual Toggle ------------
----------------------------------------

local function in_game() --HasInputFocus is cleaner than checking active screen
    return _G.TheWorld and _G.ThePlayer and _G.ThePlayer.HUD and not _G.ThePlayer.HUD:HasInputFocus()
end

if ToggleNightvisionKey ~= 0 then --Manual toggle can be disabled
    _G.TheInput:AddKeyUpHandler(ToggleNightvisionKey, function()
        if not in_game() then
            return
        end

        local p = _G.ThePlayer --Temporarily set to player for brevity
        p = not (p._forced_nightvision and p._forced_nightvision:value()) and
            p.components.playervision --If WX's circuit is active then p = false, else p = playervision

        if not p or p.nightvision and not (MOGGLES_EQUIP == 0 or MOGGLES_EQUIP == 1 and p.forcenightvision) then
            return --Restrict manual toggling based on MOGGLES_EQUIP and WX circuit
        end

        p:ForceNightVision(not p.forcenightvision) --Toggle and push "nightvision" event
    end)
end

----------------------------------------
--------------- Grue Alert -------------
----------------------------------------

local SpawnGrueAlert = require("prefabs/grue_alert")

local GrueAlertTask = nil
local function GrueAlertFn(inst)
    if inst.components.grue or --Free nightvision protects in singleplayer
        inst._forced_nightvision and inst._forced_nightvision:value() then --Don't alert if WX's circuit active
            return
    end

    local pv = inst.components.playervision
    if pv and (pv.forcenightvision and not pv.nightvision) then
        SpawnGrueAlert(inst) --Alert when free nightvision active and moggles not equipped
    end
end

----------------------------------------
------------ Automatic Stuff -----------
----------------------------------------

local function set_nv(inst, enable) --Set nightvision, restricted based on moggles and WX's circuit
    local pv = inst.components.playervision
    if pv and not (inst._forced_nightvision and inst._forced_nightvision:value()) then
        pv:ForceNightVision(enable and not pv.nightvision)
    end
end

local function OnEnterDark(inst)
    _G.t.dark = _G.t.dark + 1 --DEBUG
    --dprint(inst, "dark = ".._G.t.dark)
    if FREENIGHTVISION_GRUEALERT and GrueAlertTask == nil then
        GrueAlertTask = inst:DoPeriodicTask(0.25, GrueAlertFn)
    end
    if AUTO_DARK > 2 then --AUTO_DARK: 0=Disabled, 1=Night, 2=NightCaves, 3=Dark
        set_nv(inst, true)
    end
end

local function OnEnterLight(inst)
    _G.t.light = _G.t.light + 1 --DEBUG
    --dprint(inst, "light = ".._G.t.light)
    if GrueAlertTask then
        GrueAlertTask:Cancel()
        GrueAlertTask = nil
    end
    if AUTO_LIGHT > 1 then --AUTO_LIGHT: 0=Disabled, 1=Day, 2=Light
        set_nv(inst, false)
    end
end

local function OnPhaseChanged(inst, phase)
    _G.t.phase = _G.t.phase + 1 --DEBUG
    --dprint(inst, "phase = ".._G.t.phase)
    local pv = inst.components.playervision
    if not pv or DUSK_IS_DAY and phase == "dusk" then
        return --If DUSK_IS_DAY and called from listener, then ignore day -> dusk
    end

    local state = _G.TheWorld.state
    if pv.forcenightvision then
        if AUTO_LIGHT == 1 and
            (state.isday or
            state.isdusk and DUSK_IS_DAY or
            state.isnight and state.isfullmoon) then
                set_nv(inst, false)
        end
    elseif (AUTO_DARK == 1 or AUTO_DARK == 2) and
        (state.isdusk and not DUSK_IS_DAY or
        state.isnight and not state.isfullmoon) then
            set_nv(inst, true)
    end
end

local function OnNightVision(inst, enabled)
    _G.t.nv = _G.t.nv + 1 --DEBUG
    --dprint(inst, "nv = ".._G.t.nv)
    if enabled then
        if MOGGLES_EQUIP > 2 then --AutoToggleOff
            set_nv(inst, false)
        end
    elseif _G.TheWorld:HasTag("cave") then
        if AUTO_DARK == 2 then --Auto enabled for caves
            set_nv(inst, true)
        end
    else --Set based on auto light/dark settings
        OnPhaseChanged(inst)
    end

    if NV_ICON then
        inst:PushEvent("nv_change") --Update icon
    end
end

local function MogglesOn(inst, data)
    --dprint(inst, "moggles on")
    if inst == _G.ThePlayer and data and data.item and data.item:HasTag("nightvision") then
        inst:DoTaskInTime(0, OnNightVision, true)
    end
end

local function MogglesOff(inst, data)
    --dprint(inst, "moggles off")
    if inst == _G.ThePlayer and data and data.item and data.item:HasTag("nightvision") then
        local inv = inst.replica and inst.replica.inventory
        if inv then --Might have other nightvision equipment
            inst:DoTaskInTime(0, OnNightVision, inv:EquipHasTag("nightvision"))
        else --Player lost inventory component somehow
            inst:DoTaskInTime(0, OnNightVision, false)
        end
    end
end

----------------------------------------
-------------- PlayerVision ------------
----------------------------------------

if DAY_CC or NIGHT_CC or NV_ICON then
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
        if NV_ICON and self.ForceNightVision then
            local old_fn = self.ForceNightVision

            function self:ForceNightVision(force) --Track free and WX nightvision
                old_fn(self, force)
                self.inst:PushEvent("nv_change") --Update icon
            end
        end

        if not (DAY_CC or NIGHT_CC) then
            return
        end

        local cc_table = find_cc(self.UpdateCCTable)
        if not cc_table then
            return --Somebody removed it!
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
    if not inst.components.grue and --If singleplayer then player already pushed
        (FREENIGHTVISION_GRUEALERT or AUTO_DARK > 2 or AUTO_LIGHT > 1) then
            inst:AddComponent("client_lightwatcher")
    end
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

    if NV_ICON then
        init_nv_icon(inst.HUD)
    end

    if NV_ICON or MOGGLES_EQUIP > 2 or AUTO_DARK > 0 or AUTO_LIGHT > 0 then --MOGGLES_EQUIP: ..., 3=AutoToggleOff
        inst:ListenForEvent("equip", MogglesOn)
        inst:ListenForEvent("unequip", MogglesOff)

        local pv = inst.components.playervision
        if pv and not pv.nightvision then
            OnNightVision(inst, false) --Check caves/night now if applicable
        end
    end

    if FREENIGHTVISION_GRUEALERT or AUTO_DARK > 2 then --AUTO_DARK: 0=Disabled, 1=Night, 2=NightCaves, 3=Dark
        inst:ListenForEvent("enterdark", OnEnterDark)

        inst:DoTaskInTime(0.25, function(inst) --We might already be in darkness
            if not inst:IsInLight() then
                OnEnterDark(inst) --Player entered the shard in darkness
            end
        end)
    end

    if FREENIGHTVISION_GRUEALERT or AUTO_LIGHT > 1 then --AUTO_LIGHT: 0=Disabled, 1=Day, 2=Light
        inst:ListenForEvent("enterlight", OnEnterLight)
        --We start off disabled by default, so no need to check for light immediately
    end

    if not _G.TheWorld:HasTag("cave") and (AUTO_LIGHT == 1 or AUTO_DARK == 1 or AUTO_DARK == 2) then
        inst:ListenForEvent("phasechanged", function(world, phase) inst:DoTaskInTime(0, OnPhaseChanged, phase) end, _G.TheWorld)
        --We already checked night in OnNightVision and we start off disabled for day
    end
end

AddPlayerPostInit(function(inst)
    inst:DoTaskInTime(0, init_fn)
end)
