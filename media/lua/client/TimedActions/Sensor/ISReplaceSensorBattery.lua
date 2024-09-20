-- media/lua/client/TimedActions/ISReplaceSensorBattery.lua

require "TimedActions/Sensor/ISBaseSensorTimedAction"

ISReplaceSensorBattery = ISBaseSensorTimedAction:derive("ISReplaceSensorBattery")

function ISReplaceSensorBattery:new(character, sensor)
    local o = ISBaseSensorTimedAction.new(self, character, sensor)
    o.maxTime = 80
    return o
end

function ISReplaceSensorBattery:isValid()
    return ISBaseSensorTimedAction.isValid(self) and
           self.character:getInventory():containsTypeRecurse("Battery")
end

function ISReplaceSensorBattery:perform()
    if self:isValid() then
        local battery = self.character:getInventory():getFirstTypeRecurse("Battery")
        if battery then
            local oldBatteryLevel = self.sensor.batteryLevel
            self.sensor.batteryLevel = battery:getUsedDelta() * 100
            self.character:getInventory():Remove(battery)

            -- If the old battery had some charge, give the player a partially used battery
            if oldBatteryLevel > 0 then
                local oldBattery = self.character:getInventory():AddItem("Base.Battery")
                oldBattery:setUsedDelta(oldBatteryLevel / 100)
            end

            self.character:Say(getText("IGUI_SensorBatteryReplaced"))

            if isClient() then
                sendClientCommand("SensorManager", "UpdateSensorBattery", {
                    x = self.sensor.x,
                    y = self.sensor.y,
                    z = self.sensor.z,
                    batteryLevel = self.sensor.batteryLevel
                })
            end
        end
    end
    ISBaseSensorTimedAction.perform(self)
end

return ISReplaceSensorBattery