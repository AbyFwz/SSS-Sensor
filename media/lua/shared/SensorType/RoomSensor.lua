-- media/lua/shared/SensorType/RoomOccupancySensor.lua

local SensorCore = require "SensorCore"

local RoomOccupancySensor = SensorCore:new()

function RoomOccupancySensor:new(o)
    o = o or SensorCore:new(o)
    setmetatable(o, self)
    self.__index = self
    return o
end

function RoomOccupancySensor:init(batteryLevel, ownerUsername, object)
    SensorCore.init(self, "RoomOccupancySensor", batteryLevel, ownerUsername, object)
end

function RoomOccupancySensor:checkRequirement()
    if not self.isActive or not self.attachedObject then return false end

    local square = self.attachedObject:getSquare()
    if not square then return false end

    local room = square:getRoom()
    if not room then return false end

    local players = getOnlinePlayers()
    for i = 0, players:size() - 1 do
        local player = players:get(i)
        if player:getSquare():getRoom() == room then
            return true
        end
    end

    return false
end

function RoomOccupancySensor:triggerAction()
    print("Room is occupied!")
    -- You can add more complex actions here, like turning on lights or security systems
end

return RoomOccupancySensor