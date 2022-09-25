
local function SpawnGrueAlert(parent)
    if not parent then
        return
    end

    local inst = CreateEntity()

    inst.prefab = "grue_alert"
    inst.entity:SetCanSleep(false)
    inst.persists = false

    inst.entity:AddTransform()
    inst.entity:AddAnimState()

    inst:AddTag("CLASSIFIED")
    inst:AddTag("NOCLICK")
    inst:AddTag("NOBLOCK")

    inst.AnimState:SetBank("winona_battery_placement")
    inst.AnimState:SetBuild("winona_battery_placement")
    inst.AnimState:PlayAnimation("idle")
    inst.AnimState:SetLightOverride(1)
    inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
    inst.AnimState:SetLayer(LAYER_BACKGROUND)
    inst.AnimState:SetSortOrder(1)
    inst.AnimState:SetScale(0, 0)
    inst.AnimState:SetAddColour(1,0,0,0)
    inst.entity:SetParent(parent.entity)

    for i=0, 8 do
        inst:DoTaskInTime(FRAMES*i, function(inst)
            inst.AnimState:SetScale(i/8, i/8)
        end)
        inst:DoTaskInTime(FRAMES*(i+9), function(inst)
            inst.AnimState:SetScale(1-i/8, 1-i/8)
        end)
    end

    inst:DoTaskInTime(0.5, function(inst)
        inst:Remove()
    end)

    return inst
end

return SpawnGrueAlert
