---@class falg.Float4
---@field X number
---@field Y number
---@field Z number
---@field W number
local Float4 = {}
Float4.__index = Float4

local ffi = require "ffi"
ffi.cdef [[
typedef struct {
  float X, Y, Z, W;

} Float4;
]]

---@return string
function Float4:__tostring()
  return string.format(
    "[%0.2f, %0.2f, %0.2f, %0.2f]",
    self.X,
    self.Y,
    self.Z,
    self.W
  )
end

---@type falg.Float4
Float4 = ffi.metatype("Float4", Float4)

return Float4
