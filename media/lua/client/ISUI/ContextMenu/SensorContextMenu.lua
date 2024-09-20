-- media/lua/client/ISUI/SensorContextMenu.lua

local SensorManagerClient = require "SensorManagerClient"
local SensorUtil = require "SensorUtil"
require "TimedActions/Sensor/ISCheckSensorBattery"
require "TimedActions/Sensor/ISToggleSensor"
require "TimedActions/Sensor/ISRemoveSensor"
require "TimedActions/Sensor/ISAttachSensor"
require "TimedActions/Sensor/ISReplaceSensorBattery"

SensorContextMenu = {}

SensorContextMenu.isDoorOrGate = function(object)
    return instanceof(object, "IsoDoor") or (instanceof(object, "IsoThumpable") and object:isDoor())
end

SensorContextMenu.isSensorItem = function(item)
    return item:getType():find("Sensor_")
end

SensorContextMenu.onFillWorldObjectContextMenu = function(player, context, worldobjects, test)
    local playerObj = getSpecificPlayer(player)
    if not playerObj then return end

    local validObject = nil
    local sensorOnDoor = nil

    for _, object in ipairs(worldobjects) do
        if SensorContextMenu.isDoorOrGate(object) then
            validObject = object
            local square = object:getSquare()
            if square then
                sensorOnDoor = SensorManagerClient.getSensorAtSquare(square)
            end
            break
        end
    end

    if validObject then
        if sensorOnDoor then
            SensorContextMenu.addSensorOptions(context, sensorOnDoor, validObject, playerObj)
        else
            SensorContextMenu.addAttachSensorOption(context, validObject, playerObj)
        end
    end

    if isDebugEnabled() then
        local sensorDebug = context:addOption("[Debug] Load Sensor State", playerObj, SensorManagerClient.loadState)
        local sensorDebug = context:addOption("[Debug] Clear Sensor State", playerObj, SensorManagerClient.clearModData)
        -- local subMenu = ISContextMenu.getNew(context)
        -- context:addSubMenu(sensorDebug, subMenu)

        -- subMenu:addOption("Load Sensor State", playerObj, SensorManagerClient.loadState)
    end
end

SensorContextMenu.addSensorOptions = function(context, sensor, object, playerObj)
    local sensorOption = context:addOption(getText("IGUI_ContextMenu_SensorObject_SensorOptions"), worldobjects, nil)
    local subMenu = ISContextMenu:getNew(context)
    context:addSubMenu(sensorOption, subMenu)

    subMenu:addOption(getText("IGUI_ContextMenu_SensorObject_CheckBattery"), playerObj, SensorContextMenu.onCheckBattery, object, sensor)

    local toggleText = sensor.isActive and getText("IGUI_ContextMenu_SensorObject_TurnOffSensor") or getText("IGUI_ContextMenu_SensorObject_TurnOnSensor")
    subMenu:addOption(toggleText, playerObj, SensorContextMenu.onToggleSensor, object, sensor)

    local replaceBatteryOption = subMenu:addOption(getText("IGUI_ContextMenu_SensorObject_ReplaceBattery"), playerObj, SensorContextMenu.onReplaceBattery, object, sensor)
    if not playerObj:getInventory():containsTypeRecurse("Battery") then
        replaceBatteryOption.notAvailable = true
        replaceBatteryOption.toolTip = ISToolTip:new()
        replaceBatteryOption.toolTip:setVisible(false)
        replaceBatteryOption.toolTip:setName(getText("IGUI_ContextMenu_SensorObject_ReplaceBattery"))
        replaceBatteryOption.toolTip:setTexture("Item_Battery")
        replaceBatteryOption.toolTip.description = getText("IGUI_ContextMenu_SensorObject_NeedBattery")
    end

    subMenu:addOption(getText("IGUI_ContextMenu_SensorObject_RemoveSensor"), playerObj, SensorContextMenu.onRemoveSensor, object, sensor)
end

SensorContextMenu.addAttachSensorOption = function(context, object, playerObj)
    local attachOption = context:addOption(getText("IGUI_ContextMenu_SensorObject_AttachSensor"), worldobjects, nil)
    local subMenu = ISContextMenu:getNew(context)
    context:addSubMenu(attachOption, subMenu)

    local inventory = playerObj:getInventory()
    local sensorItems = inventory:getItems()
    local hasSensors = false

    for i = 0, sensorItems:size() - 1 do
        local item = sensorItems:get(i)
        if SensorContextMenu.isSensorItem(item) then
            hasSensors = true
            subMenu:addOption(item:getName(), playerObj, SensorContextMenu.onAttachSensor, object, item)
        end
    end

    if not hasSensors then
        local option = subMenu:addOption(getText("IGUI_ContextMenu_SensorObject_NoSensorsAvailable"))
        option.notAvailable = true
    end
end

SensorContextMenu.addDebugOptions = function(context, playerObj)
    local sensorDebug = context:addOption("[Debug] Sensor", worldobjects, nil)
    local subMenu = ISContextMenu.getNew(context)
    context:addSubMenu(sensorDebug, subMenu)

    subMenu:addOption("Load Sensor State", playerObj, SensorManagerClient.loadState)
end

SensorContextMenu.onCheckBattery = function(playerObj, object, sensor)
    if SensorUtil.walkToObject(playerObj, object) then
        ISTimedActionQueue.add(ISCheckSensorBattery:new(playerObj, sensor))
    end
end

SensorContextMenu.onToggleSensor = function(playerObj, object, sensor)
    if SensorUtil.walkToObject(playerObj, object) then
        ISTimedActionQueue.add(ISToggleSensor:new(playerObj, sensor))
    end
end

SensorContextMenu.onReplaceBattery = function(playerObj, object, sensor)
    if SensorUtil.walkToObject(playerObj, object) then
        ISTimedActionQueue.add(ISReplaceSensorBattery:new(playerObj, sensor))
    end
end

SensorContextMenu.onRemoveSensor = function(playerObj, object, sensor)
    if SensorUtil.walkToObject(playerObj, object) then
        ISTimedActionQueue.add(ISRemoveSensor:new(playerObj, sensor))
    end
end

SensorContextMenu.onAttachSensor = function(playerObj, object, sensorItem)
    if SensorUtil.walkToObject(playerObj, object) then
        ISTimedActionQueue.add(ISAttachSensor:new(playerObj, object, sensorItem))
    end
end

Events.OnFillWorldObjectContextMenu.Add(SensorContextMenu.onFillWorldObjectContextMenu)

return SensorContextMenu