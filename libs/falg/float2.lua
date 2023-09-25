---@class falg.Float2
local Float2 = {}
Float2.__index = Float2

local ffi = require "ffi"
ffi.cdef [[
typedef struct {
  float X, Y;
} Float2;
]]

---@type falg.Float2
return ffi.metatype("Float2", Float2)
