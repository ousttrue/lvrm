local ffi = require "ffi"

ffi.cdef [[
typedef struct {
  Float3 Position;
  Float2 TexCoord;
  Float3 Normal;
} Vertex;
typedef struct {
  Float3 Position;
  Float3 Normal;
} MorphVertex;
]]

---@class VertexBuffer: VertexBufferInstance
local VertexBuffer = {}
VertexBuffer.__index = VertexBuffer

VertexBuffer.TYPE_MAP = {
  Vertex = {
    { "VertexPosition", "float", 3 },
    { "VertexTexCoord", "float", 2 },
    { "VertexNormal", "float", 3 },
  },
  MorphVertex = {
    { "VertexPosition", "float", 3 },
    { "VertexNormal", "float", 3 },
  },
  uint32_t = "uint32",
  uint16_t = "uint16",
}

---@param array ffi.cdata* Vertex[N]
---@param value_type string
---@return VertexBuffer
function VertexBuffer.new(array, value_type)
  ---@class VertexBufferInstance
  local instance = {
    array = array,
    value_type = value_type,
  }
  ---@type VertexBuffer
  return setmetatable(instance, VertexBuffer)
end

---@return VertexBuffer
function VertexBuffer.create(t, count)
  ---@type ffi.cdecl*
  local ct = string.format("%s[%d]", t, count)
  local array = ffi.new(ct)
  return VertexBuffer.new(array, t)
end

---@return integer
function VertexBuffer:count()
  return ffi.sizeof(self.array) / ffi.sizeof(self.value_type)
end

---@param usage "static" | "dynamic" | "stream"
function VertexBuffer:to_lg_mesh(usage)
  ---@type integer
  local size = ffi.sizeof(self.array)
  local data = love.data.newByteData(size)
  ffi.copy(data:getFFIPointer(), self.array, size)
  return love.graphics.newMesh(self.format, data, "triangles", usage and usage or "static")
end

---@param offset integer
---@param span Span
---@param prop string?
function VertexBuffer:assign(offset, span, prop)
  if prop then
    for i = 0, span.len - 1 do
      self.array[offset + i][prop] = span.ptr[i]
    end
  else
    for i = 0, span.len - 1 do
      self.array[offset + i] = span.ptr[i]
    end
  end
end

return VertexBuffer
