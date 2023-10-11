---@class falg.UShort4
local UShort4 = {}
UShort4.__index = UShort4

local ffi = require "ffi"
ffi.cdef [[
typedef struct {
  uint16_t X, Y, Z, W;

} UShort4;
]]

---@return string
function UShort4:__tostring()
  return string.format("[%d, %d, %d, %d]", self.X, self.Y, self.Z, self.W)
end

---@type falg.UShort4
UShort4 = ffi.metatype("UShort4", UShort4)

return UShort4
