-- media/lua/shared/SensorType/ZombieSensor.lua

local SensorCore = require "SensorCore"

local ZombieSensor = SensorCore:new()

function ZombieSensor:new(o)
    o = o or SensorCore:new(o)
    setmetatable(o, self)
    self.__index = self
    return o
end

function ZombieSensor:init(batteryLevel, ownerUsername, square)
    SensorCore.init(self, "ZombieSensor", batteryLevel, ownerUsername, square)
    self.detectionRange = 5 -- tiles
end

function ZombieSensor:checkRequirement()
    if not self.isActive or self.batteryLevel <= 0 then return false end

    local cell = getCell()
    for x = self.x - self.detectionRange, self.x + self.detectionRange do
        for y = self.y - self.detectionRange, self.y + self.detectionRange do
            local square = cell:getGridSquare(x, y, self.z)
            if square then
                local movingObjects = square:getMovingObjects()
                for i = 0, movingObjects:size() - 1 do
                    local obj = movingObjects:get(i)
                    if instanceof(obj, "IsoZombie") then
                        return true
                    end
                end
            end
        end
    end
    return false
end

function ZombieSensor:triggerAction()
    -- Implement the action to be triggered (e.g., activate a zombie alarm)
    local square = getCell():getGridSquare(self.x, self.y, self.z)
    if square then
        square:playSound("ZombieAlarmSound")
    end
    print("Zombie sensor detected zombie presence at " .. self.x .. "," .. self.y .. "," .. self.z)
end

return ZombieSensor