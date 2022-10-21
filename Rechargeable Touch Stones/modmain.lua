
local _G = GLOBAL
if not _G.TheNet:GetIsServer() then
    return
end

local REPAIR_TYPE = GetModConfigData("repair_type") --0:Amulet, 1:TelltalePenalty, 2:TelltaleNoPenalty

AddComponentPostInit("touchstonetracker", function(self)
    function self:RepairTouchStone(touchstone)
        local id = touchstone and touchstone.GetTouchStoneID and touchstone:GetTouchStoneID() or 0
        if id > 0 then
            self.used[id] = nil
            if self.inst.player_classified then
                local used = {}
                for k, v in pairs(self.used) do
                    table.insert(used, k)
                end
                self.inst.player_classified:SetUsedTouchStones(used)
            end
        end
    end
end)

local REPAIR_ITEM = REPAIR_TYPE == 0 and "amulet" or "reviver"
local function accepttest(inst, item, giver)
    if not inst.AnimState:IsCurrentAnimation("idle_activate") then
        return false, "BUSY"
    elseif not item or item.prefab ~= REPAIR_ITEM then
        return false, "GENERIC"
    elseif not giver.CanUseTouchStone or giver:CanUseTouchStone(inst) then
        return false, "SLOTFULL"
    else
        return true
    end
end

local function onacceptitem(inst, giver, item)
    local ts = giver.components.touchstonetracker
    if ts then
        ts:RepairTouchStone(inst)
    end

    local h = REPAIR_TYPE == 1 and TUNING.HEALTH_PENALTY_ENABLED and giver.components.health
    if h then
        h:DeltaPenalty(TUNING.REVIVE_HEALTH_PENALTY)
    end
end

AddPrefabPostInit("resurrectionstone", function(inst)
    inst:AddComponent("trader")
    inst.components.trader:SetAbleToAcceptTest(accepttest)
    inst.components.trader.onaccept = onacceptitem
    inst.components.trader.acceptnontradable = true
end)
