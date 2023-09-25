---@class falg.Float3
local Float3 = {}
Float3.__index = Float3

local ffi = require "ffi"
ffi.cdef [[
typedef struct {
  float X, Y, Z;

} Float3;
]]

---@type falg.Float3
return ffi.metatype("Float3", Float3)
