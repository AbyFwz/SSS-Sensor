SensorUtil = {}

function SensorUtil:logError(message)
    print("[ERROR] SensorManager: " .. message)
end

function SensorUtil:logInfo(message)
    if isDebugEnabled() then
        print("[INFO] SensorManager: " .. message)
    end
end

function SensorUtil.walkToObject(player, object)
    if luautils.walkAdj(player, object:getSquare()) then
        return true
    end
    return false
end

return SensorUtil