-- media/lua/client/TimedActions/ISInsertSensorItemBatteryAction.lua

require "TimedActions/SensorItems/ISBaseSensorItemAction"

ISInsertSensorItemBatteryAction = ISBaseSensorItemAction:derive("ISInsertSensorItemBatteryAction")

function ISInsertSensorItemBatteryAction:new(character, item)
    return ISBaseSensorItemAction.new(self, character, item, 100)
end

function ISInsertSensorItemBatteryAction:isValid()
    return ISBaseSensorItemAction.isValid(self) and self.character:getInventory():contains("Base.Battery") and self.item:getUsedDelta() == 0
end

function ISInsertSensorItemBatteryAction:perform()
    local inventory = self.character:getInventory()
    local newBattery = inventory:FindAndReturn("Base.Battery")

    if newBattery then
        self.item:setUsedDelta(newBattery:getUsedDelta())
        inventory:Remove(newBattery)
        self.character:Say("Added a battery to " .. self.item:getName() .. ".")
    else
        self.character:Say("No battery found in inventory.")
    end
    ISBaseSensorItemAction.perform(self)
end

return ISInsertSensorItemBatteryAction