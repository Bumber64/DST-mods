
if not GLOBAL.TheNet:GetIsServer() then
    return
end

local function Beeify(inst)
    if not inst:IsValid() then
        return nil
    end

    local bee = GLOBAL.SpawnPrefab("bee")
    if not bee then
        return nil
    end

    local holder = nil
    bee.Transform:SetPosition(inst.Transform:GetWorldPosition())

    if bee.components.stackable and inst.components.stackable then
        bee.components.stackable:SetStackSize(inst.components.stackable.stacksize)
    end
    if bee.components.perishable and inst.components.perishable then
        bee.components.perishable:SetPercent(inst.components.perishable:GetPercent())
    end
    if bee.components.inventoryitem and inst.components.inventoryitem then
        holder = inst.components.inventoryitem:GetContainer()
        bee.components.inventoryitem:InheritMoisture(inst.components.inventoryitem:GetMoisture(), inst.components.inventoryitem:IsWet())
    end

    inst:Remove()
    if holder then
        holder:GiveItem(bee)
    end
end

AddPrefabPostInit("killerbee", function(inst)
    inst:ListenForEvent("onputininventory", function(inst)
        inst:DoTaskInTime(0, function() Beeify(inst) end)
    end)
end)
