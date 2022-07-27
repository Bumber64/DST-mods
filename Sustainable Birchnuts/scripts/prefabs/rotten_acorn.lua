require "prefabutil"

local assets =
{
    Asset("ANIM", "anim/acorn.zip"),
}

local prefabs =
{
    "acorn_sapling",
    "winter_deciduoustree",
}

local function plant(inst, growtime)
    local sapling = SpawnPrefab("acorn_sapling")
    sapling:StartGrowing()
    sapling.Transform:SetPosition(inst.Transform:GetWorldPosition())
    sapling.SoundEmitter:PlaySound("dontstarve/wilson/plant_tree")
    inst:Remove()
end

local function domonsterstop(ent)
    ent.monster_stop_task = nil
    ent:StopMonster()
end

local PACIFYTARGET_MUST_TAGS = {"birchnut", "monster"}
local PACIFYTARGET_CANT_TAGS = {"stump", "burnt", "FX", "NOCLICK","DECOR","INLIMBO"}
local function ondeploy(inst, pt)
    inst = inst.components.stackable:Get()
    inst.Transform:SetPosition(pt:Get())
    local timeToGrow = GetRandomWithVariance(TUNING.ACORN_GROWTIME.base, TUNING.ACORN_GROWTIME.random)
    plant(inst, timeToGrow)

    -- Pacify a nearby monster tree
    local ent = FindEntity(inst, TUNING.DECID_MONSTER_ACORN_CHILL_RADIUS, nil, PACIFYTARGET_MUST_TAGS, PACIFYTARGET_CANT_TAGS)
    if ent ~= nil then
        if ent.monster_start_task ~= nil then
            ent.monster_start_task:Cancel()
            ent.monster_start_task = nil
        end
        if ent.monster and
            ent.monster_stop_task == nil and
            not (ent.components.burnable ~= nil and ent.components.burnable:IsBurning()) and
            not (ent:HasTag("stump") or ent:HasTag("burnt")) then
            ent.monster_stop_task = ent:DoTaskInTime(math.random(0, 3), domonsterstop)
        end
    end
end

local function OnLoad(inst, data)
    if data and data.growtime then
        plant(inst, data.growtime)
    end
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("acorn")
    inst.AnimState:SetBuild("acorn")
    inst.AnimState:PlayAnimation("idle")

    inst:AddTag("deployedplant")
    inst:AddTag("icebox_valid")
    inst:AddTag("cattoy")
    inst:AddTag("treeseed")

    MakeInventoryFloatable(inst, "small", 0.15)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("tradable")

    inst:AddComponent("stackable")
    inst.components.stackable.maxsize = TUNING.STACK_SIZE_SMALLITEM

    inst:AddComponent("inspectable")

    MakeSmallBurnable(inst, TUNING.SMALL_BURNTIME)
    MakeSmallPropagator(inst)

    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.imagename = "acorn"

    inst:AddComponent("deployable")
    inst.components.deployable:SetDeployMode(DEPLOYMODE.PLANT)
    inst.components.deployable.ondeploy = ondeploy

    inst:AddComponent("winter_treeseed")
    inst.components.winter_treeseed:SetTree("winter_deciduoustree")

    inst:AddComponent("forcecompostable")
    inst.components.forcecompostable.brown = true

    MakeHauntableLaunchAndIgnite(inst)

    inst.OnLoad = OnLoad

    return inst
end

return Prefab("rotten_acorn", fn, assets, prefabs),
       MakePlacer("rotten_acorn_placer", "acorn", "acorn", "idle_planted")
