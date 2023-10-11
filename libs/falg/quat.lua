---@class falg.Quat
---@field X number
---@field Y number
---@field Z number
---@field W number
local Quat = {}
Quat.__index = Quat

local ffi = require "ffi"
ffi.cdef [[
typedef struct {
  float X, Y, Z, W;

} Quat;
]]

---@return string
function Quat:__tostring()
  return string.format(
    "[%0.2f, %0.2f, %0.2f; %0.2f]",
    self.X,
    self.Y,
    self.Z,
    self.W
  )
end

---@return falg.Quat
function Quat.new_identity()
  return Quat(0, 0, 0, 1)
end

---@type falg.Quat
Quat = ffi.metatype("Quat", Quat)

return Quat
