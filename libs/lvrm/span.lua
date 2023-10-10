local ffi = require "ffi"

---@class lvrm.Span: lvrm.SpanInstance
local Span = {}
Span.__index = Span

---@param ptr ffi.cdata* T*
---@param len integer T count
---@param stride integer?
---@return lvrm.Span
function Span.new(ptr, len, stride)
  ---@class lvrm.SpanInstance
  local instance = {
    ptr = ptr,
    len = len,
    stride = stride,
  }
  ---@type lvrm.Span
  return setmetatable(instance, Span)
end

---@param offset integer
---@param len integer
---@return lvrm.Span
function Span:subspan(offset, len)
  return Span.new(self.ptr + offset, len, self.stride)
end

---@param t string
---@param count integer
---@retun lvrm.Span
function Span:cast(t, count)
  local ct = t .. "*"
  return Span.new(ffi.cast(ct, self.ptr), count, ffi.sizeof(t))
end

return Span
