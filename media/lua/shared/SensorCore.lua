-- media/lua/shared/SensorType/SensorCore.lua

SensorCore = {}
SensorCore.__index = SensorCore

function SensorCore:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    o.id = o.id or SensorCore.generateUniqueId()
    return o
end

function SensorCore.generateUniqueId()
    return tostring(os.time()) .. "_" .. tostring(ZombRand(100000, 999999))
end

function SensorCore:init(sensorType, batteryLevel, ownerUsername, object)
    self.sensorType = sensorType
    self.batteryLevel = batteryLevel or 100
    self.ownerUsername = ownerUsername or "Unknown"
    self.isActive = true
    self.objectName = object:getSprite():getName()
    self.square = object:getSquare()
    self.x, self.y, self.z = object:getX(), object:getY(), object:getZ()
    self.lastUpdateTime = getGameTime():getWorldAgeHours()
end

function SensorCore:update(elapsedTime)
    if self.isActive then
        self.batteryLevel = math.max(0, self.batteryLevel - (elapsedTime * 0.1)) -- Drain 0.1% per hour
    end

    if self.batteryLevel <= 0 then
        self.isActive = false
    end
end

function SensorCore:toggle()
    self.isActive = not self.isActive
end

function SensorCore:checkRequirement()
    -- This method should be overridden by specific sensor types
    return false
end

function SensorCore:triggerAction()
    -- This method should be overridden by specific sensor types
end

function SensorCore:serialize()
    return {
        id = self.id,
        sensorType = self.sensorType,
        batteryLevel = self.batteryLevel,
        ownerUsername = self.ownerUsername,
        isActive = self.isActive,
        objectName = self.objectName,
        x = self.x,
        y = self.y,
        z = self.z,
        lastUpdateTime = self.lastUpdateTime
    }
end

function SensorCore:deserialize(data)
    for k, v in pairs(data) do
        self[k] = v
    end
end

return SensorCore