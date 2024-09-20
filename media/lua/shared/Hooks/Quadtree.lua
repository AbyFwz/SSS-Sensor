-- Quadtree implementation
local Quadtree = {}
Quadtree.__index = Quadtree

function Quadtree.new(boundary, capacity)
    local self = setmetatable({}, Quadtree)
    self.boundary = boundary
    self.capacity = capacity
    self.sensors = {}
    self.divided = false
    return self
end

function Quadtree:insert(sensor)
    if not self.boundary:contains(sensor.x, sensor.y) then
        return false
    end

    if #self.sensors < self.capacity and not self.divided then
        table.insert(self.sensors, sensor)
        return true
    end

    if not self.divided then
        self:subdivide()
    end

    return self.northwest:insert(sensor) or
           self.northeast:insert(sensor) or
           self.southwest:insert(sensor) or
           self.southeast:insert(sensor)
end

function Quadtree:subdivide()
    local x = self.boundary.x
    local y = self.boundary.y
    local w = self.boundary.width / 2
    local h = self.boundary.height / 2

    self.northwest = Quadtree.new({x = x, y = y, width = w, height = h}, self.capacity)
    self.northeast = Quadtree.new({x = x + w, y = y, width = w, height = h}, self.capacity)
    self.southwest = Quadtree.new({x = x, y = y + h, width = w, height = h}, self.capacity)
    self.southeast = Quadtree.new({x = x + w, y = y + h, width = w, height = h}, self.capacity)

    self.divided = true
end

function Quadtree:query(range, found)
    found = found or {}
    if not self.boundary:intersects(range) then
        return found
    end

    for _, sensor in ipairs(self.sensors) do
        if range:contains(sensor.x, sensor.y) then
            table.insert(found, sensor)
        end
    end

    if self.divided then
        self.northwest:query(range, found)
        self.northeast:query(range, found)
        self.southwest:query(range, found)
        self.southeast:query(range, found)
    end

    return found
end

return Quadtree