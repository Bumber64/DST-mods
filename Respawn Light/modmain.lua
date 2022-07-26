
if not GLOBAL.TheNet:GetIsServer() then
    return
end

AddPlayerPostInit(function(inst)
    inst:ListenForEvent("ms_respawnedfromghost", function(inst)
        local x, y, z = inst.Transform:GetWorldPosition()
        if x and not GLOBAL.TheWorld.state.isday and #GLOBAL.TheSim:FindEntities(x, y, z, 4, {"spawnlight"}) <= 0 then
            GLOBAL.SpawnPrefab("spawnlight_multiplayer").Transform:SetPosition(x, y, z)
        end
    end)
end)
