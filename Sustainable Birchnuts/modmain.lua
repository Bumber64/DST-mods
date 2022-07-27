
PrefabFiles =
{
    "rotten_acorn",
}

local _G = GLOBAL

_G.STRINGS.NAMES.ROTTEN_ACORN = "Rotten Birchnut"
for _, v in pairs(_G.STRINGS.CHARACTERS) do
    v.DESCRIBE.ROTTEN_ACORN = v.DESCRIBE.ACORN
end

if not _G.TheNet:GetIsServer() then
    return
end

local BONUS_ACORN_CHANCE = GetModConfigData("bonus_acorn_chance")
local ROTTEN_ACORNS = GetModConfigData("rotten_acorns")

if BONUS_ACORN_CHANCE > 0.0 then
    local function bonus_acorn(inst, chopper)
        if not inst.monster and inst.components.growable and inst.components.growable.stage > 1 and math.random() < BONUS_ACORN_CHANCE then
            if (chopper:GetPosition() - inst:GetPosition()):Dot(_G.TheCamera:GetRightVec()) > 0 then
                inst.components.lootdropper:SpawnLootPrefab("acorn", inst:GetPosition() - _G.TheCamera:GetRightVec())
            else
                inst.components.lootdropper:SpawnLootPrefab("acorn", inst:GetPosition() + _G.TheCamera:GetRightVec())
            end
        end
    end

    AddPrefabPostInit("deciduoustree", function(inst)
        local old_work_fn = inst.components.workable and inst.components.workable.onfinish
        if old_work_fn then
            inst.components.workable:SetOnFinishCallback(function(inst, chopper)
                bonus_acorn(inst, chopper)
                old_work_fn(inst, chopper)
            end)
        end
    end)
end

if ROTTEN_ACORNS then
    AddPrefabPostInit("acorn", function(inst)
        if inst.components.perishable then
            inst.components.perishable.onperishreplacement = "rotten_acorn"
        end
    end)
end
