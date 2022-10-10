
local function light_test(self)
    local in_light = self.inst:IsInLight()
    if self.in_light ~= in_light then
        self.in_light = in_light
        if in_light then
            self.inst:PushEvent("enterlight")
        else
            self.inst:PushEvent("enterdark")
        end
    end
end

local CLWatcher = Class(function(self, inst)
    self.inst = inst
    self.interval = 0.5

    self:Start()
end)

function CLWatcher:OnRemoveFromEntity()
    if self.task then
        self.task:Cancel()
        self.task = nil
    end
end

function CLWatcher:Start()
    if self.task then
        return
    end

    self.in_light = self.inst:IsInLight()
    if self.in_light then
        self.inst:PushEvent("enterlight")
    else
        self.inst:PushEvent("enterdark")
    end

    self.task = self.inst:DoPeriodicTask(self.interval, function() light_test(self) end)
end

function CLWatcher:Stop()
    if self.task then
        self.task:Cancel()
        self.task = nil
    end
end

return CLWatcher
