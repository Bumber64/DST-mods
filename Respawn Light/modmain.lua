
local _G = GLOBAL
if not _G.TheNet:GetIsServer() then
    return
end

AddPlayerPostInit(function(inst)
    inst:ListenForEvent("ms_respawnedfromghost", function(inst)
        local x, y, z = inst.Transform:GetWorldPosition()
        if x and not _G.TheWorld.state.isday and #_G.TheSim:FindEntities(x, y, z, 4, {"spawnlight"}) <= 0 then
            _G.SpawnPrefab("spawnlight_multiplayer").Transform:SetPosition(x, y, z)
        end
    end)
end)
