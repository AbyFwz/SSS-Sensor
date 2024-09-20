-- media/lua/server/SensorManagerServer.lua

if isClient() then return end

local SensorUtil = require "SensorUtil"
local SensorManagerShared = require "SensorManagerShared"

SensorManagerServer = {
    sensors = {}, -- Sensors indexed by cell coordinates
}

function SensorManagerServer.createSensor(args)
    if not SensorManagerShared.isValidPosition(args.x, args.y, args.z) then
        SensorUtil:logError("Invalid position for sensor creation: " .. args.x .. "," .. args.y .. "," .. args.z)
        return
    end

    local cellKey = SensorManagerShared.getCellKey(args.x, args.y)
    if SensorManagerServer.sensors[cellKey] and #SensorManagerServer.sensors[cellKey] >= SensorManagerShared.maxSensorsPerCell then
        SensorUtil:logError("Maximum number of sensors reached for cell: " .. cellKey)
        return
    end

    local square = getCell():getGridSquare(args.x, args.y, args.z)
    if square then
        local SensorTypeClass = require("SensorType/" .. args.sensorType:gsub("^Sensor_", ""))
        if not SensorTypeClass then
            SensorUtil:logError("Sensor type not found: " .. args.sensorType)
            return
        end

        local sensor = SensorTypeClass:new()
        sensor:init(args.sensorType, args.batteryLevel, args.ownerUsername, square)

        SensorManagerServer.sensors[cellKey] = SensorManagerServer.sensors[cellKey] or {}
        table.insert(SensorManagerServer.sensors[cellKey], sensor)

        SensorUtil:logInfo("Sensor created on server: Type=" .. sensor.sensorType .. ", Position=" .. sensor.x .. "," .. sensor.y .. "," .. sensor.z)

        sendServerCommand("SensorManager", "SensorCreated", args)
    end
end

function SensorManagerServer.removeSensor(args)
    local cellKey = SensorManagerShared.getCellKey(args.x, args.y)
    if SensorManagerServer.sensors[cellKey] then
        for i, sensor in ipairs(SensorManagerServer.sensors[cellKey]) do
            if sensor.x == args.x and sensor.y == args.y and sensor.z == args.z then
                table.remove(SensorManagerServer.sensors[cellKey], i)
                SensorUtil:logInfo("Sensor removed on server: Position=" .. args.x .. "," .. args.y .. "," .. args.z)
                sendServerCommand("SensorManager", "SensorRemoved", args)
                break
            end
        end
    end
end

function SensorManagerServer.updateSensor(args)
    local cellKey = SensorManagerShared.getCellKey(args.x, args.y)
    if SensorManagerServer.sensors[cellKey] then
        for _, sensor in ipairs(SensorManagerServer.sensors[cellKey]) do
            if sensor.x == args.x and sensor.y == args.y and sensor.z == args.z then
                if args.batteryLevel ~= nil then sensor.batteryLevel = args.batteryLevel end
                if args.isActive ~= nil then sensor.isActive = args.isActive end
                SensorUtil:logInfo("Sensor updated on server: Position=" .. args.x .. "," .. args.y .. "," .. args.z)
                sendServerCommand("SensorManager", "SensorUpdated", args)
                break
            end
        end
    end
end

function SensorManagerServer.syncSensorStates(args)
    local decompressedStates = SensorManagerShared.decompressStates(args.states)
    local updatedStates = {}
    for _, state in ipairs(decompressedStates) do
        if SensorManagerShared.isValidPosition(state.x, state.y, state.z) then
            local cellKey = SensorManagerShared.getCellKey(state.x, state.y)
            if SensorManagerServer.sensors[cellKey] then
                for _, sensor in ipairs(SensorManagerServer.sensors[cellKey]) do
                    if sensor.x == state.x and sensor.y == state.y and sensor.z == state.z then
                        sensor.batteryLevel = state.batteryLevel
                        sensor.isActive = state.isActive
                        table.insert(updatedStates, state)
                        break
                    end
                end
            end
        else
            SensorUtil:logError("Invalid position in sync request: " .. state.x .. "," .. state.y .. "," .. state.z)
        end
    end
    if #updatedStates > 0 then
        sendServerCommand("SensorManager", "SensorStatesUpdated", {states = SensorManagerShared.compressStates(updatedStates)})
    end
end

function SensorManagerServer.updateSensors()
    for _, cellSensors in pairs(SensorManagerServer.sensors) do
        for _, sensor in ipairs(cellSensors) do
            if sensor and sensor.update then
                sensor:update(getGameTime():getWorldAgeHours() - sensor.lastUpdateTime)
                sensor.lastUpdateTime = getGameTime():getWorldAgeHours()
                if sensor:checkRequirement() then
                    sensor:triggerAction()
                end
            end
        end
    end
end

function SensorManagerServer.saveState()
    local data = {}
    for cellKey, cellSensors in pairs(SensorManagerServer.sensors) do
        data[cellKey] = {}
        for _, sensor in ipairs(cellSensors) do
            table.insert(data[cellKey], sensor:serialize())
        end
    end
    ModData.add("SensorManagerServerData", data)
    ModData.transmit("SensorManagerServerData")
end

function SensorManagerServer.loadState()
    local data = ModData.getOrCreate("SensorManagerServerData")
    if data then
        for cellKey, cellSensors in pairs(data) do
            SensorManagerServer.sensors[cellKey] = {}
            for _, sensorData in ipairs(cellSensors) do
                local square = getCell():getGridSquare(sensorData.x, sensorData.y, sensorData.z)
                if square then
                    local SensorTypeClass = require("SensorType/" .. sensorData.sensorType:gsub("^Sensor_", ""))
                    if SensorTypeClass then
                        local sensor = SensorTypeClass:new()
                        sensor:deserialize(sensorData)
                        table.insert(SensorManagerServer.sensors[cellKey], sensor)
                    end
                end
            end
        end
    end
end

Events.OnClientCommand.Add(function(module, command, player, args)
    if module == "SensorManager" then
        if command == "CreateSensor" then SensorManagerServer.createSensor(args)
        elseif command == "RemoveSensor" then SensorManagerServer.removeSensor(args)
        elseif command == "UpdateSensor" then SensorManagerServer.updateSensor(args)
        elseif command == "SyncStates" then SensorManagerServer.syncSensorStates(args)
        end
    end
end)

Events.OnInitGlobalModData.Add(SensorManagerServer.loadState)
Events.OnSave.Add(SensorManagerServer.saveState)
Events.EveryTenMinutes.Add(SensorManagerServer.updateSensors)

return SensorManagerServer