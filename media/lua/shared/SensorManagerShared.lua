-- media/lua/shared/SensorManagerShared.lua

SensorManagerShared = {
    cellSize = 300,
    chunkSize = 10,
    worldSize = 66,
    renderDistance = 30,
    bufferCells = 1,
    maxSensorsPerCell = 100,
}

function SensorManagerShared.getCellKey(x, y)
    return math.floor(x / SensorManagerShared.cellSize) .. "," .. math.floor(y / SensorManagerShared.cellSize)
end

function SensorManagerShared.getAdjacentCells(cellX, cellY, bufferSize)
    local adjacent = {}
    for dx = -bufferSize, bufferSize do
        for dy = -bufferSize, bufferSize do
            local adjX, adjY = cellX + dx, cellY + dy
            if adjX >= 0 and adjX < SensorManagerShared.worldSize and adjY >= 0 and adjY < SensorManagerShared.worldSize then
                table.insert(adjacent, adjX .. "," .. adjY)
            end
        end
    end
    return adjacent
end

function SensorManagerShared.isValidPosition(x, y, z)
    return x >= 0 and x < SensorManagerShared.worldSize * SensorManagerShared.cellSize and
           y >= 0 and y < SensorManagerShared.worldSize * SensorManagerShared.cellSize and
           z >= 0 and z <= 7
end

function SensorManagerShared.compressStates(states)
    local compressed = {}
    local lastX, lastY, lastZ = 0, 0, 0

    for _, state in ipairs(states) do
        local deltaX, deltaY, deltaZ = state.x - lastX, state.y - lastY, state.z - lastZ
        local packedState = table.concat({
            SensorManagerShared.packNumber(deltaX),
            SensorManagerShared.packNumber(deltaY),
            SensorManagerShared.packNumber(deltaZ),
            SensorManagerShared.packNumber(state.batteryLevel),
            state.isActive and "1" or "0"
        }, ",")

        table.insert(compressed, packedState)
        lastX, lastY, lastZ = state.x, state.y, state.z
    end

    return table.concat(compressed, ";")
end

function SensorManagerShared.decompressStates(compressedStates)
    local states, lastX, lastY, lastZ = {}, 0, 0, 0

    for packedState in compressedStates:gmatch("[^;]+") do
        local parts = {}
        for part in packedState:gmatch("[^,]+") do
            table.insert(parts, part)
        end

        local deltaX, deltaY, deltaZ = SensorManagerShared.unpackNumber(parts[1]), SensorManagerShared.unpackNumber(parts[2]), SensorManagerShared.unpackNumber(parts[3])
        lastX, lastY, lastZ = lastX + deltaX, lastY + deltaY, lastZ + deltaZ

        table.insert(states, {
            x = lastX,
            y = lastY,
            z = lastZ,
            batteryLevel = SensorManagerShared.unpackNumber(parts[4]),
            isActive = parts[5] == "1"
        })
    end

    return states
end

function SensorManagerShared.packNumber(num)
    if num == 0 then return "0" end
    local sign = num < 0 and "-" or ""
    num = math.abs(num)
    local int, frac = math.modf(num)
    local packed = sign .. string.char(int + 35)
    if frac ~= 0 then
        packed = packed .. string.char(math.floor(frac * 100) + 35)
    end
    return packed
end

function SensorManagerShared.unpackNumber(str)
    if str == "0" then return 0 end
    local sign = str:sub(1, 1) == "-" and -1 or 1
    str = str:gsub("^-", "")
    local int = str:byte(1) - 35
    local frac = #str > 1 and (str:byte(2) - 35) / 100 or 0
    return sign * (int + frac)
end

return SensorManagerShared