---@class falg.Float3
---@field X number
---@field Y number
---@field Z number
local Float3 = {}
Float3.__index = Float3

local ffi = require "ffi"
ffi.cdef [[
typedef struct {
  float X, Y, Z;
} Float3;
]]

---@return string
function Float3:__tostring()
  return string.format("[%0.2f, %0.2f, %0.2f]", self.X, self.Y, self.Z)
end

---@param rhs falg.Float3
---@return boolean
function Float3:__eq(rhs)
  return self.X == rhs.X and self.Y == rhs.Y and self.Z == rhs.Z
end

---@param rhs falg.Float3
---@return falg.Float3
function Float3:__add(rhs)
  return Float3(self.X + rhs.X, self.Y + rhs.Y, self.Z + rhs.Z)
end

---@param factor number
---@return falg.Float3
function Float3:scale(factor)
  return Float3(self.X * factor, self.Y * factor, self.Z * factor)
end

---@type falg.Float3
Float3 = ffi.metatype("Float3", Float3)

return Float3
