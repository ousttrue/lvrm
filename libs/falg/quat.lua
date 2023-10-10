---@class falg.Quat
local Quat = {}
Quat.__index = Quat

local ffi = require "ffi"
ffi.cdef [[
typedef struct {
  float X, Y, Z, W;

} Quat;
]]

---@return falg.Quat
function Quat.new_identity()
  return Quat(0, 0, 0, 1)
end

---@type falg.Quat
Quat = ffi.metatype("Quat", Quat)

return Quat
