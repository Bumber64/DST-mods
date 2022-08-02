
local _G = GLOBAL
if not _G.TheNet:GetIsServer() then
    return
end

local UpvalueHacker = require("tools/upvaluehacker") --Rezecib's upvalue hacker

local function modprint(s)
    print("[Ice Flingomatic Watering] "..s)
end

local function modassert(v, s)
    _G.assert(v, "[Ice Flingomatic Watering] "..s)
end

local function insertifnotexist(t, s)
    if table.contains(t, s) then
        return false
    end
    
    table.insert(t, s)
    return true
end

-------------------------------------------
---------------- Settings -----------------
-------------------------------------------

local SMART_TARGET_WITHER = GetModConfigData("smart_target_wither") --target witherables only when too hot
local SMART_TARGET_CROPS = GetModConfigData("smart_target_crops") --target crops only when actually needed
local TARGET_CENTER = GetModConfigData("target_center") --target center of tile once instead of each crop
local WATER_PERCENT = GetModConfigData("water_percent") --water crops when tile moisture falls below this value
local ADD_WETNESS_AMOUNT = GetModConfigData("add_wetness") --snowballs add this much wetness

-------------------------------------------
---------- Find Existing Stuff ------------
-------------------------------------------

local my_NOTAGS
local my_NONEMERGENCYTAGS
local my_NONEMERGENCY_FIREONLY_TAGS
local my_RegisterDetectedItem

local function find_fdetector_upvalues(self)
    if my_RegisterDetectedItem then
        return
    end

    modprint("Upvalue hacking Activate for old LookForFiresAndFirestarters...")
    local old_LFFAF = UpvalueHacker.GetUpvalue(self.Activate, "LookForFiresAndFirestarters")
    modassert(old_LFFAF, "Old LookForFiresAndFirestarters not found in Activate!")

    modprint("Upvalue hacking old LookForFiresAndFirestarters for NOTAGS...")
    my_NOTAGS = UpvalueHacker.GetUpvalue(old_LFFAF, "NOTAGS")
    if not my_NOTAGS then
        modprint("NOTAGS not found in old LookForFiresAndFirestarters! Using default.")
        my_NOTAGS = {"FX", "NOCLICK", "DECOR", "INLIMBO", "burnt", "player", "monster"}
    end

    modprint("Upvalue hacking old LookForFiresAndFirestarters for NONEMERGENCYTAGS...")
    my_NONEMERGENCYTAGS = UpvalueHacker.GetUpvalue(old_LFFAF, "NONEMERGENCYTAGS")
    if not my_NONEMERGENCYTAGS then
        modprint("NONEMERGENCYTAGS not found in old LookForFiresAndFirestarters! Using default.")
        my_NONEMERGENCYTAGS = {"witherable", "fire", "smolder", "farmplantstress"} --target farm crops
    elseif insertifnotexist(my_NONEMERGENCYTAGS, "farmplantstress") then --target farm crops
        modprint("Added \"farmplantstress\" tag to existing NONEMERGENCYTAGS.")
    else
        modprint("Found \"farmplantstress\" tag in existing NONEMERGENCYTAGS.")
    end

    modprint("Upvalue hacking old LookForFiresAndFirestarters for NONEMERGENCY_FIREONLY_TAGS...")
    my_NONEMERGENCY_FIREONLY_TAGS = UpvalueHacker.GetUpvalue(old_LFFAF, "NONEMERGENCY_FIREONLY_TAGS")
    if not my_NONEMERGENCY_FIREONLY_TAGS then
        modprint("NONEMERGENCY_FIREONLY_TAGS not found in old LookForFiresAndFirestarters! Using default.")
        my_NONEMERGENCY_FIREONLY_TAGS = {"fire", "smolder"}
    end

    modprint("Upvalue hacking old LookForFiresAndFirestarters for RegisterDetectedItem...")
    my_RegisterDetectedItem = UpvalueHacker.GetUpvalue(old_LFFAF, "RegisterDetectedItem")
    if not my_RegisterDetectedItem then
        modprint("RegisterDetectedItem not found in old LookForFiresAndFirestarters! Using default.")
        my_RegisterDetectedItem = function(inst, self, target)
            self.detectedItems[target] = inst:DoTaskInTime(2,
                function(inst, self, target)
                    self.detectedItems[target] = nil
                end, self, target)
        end
    end
end

-------------------------------------------
--------------- New Stuff -----------------
-------------------------------------------

local function GetCenterCoord(target) --helper function
    return _G.TheWorld.Map:GetTileCenterPoint(target.Transform:GetWorldPosition())
end

local function SoilCoord(target) --returns a string unique to crop's map tile or nil
    if TARGET_CENTER and target and target:HasTag("farmplantstress") then
        local x, y, z = GetCenterCoord(target)
        return string.format("%d,%d", x, z)
    end
    return nil
end

local is_point_dry --set to appropriate fn based on settings
if WATER_PERCENT > 0.0 and not SMART_TARGET_CROPS then --need to acquire GetTileDataAtPoint and define GetSoilMoistureAtPoint
    AddClassPostConstruct("components/farming_manager", function(self)
        modprint("Checking for GetSoilMoistureAtPoint...")
        if self.GetSoilMoistureAtPoint then
            modprint("GetSoilMoistureAtPoint found.")
        else
            modprint("GetSoilMoistureAtPoint not found. Upvalue hacking OnSave for _moisturegrid...")
            local _moisturegrid = UpvalueHacker.GetUpvalue(self.OnSave, "_moisturegrid")
            modassert(_moisturegrid, "_moisturegrid not found in OnSave!")\

            function self:GetSoilMoistureAtPoint(x, y, z)
                local tx, ty = _G.TheWorld.Map:GetTileCoordsAtPoint(x, y, z)
                return _moisturegrid:GetDataAtPoint(tx, ty) or _G.TheWorld.state.wetness
            end
            modprint("Defined GetSoilMoistureAtPoint.")
        end
    end)

    is_point_dry = function(x, y, z)
        return _G.TheWorld.components.farming_manager:GetSoilMoistureAtPoint(x, y, z) < WATER_PERCENT
    end
else
    is_point_dry = function(x, y, z)
        return not _G.TheWorld.components.farming_manager:IsSoilMoistAtPoint(x, y, z)
    end
end

-------------------------------------------
------------- Changed Stuff ---------------
-------------------------------------------

local function CheckTargetScore(target) --added crops; smarter witherable handling
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
    if w and not w:IsProtected() then
        if w:CanWither() then
            if not SMART_TARGET_WITHER or _G.TheWorld.state.temperature >= w.wither_temp then --option to skip if not hot
                return 8
            end
        elseif w:CanRejuvenate() then
            return 7
        end
    end

    local ps = target.components.farmplantstress
    if ps and ps.stressors.moisture then --only target plants that require moisture
        local thirsty = not SMART_TARGET_CROPS or --option to skip if plant doesn't need water right now
            ps.stressors_testfns.moisture and ps.stressors_testfns.moisture(target, ps.stressors.moisture, false) and --moisture need is unmet
            (not target.components.growable or target.components.growable:GetCurrentStageData().tendable) --only target growing crops

        if thirsty and is_point_dry(target.Transform:GetWorldPosition()) then --plant needs watering and soil is dry
            return 8
        end
    end

    return 0
end

local function LookForFiresAndFirestarters(inst, self, force) --allow targeting of soil instead of individual crops
    if not force and inst.sg ~= nil and inst.sg:HasStateTag("busy") then
        return
    end
    local x, y, z = inst.Transform:GetWorldPosition()
    local ents = _G.TheSim:FindEntities(x, y, z, self.range, nil, my_NOTAGS, (self.fireOnly and my_NONEMERGENCY_FIREONLY_TAGS) or my_NONEMERGENCYTAGS)
    local target = nil
    local targetscore = 0
    for i, v in ipairs(ents) do
        local sc = SoilCoord(v) --use center of target's tile when TARGET_CENTER
        if not self.detectedItems[v] and not (sc and self.detectedItems[sc]) then
            local score, force = CheckTargetScore(v)
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
            my_RegisterDetectedItem(inst, self, sc) --register the string
            if self.onfindfire ~= nil then
                local x, y, z = GetCenterCoord(target)
                self.onfindfire(inst, _G.Point(x, 0, z))
            end
        else --use position of entity
            my_RegisterDetectedItem(inst, self, target)
            if self.onfindfire ~= nil then
                self.onfindfire(inst, target:GetPosition())
            end
        end
    end
end

-------------------------------------------
---------------- Finally ------------------
-------------------------------------------

AddClassPostConstruct("components/firedetector", function(self)
    find_fdetector_upvalues(self)
    modprint("Replacing LookForFiresAndFirestarters in firedetector component.")
    UpvalueHacker.SetUpvalue(self.Activate, LookForFiresAndFirestarters, "LookForFiresAndFirestarters")
end)

AddPrefabPostInit("firesuppressor", function(inst)
    inst.components.wateryprotection.addwetness = ADD_WETNESS_AMOUNT
end)

AddPrefabPostInit("snowball", function(inst)
    inst.components.wateryprotection.addwetness = ADD_WETNESS_AMOUNT
end)
