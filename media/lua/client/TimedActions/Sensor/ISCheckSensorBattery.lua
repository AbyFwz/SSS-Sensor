-- media/lua/client/TimedActions/ISCheckSensorBattery.lua

require "TimedActions/Sensor/ISBaseSensorTimedAction"

ISCheckSensorBattery = ISBaseSensorTimedAction:derive("ISCheckSensorBattery")

function ISCheckSensorBattery:new(character, sensor)
    local o = ISBaseSensorTimedAction.new(self, character, sensor)
    o.maxTime = 50
    return o
end

function ISCheckSensorBattery:perform()
    if self:isValid() then
        self.character:Say(getText("IGUI_SensorBatteryLevel", math.floor(self.sensor.batteryLevel)))
    end
    ISBaseSensorTimedAction.perform(self)
end

return ISCheckSensorBattery