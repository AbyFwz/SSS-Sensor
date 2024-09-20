-- media/lua/shared/SensorType/PlayerSensor.lua

local SensorCore = require "SensorCore"

local PlayerSensor = SensorCore:new()

function PlayerSensor:new(o)
    o = o or SensorCore:new(o)
    setmetatable(o, self)
    self.__index = self
    return o
end

function PlayerSensor:init(batteryLevel, ownerUsername, object)
    SensorCore.init(self, "PlayerSensor", batteryLevel, ownerUsername, object)
    self.detectionRange = 8 -- tiles
    self.ignoreOwner = true -- Set to false if you want the sensor to detect its owner as well
end

function PlayerSensor:checkRequirement()
    if not self.isActive or self.batteryLevel <= 0 then return false end

    local cell = getCell()
    for x = self.x - self.detectionRange, self.x + self.detectionRange do
        for y = self.y - self.detectionRange, self.y + self.detectionRange do
            local square = cell:getGridSquare(x, y, self.z)
            if square then
                local movingObjects = square:getMovingObjects()
                for i = 0, movingObjects:size() - 1 do
                    local obj = movingObjects:get(i)
                    if instanceof(obj, "IsoPlayer") then
                        if not self.ignoreOwner or obj:getUsername() ~= self.ownerUsername then
                            return true
                        end
                    end
                end
            end
        end
    end
    return false
end

function PlayerSensor:triggerAction()
    -- Implement the action to be triggered (e.g., log player activity)
    local square = getCell():getGridSquare(self.x, self.y, self.z)
    if square then
        square:playSound("PlayerDetectedSound")
    end
    print("Player sensor detected human presence at " .. self.x .. "," .. self.y .. "," .. self.z)
end

return PlayerSensor