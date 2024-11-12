
local _G = GLOBAL
if not _G.TheNet:GetIsServer() then
    return
end

local function modprint(s)
    print("[Ice Flingomatic Watering] "..s)
end

local function insert_if_not_exist(t, s)
    if table.contains(t, s) then
        return false
    end
    table.insert(t, s)
    return true
end

local HackUtil = require("tools/hackutil")

-------------------------------------------
---------------- Settings -----------------
-------------------------------------------

local SMART_TARGET_WITHER = GetModConfigData("smart_target_wither") --bool; target witherables only when too hot
local SMART_TARGET_CROPS = GetModConfigData("smart_target_crops") --bool; target crops only when actually needed
local TARGET_CENTER = GetModConfigData("target_center") --bool; target center of tile once instead of each crop
local WATER_PERCENT = GetModConfigData("water_percent") --num; water crops when tile moisture falls below this value
local ADD_WETNESS = GetModConfigData("add_wetness") --num; snowballs add this much wetness
local NO_FREEZE_FFFLY = GetModConfigData("no_freeze_fffly") --bool; snowballs don't affect friendy fruit fly

-------------------------------------------
---------- Find Existing Stuff ------------
-------------------------------------------

local NOTAGS
local NONEMERGENCY_FIREONLY_TAGS
local RegisterDetectedItem

local my_NONEMERGENCYTAGS --add "farmplantstress"

local function find_fdetector_upvalues(self)
    if my_NONEMERGENCYTAGS then
        return true --already succeeded
    end

    modprint("Upvalue hacking firedetector.Activate for required values.")
    local old_LFFAF, err_msg = HackUtil.GetUpvalue(self.Activate, "LookForFiresAndFirestarters")
    if not old_LFFAF then
        modprint("firedetector.Activate"..err_msg)
        return false
    end

    NOTAGS, err_msg = HackUtil.GetUpvalue(old_LFFAF, "NOTAGS")
    if not NOTAGS then
        modprint("NOTAGS not found in old LookForFiresAndFirestarters! Using default.")
        NOTAGS = {"FX", "NOCLICK", "DECOR", "INLIMBO", "burnt", "player", "monster"}
    end

    NONEMERGENCY_FIREONLY_TAGS, err_msg = HackUtil.GetUpvalue(old_LFFAF, "NONEMERGENCY_FIREONLY_TAGS")
    if not NONEMERGENCY_FIREONLY_TAGS then
        modprint("NONEMERGENCY_FIREONLY_TAGS not found in old LookForFiresAndFirestarters! Using default.")
        NONEMERGENCY_FIREONLY_TAGS = {"fire", "smolder"}
    end

    RegisterDetectedItem, err_msg = HackUtil.GetUpvalue(old_LFFAF, "RegisterDetectedItem")
    if not RegisterDetectedItem then
        modprint("RegisterDetectedItem not found in old LookForFiresAndFirestarters! Using default.")
        RegisterDetectedItem = function(inst, self, target)
            self.detectedItems[target] = inst:DoTaskInTime(2, function(inst, self, target)
                self.detectedItems[target] = nil
            end, self, target)
        end
    end

    my_NONEMERGENCYTAGS, err_msg = HackUtil.GetUpvalue(old_LFFAF, "NONEMERGENCYTAGS")
    if not my_NONEMERGENCYTAGS then
        modprint("NONEMERGENCYTAGS not found in old LookForFiresAndFirestarters! Using default.")
        my_NONEMERGENCYTAGS = {"witherable", "fire", "smolder", "farmplantstress"} --target farm crops
    elseif insert_if_not_exist(my_NONEMERGENCYTAGS, "farmplantstress") then --target farm crops
        modprint("Added \"farmplantstress\" tag to existing NONEMERGENCYTAGS.")
    else
        modprint("Found \"farmplantstress\" tag in existing NONEMERGENCYTAGS.")
    end

    return true
end

-------------------------------------------
--------------- New Stuff -----------------
-------------------------------------------

local function GetTileCoords(target) --helper function
    return _G.TheWorld.Map:GetTileCoordsAtPoint(target.Transform:GetWorldPosition())
end

local function GetCenterCoords(target) --returns world coords of center of crop's tile
    return _G.TheWorld.Map:GetTileCenterPoint(GetTileCoords(target))
end

local function is_on_soil(target) --only crops planted on soil can be watered
    return _G.TheWorld.Map:GetTile(GetTileCoords(target)) == _G.WORLD_TILES.FARMING_SOIL
end

local function SoilCoord(target) --returns a string unique to crop's map tile or nil
    if TARGET_CENTER and target and target:HasTag("farmplantstress") then
        return string.format("%d,%d", GetTileCoords(target))
    end
    return nil
end

local is_point_dry --set to appropriate fn based on settings
if WATER_PERCENT > 0.0 and not SMART_TARGET_CROPS then --need to acquire _moisturegrid and define GetSoilMoistureAtPoint
    AddComponentPostInit("farming_manager", function(self)
        modprint("Checking for GetSoilMoistureAtPoint...")
        if self.GetSoilMoistureAtPoint then
            modprint("GetSoilMoistureAtPoint found.")
        else
            modprint("GetSoilMoistureAtPoint not found.")
            local _moisturegrid

            function self:GetSoilMoistureAtPoint(x, y, z)
                if _moisturegrid == nil then
                    modprint("Upvalue hacking farming_manager.OnSave for \"_moisturegrid\".")
                    _moisturegrid, err_msg = HackUtil.GetUpvalue(self.OnSave, "_moisturegrid")

                    if not _moisturegrid then
                        _moisturegrid = false --don't retry
                        modprint("farming_manager.OnSave"..err_msg)
                        _G.TheNet:SystemMessage("[Ice Flingomatic Watering] Failed to find \"_moisturegrid\" in farming_manager component!")
                    end
                end

                if _moisturegrid then
                    return _moisturegrid:GetDataAtPoint(_G.TheWorld.Map:GetTileCoordsAtPoint(x, y, z)) or _G.TheWorld.state.wetness
                else
                    return 100.0 --error, never water
                end
            end
            modprint("Defined GetSoilMoistureAtPoint.")
        end
    end)

    is_point_dry = function(x, y, z)
        return _G.TheWorld.components.farming_manager:GetSoilMoistureAtPoint(x, y, z) < WATER_PERCENT
    end
else --dry is 0 moisture
    is_point_dry = function(x, y, z)
        return not _G.TheWorld.components.farming_manager:IsSoilMoistAtPoint(x, y, z)
    end
end

-------------------------------------------
------------- Changed Stuff ---------------
-------------------------------------------

local function my_CheckTargetScore(target) --added crops; smarter witherable handling
    if not target:IsValid() then
        return 0
    elseif target.components.burnable then
        if target.components.burnable:IsBurning() then
            return 10, true
        elseif target.components.burnable:IsSmoldering() then
            return 9
        end
    end

    local w = target.components.witherable
    if w and (w.protect_to_time == nil or w.protect_to_time < _G.GetTime() + 5.0) then --unprotected or soon to be
        if w:CanWither() then --not already withered
            if not SMART_TARGET_WITHER or _G.TheWorld.state.temperature > w.wither_temp - 1.0 then --option to skip if not hot
                return 8
            end
        elseif w:CanRejuvenate() then
            return 7
        end
    end

    local ps = target.components.farmplantstress
    if ps and ps.stressors.moisture and is_on_soil(target) then --only target plants that require moisture and can be watered
        local thirsty = not SMART_TARGET_CROPS or --option to skip if plant doesn't need water right now
            ps.stressors_testfns.moisture and ps.stressors_testfns.moisture(target, ps.stressors.moisture, false) and --moisture need is unmet
            (not target.components.growable or target.components.growable:GetCurrentStageData().tendable) --only target growing crops

        if thirsty and is_point_dry(target.Transform:GetWorldPosition()) then --plant needs watering and soil is dry
            return 8
        end
    end

    return 0
end

local function my_LookForFiresAndFirestarters(inst, self, force) --allow targeting of soil instead of individual crops
    if not force and inst.sg and inst.sg:HasStateTag("busy") then
        return
    end
    local x, y, z = inst.Transform:GetWorldPosition()
    local ents = _G.TheSim:FindEntities(x, y, z, self.range, nil, NOTAGS, (self.fireOnly and NONEMERGENCY_FIREONLY_TAGS) or my_NONEMERGENCYTAGS)
    local target = nil
    local targetscore = 0
    for _,v in ipairs(ents) do
        local sc = SoilCoord(v) --use center of target's tile when TARGET_CENTER
        if not self.detectedItems[v] and not (sc and self.detectedItems[sc]) then
            local score, force = my_CheckTargetScore(v)
            if force then
                target = v
                break
            elseif score > targetscore then
                targetscore = score
                target = v
            end
        end
    end
    if target then
        local sc = SoilCoord(target)
        if sc then --use center of soil tile
            RegisterDetectedItem(inst, self, sc) --register the string
            if self.onfindfire ~= nil then
                local x, y, z = GetCenterCoords(target)
                self.onfindfire(inst, _G.Point(x, 0, z))
            end
        else --use position of entity
            RegisterDetectedItem(inst, self, target)
            if self.onfindfire ~= nil then
                self.onfindfire(inst, target:GetPosition())
            end
        end
    end
end

-------------------------------------------
---------------- Finally ------------------
-------------------------------------------

AddComponentPostInit("firedetector", function(self)
    if not find_fdetector_upvalues(self) then
        return
    elseif not HackUtil.SetUpvalue(self.Activate, my_LookForFiresAndFirestarters, "LookForFiresAndFirestarters") then
        modprint("firedetector.Activate -> LookForFiresAndFirestarters not found! (This shouldn't happen!)")
    end
end)

AddPrefabPostInit("firesuppressor", function(inst)
    inst.components.wateryprotection.addwetness = ADD_WETNESS
end)

AddPrefabPostInit("snowball", function(inst)
    inst.components.wateryprotection.addwetness = ADD_WETNESS
    if NO_FREEZE_FFFLY then
        inst.components.wateryprotection:AddIgnoreTag("friendlyfruitfly")
    end
end)
