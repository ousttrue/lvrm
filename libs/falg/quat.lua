---@class falg.Quat
local Quat = {}
Quat.__index = Quat

local ffi = require "ffi"
ffi.cdef [[
typedef struct {
  float X, Y, Z, W;

} Quat;
]]

---@type falg.Quat
return ffi.metatype("Quat", Quat)