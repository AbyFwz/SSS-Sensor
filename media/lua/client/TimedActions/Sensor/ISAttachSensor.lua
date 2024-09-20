-- media/lua/client/TimedActions/ISAttachSensor.lua

require "TimedActions/ISBaseTimedAction"

ISAttachSensor = ISBaseTimedAction:derive("ISAttachSensor")

function ISAttachSensor:new(character, object, sensorItem)
    local o = {}
    setmetatable(o, self)
    self.__index = self
    o.character = character
    o.object = object
    o.sensorItem = sensorItem
    o.maxTime = 50
    o.stopOnWalk = true
    o.stopOnRun = true
    return o
end

function ISAttachSensor:isValid()
    return self.character:getInventory():contains(self.sensorItem)
        and self.object
        and not self.object:isDestroyed()
end

function ISAttachSensor:waitToStart()
    self.character:faceThisObject(self.object)
    return self.character:shouldBeTurning()
end

function ISAttachSensor:start()
    self:setActionAnim("Loot")
    -- self.character:setAnimVariable("LootPosition", "Low")
end

function ISAttachSensor:update()
    self.character:faceThisObject(self.object)
end

function ISAttachSensor:stop()
    ISBaseTimedAction.stop(self)
    -- self.character:setAnimVariable("LootPosition", "")
end

function ISAttachSensor:perform()
    -- self.character:setAnimVariable("LootPosition", "")

    if self:isValid() then
        local square = self.object:getSquare()
        local sensor = SensorManagerClient.createSensor(self.sensorItem:getType(), (self.sensorItem:getUsedDelta() * 100), self.character:getUsername(), self.object)
        if sensor then
            self.character:getInventory():Remove(self.sensorItem)
            self.character:playSound("SensorAttached")
            self.character:Say(getText("IGUI_SensorAttached"))

            sensor.attachedObject = self.object
            print("Sensor attached to object at " .. square:getX() .. "," .. square:getY() .. "," .. square:getZ())
        else
            self.character:Say(getText("IGUI_SensorAttachFailed"))
        end
    else
        self.character:Say(getText("IGUI_SensorAttachInvalid"))
    end

    ISBaseTimedAction.perform(self)
end

return ISAttachSensor