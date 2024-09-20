-- media/lua/client/TimedActions/ISBaseSensorItemAction.lua

require "TimedActions/ISBaseTimedAction"

ISBaseSensorItemAction = ISBaseTimedAction:derive("ISBaseSensorItemAction")

function ISBaseSensorItemAction:new(character, item, time)
    local o = {}
    setmetatable(o, self)
    self.__index = self
    o.character = character
    o.item = item
    o.maxTime = time
    o.stopOnWalk = false
    o.stopOnRun = true
    o.actionAnim = "Craft"
    return o
end

function ISBaseSensorItemAction:isValid()
    return self.character:getInventory():contains(self.item)
end

function ISBaseSensorItemAction:start()
    self:setActionAnim(self.actionAnim)
    self:setOverrideHandModels(self.item, nil)
    self.character:playSound("CheckSensor")
end

function ISBaseSensorItemAction:update()
    self.item:setJobDelta(self:getJobDelta())
    self.character:setMetabolicTarget(Metabolics.LightWork)
end

function ISBaseSensorItemAction:stop()
    self.item:setJobDelta(0.0)
    ISBaseTimedAction.stop(self)
end

function ISBaseSensorItemAction:perform()
    self.item:setJobDelta(0.0)
    ISBaseTimedAction.perform(self)
end

return ISBaseSensorItemAction