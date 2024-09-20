-- media/lua/client/ISUI/SensorItemsContextMenu.lua

require "TimedActions/SensorItems/ISCheckSensorItemBatteryAction"
require "TimedActions/SensorItems/ISAddSensorItemBatteryAction"
require "TimedActions/SensorItems/ISReplaceSensorItemBatteryAction"
require "TimedActions/SensorItems/ISRemoveSensorItemBatteryAction"

local SensorUtil = require "SensorUtil"

SensorItemsContextMenu = {}

SensorItemsContextMenu.onSensorItemContextMenu = function(playerObj, context, items)
    local player = getSpecificPlayer(playerObj)
    for _, v in ipairs(items) do
        local item = v
        if not instanceof(v, "InventoryItem") then
            item = v.items[1]
        end
        if item and item:getType():find("Sensor_") then
            local sensorOption = context:addOption(item:getName(), item, nil)
            local subMenu = ISContextMenu:getNew(context)
            context:addSubMenu(sensorOption, subMenu)

            local hasBattery = player:getInventory():containsTypeRecurse("Battery")
            local batteryTooltip = getText("IGUI_ContextMenu_SensorItems_NoBattery")

            if item:getUsedDelta() == 0 then
                local addOption = subMenu:addOption(getText("IGUI_ContextMenu_SensorItems_AddBattery"), item, SensorItemsContextMenu.addBattery, player)
                if not hasBattery then
                    addOption.notAvailable = true
                    local tooltip = ISToolTip:new()
                    tooltip:setName(getText("IGUI_ContextMenu_SensorItems_AddBattery"))
                    tooltip.description = batteryTooltip
                    addOption.toolTip = tooltip
                end
            else
                subMenu:addOption(getText("IGUI_ContextMenu_SensorItems_CheckBatteryLevel"), item, SensorItemsContextMenu.checkBattery, player)
                local replaceOption = subMenu:addOption(getText("IGUI_ContextMenu_SensorItems_ReplaceBattery"), item, SensorItemsContextMenu.replaceBattery, player)
                if not hasBattery then
                    replaceOption.notAvailable = true
                    local tooltip = ISToolTip:new()
                    tooltip:setName(getText("IGUI_ContextMenu_SensorItems_ReplaceBattery"))
                    tooltip.description = batteryTooltip
                    replaceOption.toolTip = tooltip
                end
                subMenu:addOption(getText("IGUI_ContextMenu_SensorItems_RemoveBattery"), item, SensorItemsContextMenu.removeBattery, player)
            end
        end
    end
end

SensorItemsContextMenu.checkBattery = function(item, player)
    ISTimedActionQueue.add(ISCheckSensorItemBatteryAction:new(player, item))
end

SensorItemsContextMenu.addBattery = function(item, player)
    ISTimedActionQueue.add(ISInsertSensorItemBatteryAction:new(player, item))
end

SensorItemsContextMenu.replaceBattery = function(item, player)
    ISTimedActionQueue.add(ISReplaceSensorItemBatteryAction:new(player, item))
end

SensorItemsContextMenu.removeBattery = function(item, player)
    ISTimedActionQueue.add(ISRemoveSensorItemBatteryAction:new(player, item))
end

Events.OnFillInventoryObjectContextMenu.Add(SensorItemsContextMenu.onSensorItemContextMenu)

return SensorItemsContextMenu