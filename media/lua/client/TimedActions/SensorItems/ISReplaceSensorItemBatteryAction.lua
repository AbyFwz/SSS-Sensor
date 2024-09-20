-- media/lua/client/TimedActions/ISReplaceSensorItemBatteryAction.lua

require "TimedActions/SensorItems/ISBaseSensorItemAction"

ISReplaceSensorItemBatteryAction = ISBaseSensorItemAction:derive("ISReplaceSensorItemBatteryAction")

function ISReplaceSensorItemBatteryAction:new(character, item)
    return ISBaseSensorItemAction.new(self, character, item, 120)
end

function ISReplaceSensorItemBatteryAction:isValid()
    return ISBaseSensorItemAction.isValid(self) and self.character:getInventory():contains("Base.Battery") and self.item:getUsedDelta() > 0
end

function ISReplaceSensorItemBatteryAction:perform()
    local inventory = self.character:getInventory()
    local newBattery = inventory:FindAndReturn("Base.Battery")

    if newBattery then
        local oldBattery = InventoryItemFactory.CreateItem("Base.Battery")
        if oldBattery then
            oldBattery:setUsedDelta(self.item:getUsedDelta())
            inventory:AddItem(oldBattery)
            self.item:setUsedDelta(newBattery:getUsedDelta())
            inventory:Remove(newBattery)
            self.character:Say("Replaced the battery in " .. self.item:getName() .. ".")
        else
            self.character:Say("Failed to create an old battery item.")
        end
    else
        self.character:Say("No battery found in inventory.")
    end
    ISBaseSensorItemAction.perform(self)
end

return ISReplaceSensorItemBatteryAction