-- media/lua/client/TimedActions/ISRemoveSensor.lua

require "TimedActions/Sensor/ISBaseSensorTimedAction"

ISRemoveSensor = ISBaseSensorTimedAction:derive("ISRemoveSensor")

function ISRemoveSensor:new(character, sensor)
    local o = ISBaseSensorTimedAction.new(self, character, sensor)
    o.maxTime = 80
    return o
end

function ISRemoveSensor:perform()
    if self:isValid() then
        if SensorManagerClient.removeSensor(self.sensor) then
            self.character:Say(getText("IGUI_SensorRemoved"))
            -- Add the sensor item to the player's inventory
            local sensor = self.character:getInventory():AddItem("Base.Sensor_" .. self.sensor.sensorType)
            sensor:setUsedDelta(self.sensor.batteryLevel / 100)
        else
            self.character:Say(getText("IGUI_SensorRemoveFailed"))
        end
    end
    ISBaseSensorTimedAction.perform(self)
end

return ISRemoveSensor