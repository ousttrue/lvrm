---@class falg.UByte4
---@field X integer
---@field Y integer
---@field Z integer
---@field W integer
local UByte4 = {}
UByte4.__index = UByte4

local ffi = require "ffi"
ffi.cdef [[
typedef struct {
  uint8_t X, Y, Z, W;

} UByte4;
]]

---@return string
function UByte4:__tostring()
  return string.format("[%d, %d, %d, %d]", self.X, self.Y, self.Z, self.W)
end

---@type falg.UByte4
UByte4 = ffi.metatype("UByte4", UByte4)

return UByte4
