local Float3 = require "falg.float3"

---@class falg.AABB: falg.AABBInstance
local AABB = {}
AABB.__index = AABB

---@param min falg.Float3?
---@param max falg.Float3?
---@return falg.AABB
function AABB.new(min, max)
  ---@class falg.AABBInstance
  local instance = {
    min = min and min or Float3(math.huge, math.huge, math.huge),
    max = max and max or Float3(-math.huge, -math.huge, -math.huge),
  }
  ---@type falg.AABB
  return setmetatable(instance, AABB)
end

---@return boolean
function AABB:enabled()
  if tostring(self.min):match "inf" then
    return false
  end
  if tostring(self.max):match "inf" then
    return false
  end
  return true
end

---@param p falg.Float3 point
function AABB:extend(p)
  if p.X < self.min.X then
    self.min.X = p.X
  end
  if p.Y < self.min.Y then
    self.min.Y = p.Y
  end
  if p.Z < self.min.Z then
    self.min.Z = p.Z
  end
  if p.X > self.max.X then
    self.max.X = p.X
  end
  if p.Y > self.max.Y then
    self.max.Y = p.Y
  end
  if p.Z > self.max.Z then
    self.max.Z = p.Z
  end
end

return AABB
