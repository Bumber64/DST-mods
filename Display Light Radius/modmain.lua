
local _G = GLOBAL
local TheInput = _G.TheInput

local TOGGLE_KEY = GetModConfigData("toggle_key")
local HIGHLIGHT_MODE = GetModConfigData("highlight_mode")
local LIGHT_COLOR = GetModConfigData("light_color")
local HIGHLIGHT_FREQ = 0.1
local DISCOVER_RADIUS = 80 --render range
local DISCOVER_FREQ = GetModConfigData("discover_rate") --1, 2, or 5
local LIGHT_FREQ = GetModConfigData("light_refresh") --0.1, 0.2, or 0.5
local MAX_LIGHT_FAILS = DISCOVER_FREQ / LIGHT_FREQ - 1 --just short of one discovery cycle
local LIGHT_THRESH = 0.075 --minimum safe light value

light_radius_toggle_on = GetModConfigData("start_enabled")
local last_target = nil --last highlight target
local highlight_task = nil
local discover_task = nil

-- Lighting calculation courtesty of JesseB_Klei:
-- light = e ^ ( ln(intensity) * (dist / radius) ^ -(falloff / ln(intensity)) ) * (0.2126 * r + 0.7152 * g + 0.0722 * b)
-- Solve for distance:
-- dist = e ^ ( ln( ln(light / (0.2126 * r + 0.7152 * g + 0.0722 * b)) / ln(intensity) ) / -(falloff / ln(intensity)) ) * radius
local function radius_for_threshold(l, thresh) --returns distance from light source that results in the given light value
    local a = math.log(l:GetIntensity())
    local r, g, b = l:GetColour()
    local lum = 0.2126 * r + 0.7152 * g + 0.0722 * b

    return math.exp(math.log(math.log(thresh / lum) / a) / -(l:GetFalloff() / a)) * l:GetRadius()
end

local function in_game()
    return _G.TheWorld and _G.ThePlayer and _G.ThePlayer.HUD and not _G.ThePlayer.HUD:HasInputFocus()
end

local PLACER_RATIO = 1.55 / math.sqrt(15) --normalizes radius to 1
local function lightradius(parent) --create indicator and attach to parent
    if not parent or not parent:IsValid() then
        return
    elseif parent._light_radius then
        parent._light_radius.orphaned()
    end

    local inst = _G.CreateEntity()

    inst.prefab = "lightradius"
    inst.entity:SetCanSleep(false)
    inst.persists = false

    inst.entity:AddTransform()
    inst.entity:AddAnimState()

    inst:AddTag("CLASSIFIED")
    inst:AddTag("NOCLICK")
    inst:AddTag("NOBLOCK")

    inst.AnimState:SetBank("firefighter_placement")
    inst.AnimState:SetBuild("firefighter_placement")
    inst.AnimState:PlayAnimation("idle")
    inst.AnimState:SetLightOverride(1)
    inst.AnimState:SetOrientation(_G.ANIM_ORIENTATION.OnGround)
    inst.AnimState:SetLayer(_G.LAYER_BACKGROUND)
    inst.AnimState:SetSortOrder(1)
    inst.AnimState:SetMultColour(0, 0, 0, 1)

    inst.my_parent = parent
    inst.entity:SetParent(parent.entity)

    inst._fail_count = 0
    inst._update_task = nil

    inst.update_radius = function()
        if not in_game() then
            return
        end

        local l = inst.my_parent.Light
        if l and l:IsEnabled() then
            if LIGHT_COLOR then
                local r, g, b = l:GetColour()
                inst.AnimState:SetAddColour(r, g, b, 0)
            else
                inst.AnimState:SetAddColour(1, 1, 1, 0)
            end

            inst._fail_count = 0
            local scale = math.sqrt(radius_for_threshold(l, LIGHT_THRESH)) * PLACER_RATIO
            inst.Transform:SetScale(scale, scale, scale)
        elseif inst._fail_count == 0 then
            inst._fail_count = 1
            inst.AnimState:SetAddColour(0, 0, 0, 0)
        elseif inst._fail_count < MAX_LIGHT_FAILS then
            inst._fail_count = inst._fail_count + 1
        else
            inst.orphaned()
        end
    end

    inst.orphaned = function()
        inst.my_parent._light_radius = nil
        inst._update_task:Cancel()
        inst:Remove()
    end

    inst:ListenForEvent("entitysleep", inst.orphaned, parent)
    inst:ListenForEvent("onremove", inst.orphaned, parent)
    inst:ListenForEvent("killallradius", inst.orphaned, _G.TheWorld)

    inst.update_radius()
    inst._update_task = inst:DoPeriodicTask(LIGHT_FREQ, inst.update_radius)

    return inst
end

local function attach_radius(inst)
    if not inst or not inst:IsValid() or inst._light_radius or
        inst:IsAsleep() or not inst.Light or not inst.Light:IsEnabled() or
        inst.prefab == "lightradius" then
            return
    end

    inst._light_radius = lightradius(inst)
end

local function detach_radius(inst)
    if not inst or not inst._light_radius then
        return
    end

    inst._light_radius.orphaned()
end

local NO_INSPECT = (HIGHLIGHT_MODE == 2)
local function highlight_fn()
    if light_radius_toggle_on or not in_game() then
        return
    end

    if NO_INSPECT or TheInput:IsControlPressed(_G.CONTROL_FORCE_INSPECT) then
        local target = TheInput:GetHUDEntityUnderMouse() and nil or TheInput:GetWorldEntityUnderMouse()
        if target ~= last_target then --new target
            detach_radius(last_target) --does nothing if last_target is nil
            last_target = target
            attach_radius(target) --does nothing if target is nil
        end --else keep current lightradius
    elseif last_target then
        detach_radius(last_target)
        last_target = nil
    end
end

local function discover_fn() --look for potential light sources
    if not in_game() then
        return
    end

    local x, y, z = _G.ThePlayer.Transform:GetWorldPosition()
    local ents = _G.TheSim:FindEntities(x, y, z, DISCOVER_RADIUS)
    for _, ent in ipairs(ents) do
        attach_radius(ent) --attach if valid
    end
end

local function toggle_fn() --apply current toggle state
    if discover_task then
        discover_task:Cancel()
    end
    if highlight_task then
        highlight_task:Cancel()
        detach_radius(last_target)
        last_target = nil
    end

    if light_radius_toggle_on then
        discover_fn()
        discover_task = _G.ThePlayer:DoPeriodicTask(DISCOVER_FREQ, discover_fn)
    else
        _G.TheWorld:PushEvent("killallradius")
        if HIGHLIGHT_MODE ~= 0 then
            highlight_task = _G.ThePlayer:DoPeriodicTask(HIGHLIGHT_FREQ, highlight_fn)
        end
    end
end

TheInput:AddKeyDownHandler(TOGGLE_KEY, function()
    if in_game() then
        light_radius_toggle_on = not light_radius_toggle_on
        toggle_fn()
    end
end)

AddPlayerPostInit(function(inst)
    inst:DoTaskInTime(0, function(inst)
        if inst == _G.ThePlayer then
            toggle_fn() --initialize based on start_enabled
        end
    end)
end)
