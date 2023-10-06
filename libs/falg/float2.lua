---@class falg.Float2
local Float2 = {}
Float2.__index = Float2

local ffi = require "ffi"
ffi.cdef [[
typedef struct {
  float X, Y;
} Float2;
]]

---@return string
function Float2:__tostring()
  return string.format("[%0.2f, %0.2f]", self.X, self.Y)
end

---@type falg.Float2
Float2 = ffi.metatype("Float2", Float2)

return Float2
