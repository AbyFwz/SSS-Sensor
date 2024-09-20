-- media/lua/client/TimedActions/ISToggleSensor.lua

require "TimedActions/Sensor/ISBaseSensorTimedAction"

ISToggleSensor = ISBaseSensorTimedAction:derive("ISToggleSensor")

function ISToggleSensor:new(character, sensor)
    local o = ISBaseSensorTimedAction.new(self, character, sensor)
    o.maxTime = 30
    return o
end

function ISToggleSensor:perform()
    if self:isValid() then
        SensorManagerClient.toggleSensor(self.sensor)
        local state = self.sensor.isActive and "on" or "off"
        self.character:Say(getText("IGUI_SensorToggled", state))
    end
    ISBaseSensorTimedAction.perform(self)
end

return ISToggleSensor