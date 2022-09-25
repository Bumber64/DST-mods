
local Widget = require("widgets/widget")
local Image = require("widgets/image")

local MOVE_TIME = 0.5 --Seconds for sub-icons to relocate
local DEFAULTS =
{
    scale = 1.4,
    h_anchor = ANCHOR_LEFT,
    v_anchor = ANCHOR_TOP,
    x = 0,
    y = 0,
}

local x_off, y_off --Center of bg_image w/r/t root, set in CreateIcon
local do_hovertext --Show hovertext or not, set in CreateIcon

local function math_sign(n)
    return n > 0 and 1 or n == 0 and 0 or -1
end

local function OnShowIcon(icon, was_hidden)
    if was_hidden then
        icon:SetPosition(x_off, y_off)
    end
end

local function free_icon(root) --Free nightvision
    local icon = root:AddChild(Image("images/inventoryimages2.xml", "molehat.tex"))
    icon:SetSize(48, 48)
    icon:SetTint(.2, .5, 1, .5)

    icon._arrange = function()
        if icon.shown then
            local dest = root.icons.mole.shown and Vector3(x_off+3, y_off-7, 0) or --Bottom right
                Vector3(x_off, y_off, 0) --Center
            icon:MoveTo(icon:GetPosition(), dest, MOVE_TIME)
        end
    end

    icon.OnShow = OnShowIcon
    icon:Hide()

    return icon
end

local function circuit_icon(root) --WX nightvision
    local icon = root:AddChild(Image("images/inventoryimages3.xml", "wx78module_nightvision.tex"))
    icon:SetSize(40, 40)

    icon._arrange = function()
        if icon.shown then
            local dest = root.icons.mole.shown and Vector3(x_off+5, y_off-5, 0) or --Bottom right
                Vector3(x_off, y_off, 0) --Center
            icon:MoveTo(icon:GetPosition(), dest, MOVE_TIME)
        end
    end

    icon.OnShow = OnShowIcon
    icon:Hide()

    return icon
end

local function mole_icon(root) --Moggles nightvision
    local icon = root:AddChild(Image("images/inventoryimages2.xml", "molehat.tex"))
    icon:SetSize(48, 48)

    icon._arrange = function()
        if icon.shown then
            local dest = (root.icons.free.shown or root.icons.circuit.shown) and Vector3(x_off-5, y_off+7, 0) or --Top left
                Vector3(x_off, y_off, 0) --Center
            icon:MoveTo(icon:GetPosition(), dest, MOVE_TIME)
        end
    end

    icon.OnShow = OnShowIcon
    icon:Hide()

    return icon
end

local function OnUpdateNV(root)
    local pv = ThePlayer.components.playervision

    if not pv then
        return
    elseif pv.nightvision then
        root.icons.mole:Show()
    else
        root.icons.mole:Hide()
    end

    if not pv.forcenightvision then
        root.icons.free:Hide()
        root.icons.circuit:Hide()
    elseif ThePlayer._forced_nightvision and ThePlayer._forced_nightvision:value() then
        root.icons.free:Hide()
        root.icons.circuit:Show()
    else
        root.icons.free:Show()
        root.icons.circuit:Hide()
    end

    for _, v in pairs(root.icons) do
        v._arrange()
    end

    if root.icons.free.shown or root.icons.circuit.shown or root.icons.mole.shown then
        root.bg_image:Show()
    else
        root.bg_image:Hide()
    end
end

local function CreateIcon(hud, params)
    local root = hud.under_root:AddChild(Widget("nightvisionicon"))

    if type(params) ~= "table" then
        params = DEFAULTS
    else
        for k, v in pairs(DEFAULTS) do
            if params[k] == nil then
                params[k] = v
            end
        end
    end

    x_off = params.h_anchor == ANCHOR_LEFT and 32 or
        params.h_anchor == ANCHOR_RIGHT and -32 or 0
    y_off = params.v_anchor == ANCHOR_BOTTOM and 32 or
        params.v_anchor == ANCHOR_TOP and -32 or 0
    do_hovertext = params.hovertext

    root:SetScale(params.scale)
    root:SetHAnchor(params.h_anchor)
    root:SetVAnchor(params.v_anchor)
    root:SetPosition(params.x, params.y)
    root:SetClickable(false)

    root.bg_image = root:AddChild(Image("images/hud.xml", "inv_slot_construction.tex"))
    root.bg_image:SetSize(64, 64)
    root.bg_image:SetPosition(x_off, y_off)
    root.bg_image:SetTint(1, 1, 1, .5)
    root.bg_image:Hide()

    root.icons =
    {
        free = free_icon(root),
        circuit = circuit_icon(root),
        mole = mole_icon(root),
    }

    root.inst:ListenForEvent("nv_change", function(inst)
        inst:DoTaskInTime(0, function() OnUpdateNV(root) end)
    end, ThePlayer)

    return root
end

return CreateIcon
