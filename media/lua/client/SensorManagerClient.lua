-- media/lua/client/SensorManagerClient.lua

local SensorUtil = require "SensorUtil"
local SensorManagerShared = require "SensorManagerShared"

SensorManagerClient = {
    sensors = {
        active = {},
        adjacent = {},
    },
    activeCells = {},
    adjacentCells = {},
    updateInterval = 1,
    syncInterval = 60,
    lastUpdateTick = 0,
    lastSyncTick = 0,
}

function SensorManagerClient.createSensor(sensorType, batteryLevel, ownerUsername, object)
    local square = object:getSquare()
    if not square or not instanceof(square, "IsoGridSquare") then
        SensorUtil:logError("Invalid IsoGridSquare provided for sensor creation")
        return nil
    end

    local x, y, z = square:getX(), square:getY(), square:getZ()
    if not SensorManagerShared.isValidPosition(x, y, z) then
        SensorUtil:logError("Invalid position for sensor creation: " .. x .. "," .. y .. "," .. z)
        return nil
    end

    local cellKey = SensorManagerShared.getCellKey(x, y)
    local SensorTypeClass = require("SensorType/" .. sensorType:gsub("^Sensor_", ""))
    if not SensorTypeClass then
        SensorUtil:logError("Sensor type not found: " .. sensorType)
        return nil
    end

    local sensor = SensorTypeClass:new()
    sensor:init(batteryLevel, ownerUsername, object)

    SensorManagerClient.sensors.active[sensor.id] = sensor

    if isClient() then
        sendClientCommand("SensorManager", "CreateSensor", sensor:serialize())
    end

    return sensor
end

function SensorManagerClient.removeSensor(sensor)
    if SensorManagerClient.sensors.active[sensor.id] then
        SensorManagerClient.sensors.active[sensor.id] = nil
        SensorUtil:logInfo("Sensor removed: Type=" .. sensor.sensorType .. ", Position=" .. sensor.x .. "," .. sensor.y .. "," .. sensor.z)

        if isClient() then
            sendClientCommand("SensorManager", "RemoveSensor", {x = sensor.x, y = sensor.y, z = sensor.z})
        end

        return true
    end
    return false
end

function SensorManagerClient.getSensorAtSquare(square)
    local cellKey = SensorManagerShared.getCellKey(square:getX(), square:getY())
    for _, sensor in pairs(SensorManagerClient.sensors.active) do
        if sensor.square == square then
            return sensor
        end
    end
    return nil
end

function SensorManagerClient.updateActiveCells()
    local player = getPlayer()
    if not player or player:isDead() then return end

    local px, py = player:getX(), player:getY()
    local cellX, cellY = math.floor(px / SensorManagerShared.cellSize), math.floor(py / SensorManagerShared.cellSize)

    local newActiveCells = {}
    local newAdjacentCells = {}

    for _, cellKey in ipairs(SensorManagerShared.getAdjacentCells(cellX, cellY, SensorManagerShared.bufferCells)) do
        if cellKey == cellX .. "," .. cellY then
            newActiveCells[cellKey] = true
        else
            newAdjacentCells[cellKey] = true
        end
    end

    SensorManagerClient.activeCells = newActiveCells
    SensorManagerClient.adjacentCells = newAdjacentCells
end

function SensorManagerClient.updateSensors()
    local currentTick = getGameTime():getWorldAgeHours() * 3600 * 1000
    if currentTick - SensorManagerClient.lastUpdateTick < SensorManagerClient.updateInterval then
        return
    end
    SensorManagerClient.lastUpdateTick = currentTick

    SensorManagerClient.updateActiveCells()

    for _, sensor in pairs(SensorManagerClient.sensors.active) do
        if sensor and sensor.update then
            sensor:update(getGameTime():getWorldAgeHours() - sensor.lastUpdateTime)
            sensor.lastUpdateTime = getGameTime():getWorldAgeHours()
            if sensor:checkRequirement() then
                sensor:triggerAction()
            end
        end
    end

    if currentTick - SensorManagerClient.lastSyncTick >= SensorManagerClient.syncInterval then
        SensorManagerClient.syncSensorStates()
        SensorManagerClient.lastSyncTick = currentTick
    end
end

function SensorManagerClient.syncSensorStates()
    if not isClient() then return end

    local statesToSync = {}
    for _, sensor in pairs(SensorManagerClient.sensors.active) do
        table.insert(statesToSync, {
            x = sensor.x,
            y = sensor.y,
            z = sensor.z,
            batteryLevel = sensor.batteryLevel,
            isActive = sensor.isActive
        })
    end
    local compressedStates = SensorManagerShared.compressStates(statesToSync)
    sendClientCommand("SensorManager", "SyncStates", {states = compressedStates})
end

function SensorManagerClient.toggleSensor(sensor)
    sensor:toggle()
    if isClient() then
        sendClientCommand("SensorManager", "ToggleSensor", {
            x = sensor.x,
            y = sensor.y,
            z = sensor.z
        })
    end
end

function SensorManagerClient.updateSensorBattery(x, y, z, batteryLevel)
    for _, sensor in pairs(SensorManagerClient.sensors.active) do
        if sensor.x == x and sensor.y == y and sensor.z == z then
            sensor.batteryLevel = batteryLevel
            break
        end
    end
end

function SensorManagerClient.saveState()
    if not isClient() then
        local data = {}
        for _, sensor in pairs(SensorManagerClient.sensors.active) do
            local cellKey = SensorManagerShared.getCellKey(sensor.x, sensor.y)
            data[cellKey] = data[cellKey] or {}
            table.insert(data[cellKey], sensor:serialize())
        end
        ModData.add("SensorManagerData", data)
    end
end

function SensorManagerClient.loadState()
    if not isClient() then
        local data = ModData.get("SensorManagerData") or {}
        SensorManagerClient.sensors.active = {}
        for cellKey, cellSensors in pairs(data) do
            for _, sensorData in ipairs(cellSensors) do
                local square = getCell():getGridSquare(sensorData.x, sensorData.y, sensorData.z)
                if square then
                    local objects = square:getObjects()
                    for i = 0, objects:size() - 1 do
                        local object = objects:get(i)
                        if object:getSprite():getName() == sensorData.objectName then
                            local SensorTypeClass = require("SensorType/" .. sensorData.sensorType:gsub("^Sensor_", ""))
                            if SensorTypeClass then
                                local sensor = SensorTypeClass:new()
                                sensor:init(sensor.batteryLevel, sensor.ownerUsername, object)
                                SensorManagerClient.sensors.active[sensor.id] = sensor
                            end
                            break
                        end
                    end
                end
            end
        end
    end
end

function SensorManagerClient.clearModData()
    SensorManagerClient.sensors.active = {}
    ModData.add("SensorManagerData", {})
end

-- Event handlers
Events.OnGameStart.Add(function()
    SensorManagerClient.loadState()
    SensorManagerClient.lastUpdateTick = getGameTime():getWorldAgeHours() * 3600 * 1000
    SensorManagerClient.lastSyncTick = SensorManagerClient.lastUpdateTick
end)

Events.OnInitGlobalModData.Add(function(isNewGame)
    if not isNewGame then
        -- SensorManagerClient.loadState()
    else
        ModData.create("SensorManagerData")
    end
end)

Events.OnSave.Add(SensorManagerClient.saveState)
Events.OnTick.Add(SensorManagerClient.updateSensors)

-- Server command handler
Events.OnServerCommand.Add(function(module, command, args)
    if module == "SensorManager" then
        if command == "SensorCreated" then
            local square = getCell():getGridSquare(args.x, args.y, args.z)
            if square then
                SensorManagerClient.createSensor(args.sensorType, args.batteryLevel, args.ownerUsername, square)
            end
        elseif command == "SensorRemoved" then
            for id, sensor in pairs(SensorManagerClient.sensors.active) do
                if sensor.x == args.x and sensor.y == args.y and sensor.z == args.z then
                    SensorManagerClient.sensors.active[id] = nil
                    break
                end
            end
        elseif command == "SensorStatesUpdated" then
            local decompressedStates = SensorManagerShared.decompressStates(args.states)
            for _, state in ipairs(decompressedStates) do
                SensorManagerClient.updateSensorBattery(state.x, state.y, state.z, state.batteryLevel)
            end
        elseif command == "UpdateSensorBattery" then
            SensorManagerClient.updateSensorBattery(args.x, args.y, args.z, args.batteryLevel)
        elseif command == "ToggleSensor" then
            for _, sensor in pairs(SensorManagerClient.sensors.active) do
                if sensor.x == args.x and sensor.y == args.y and sensor.z == args.z then
                    sensor:toggle()
                    break
                end
            end
        end
    end
end)

return SensorManagerClient