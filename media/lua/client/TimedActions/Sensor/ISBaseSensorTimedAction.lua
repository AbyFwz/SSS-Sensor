-- media/lua/client/TimedActions/ISBaseSensorTimedAction.lua

require "TimedActions/ISBaseTimedAction"

ISBaseSensorTimedAction = ISBaseTimedAction:derive("ISBaseSensorTimedAction")

function ISBaseSensorTimedAction:new(character, sensor)
    local o = {}
    setmetatable(o, self)
    self.__index = self
    o.character = character
    o.sensor = sensor
    o.maxTime = 50
    o.stopOnWalk = true
    o.stopOnRun = true
    o.actionAnim = "Loot"
    return o
end

function ISBaseSensorTimedAction:isValid()
    return self.character:getInventory():containsTypeRecurse("Sensor")
        and self.sensor
        -- and self.sensor.square
        -- and self.sensor.square:DistToProper(self.character:getCurrentSquare()) < 2
end

function ISBaseSensorTimedAction:update()
    self.character:faceLocation(self.sensor.x, self.sensor.y)
end

function ISBaseSensorTimedAction:start()
    self.character:faceLocation(self.sensor.x, self.sensor.y)
end

function ISBaseSensorTimedAction:stop()
    ISBaseTimedAction.stop(self)
end

function ISBaseSensorTimedAction:perform()
    ISBaseTimedAction.perform(self)
end

return ISBaseSensorTimedAction