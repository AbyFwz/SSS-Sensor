-- media/lua/shared/SensorType/ProximitySensor.lua

local SensorCore = require "SensorCore"

local ProximitySensor = SensorCore:new()

function ProximitySensor:new(o)
    o = o or SensorCore:new(o)
    setmetatable(o, self)
    self.__index = self
    return o
end

function ProximitySensor:init(batteryLevel, ownerUsername, object)
    SensorCore.init(self, "ProximitySensor", batteryLevel, ownerUsername, object)
    self.detectionRange = 5 -- tiles
end

function ProximitySensor:checkRequirement()
    if not self.isActive or self.batteryLevel <= 0 then return false end

    local cell = getCell()
    for x = self.x - self.detectionRange, self.x + self.detectionRange do
        for y = self.y - self.detectionRange, self.y + self.detectionRange do
            local square = cell:getGridSquare(x, y, self.z)
            if square then
                local movingObjects = square:getMovingObjects()
                for i = 0, movingObjects:size() - 1 do
                    local obj = movingObjects:get(i)
                    if instanceof(obj, "IsoPlayer") or instanceof(obj, "IsoZombie") then
                        return true
                    end
                end
            end
        end
    end
    return false
end

function ProximitySensor:triggerAction()
    -- Implement the action to be triggered (e.g., activate an alarm)
    local square = getCell():getGridSquare(self.x, self.y, self.z)
    if square then
        square:playSound("AlarmSound")
    end
    -- print("Proximity sensor triggered at " .. self.x .. "," .. self.y .. "," .. self.z)
end

return ProximitySensor