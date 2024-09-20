-- media/lua/client/TimedActions/ISRemoveSensorItemBatteryAction.lua

require "TimedActions/SensorItems/ISBaseSensorItemAction"

ISRemoveSensorItemBatteryAction = ISBaseSensorItemAction:derive("ISRemoveSensorItemBatteryAction")

function ISRemoveSensorItemBatteryAction:new(character, item)
    return ISBaseSensorItemAction.new(self, character, item, 80)
end

function ISRemoveSensorItemBatteryAction:isValid()
    return ISBaseSensorItemAction.isValid(self) and self.item:getUsedDelta() > 0
end

function ISRemoveSensorItemBatteryAction:perform()
    local battery = InventoryItemFactory.CreateItem("Base.Battery")
    if battery then
        local usedDelta = self.item:getUsedDelta()
        battery:setUsedDelta(usedDelta)
        self.character:getInventory():AddItem(battery)
        self.item:setUsedDelta(0.0)  -- Set the item to be empty
        self.character:Say("Removed the battery from " .. self.item:getName() .. " with " .. (usedDelta * 100) .. "% charge remaining.")
    else
        self.character:Say("Failed to create a battery item.")
    end
    ISBaseSensorItemAction.perform(self)
end

return ISRemoveSensorItemBatteryAction