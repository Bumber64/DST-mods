
local _G = GLOBAL
if not _G.TheNet:GetIsServer() then
    return
end

local COLLISION = _G.COLLISION
local GHOST_ABYSS = GetModConfigData("ghost_abyss")
local GHOST_CHARS = GetModConfigData("ghost_chars")

local function CustomGhostPhysics(inst)
    local phys = inst.Physics
    phys:ClearCollisionMask()
    phys:CollidesWith(((GHOST_ABYSS or _G.TheWorld.has_ocean) and COLLISION.GROUND) or COLLISION.WORLD)

    if not GHOST_CHARS then
        phys:CollidesWith(COLLISION.CHARACTERS)
        phys:CollidesWith(COLLISION.GIANTS)
    end

    return phys
end

AddPlayerPostInit(function(inst)
    inst:ListenForEvent("ms_becameghost", CustomGhostPhysics)
end)
