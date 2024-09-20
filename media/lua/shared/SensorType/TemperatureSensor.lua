-- media/lua/shared/SensorType/TemperatureSensor.lua

local SensorCore = require "SensorCore"

local TemperatureSensor = SensorCore:new()

function TemperatureSensor:new(o)
    o = o or SensorCore:new(o)
    setmetatable(o, self)
    self.__index = self
    return o
end

function TemperatureSensor:init(batteryLevel, ownerUsername, object)
    SensorCore.init(self, "TemperatureSensor", batteryLevel, ownerUsername, object)
    self.temperatureThreshold = 25 -- Celsius
end

function TemperatureSensor:checkRequirement()
    if not self.isActive or not self.attachedObject then return false end

    local square = self.attachedObject:getSquare()
    if not square then return false end

    local temperature = square:getTemperature()
    return temperature > self.temperatureThreshold
end

function TemperatureSensor:triggerAction()
    print("Temperature exceeded " .. self.temperatureThreshold .. "°C!")
    -- You can add more complex actions here, like activating cooling systems
end

return TemperatureSensor