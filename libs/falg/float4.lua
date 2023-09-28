---@class falg.Float4
local Float4 = {}
Float4.__index = Float4

local ffi = require "ffi"
ffi.cdef [[
typedef struct {
  float X, Y, Z, W;

} Float4;
]]

---@type falg.Float4
return ffi.metatype("Float4", Float4)
