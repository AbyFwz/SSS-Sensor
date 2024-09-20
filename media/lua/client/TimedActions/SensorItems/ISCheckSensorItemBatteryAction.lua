-- media/lua/client/TimedActions/ISCheckSensorItemBatteryAction.lua

require "TimedActions/SensorItems/ISBaseSensorItemAction"

ISCheckSensorItemBatteryAction = ISBaseSensorItemAction:derive("ISCheckSensorItemBatteryAction")

function ISCheckSensorItemBatteryAction:new(character, item)
    return ISBaseSensorItemAction.new(self, character, item, 25)
end

function ISCheckSensorItemBatteryAction:perform()
    local batteryLevel = self.item:getUsedDelta() * 100
    self.character:Say(string.format("Sensor battery level: %.1f%%", batteryLevel))
    ISBaseSensorItemAction.perform(self)
end

return ISCheckSensorItemBatteryAction