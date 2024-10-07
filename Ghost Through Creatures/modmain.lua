
local _G = GLOBAL
if not _G.TheNet:GetIsServer() then
    return
end

local function CustomGhostPhysics(inst)
    local phys = inst.Physics
    phys:ClearCollisionMask()
    phys:CollidesWith(_G.COLLISION.GROUND)

    return phys
end

AddPlayerPostInit(function(inst)
    inst:ListenForEvent("ms_becameghost", CustomGhostPhysics)
end)
