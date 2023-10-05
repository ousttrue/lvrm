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

VertexBuffer.VERTEX_FORMAT = {
  Vertex = {
    { "VertexPosition", "float", 3 },
    { "VertexTexCoord", "float", 2 },
    { "VertexNormal", "float", 3 },
  },
  MorphVertex = {
    { "VertexPosition", "float", 3 },
    { "VertexNormal", "float", 3 },
  },
}

---@param array ffi.cdata* Vertex[N]
---@param format table
---@return VertexBuffer
function VertexBuffer.new(array, format)
  assert(format)
  ---@class VertexBufferInstance
  local instance = {
    array = array,
    format = format,
  }
  ---@type VertexBuffer
  return setmetatable(instance, VertexBuffer)
end

---@return VertexBuffer
function VertexBuffer.create(t, count)
  ---@type ffi.cdecl*
  local ct = string.format("Vertex[%d]", count)
  local array = ffi.new(ct)
  local f = VertexBuffer.VERTEX_FORMAT[t]
  assert(f)
  return VertexBuffer.new(array, f)
end

---@return integer
function VertexBuffer:count()
  return ffi.sizeof(self.array) / self:item_size()
end

---@return integer
function VertexBuffer:item_size()
  return ffi.sizeof(self.array[0])
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
---@param prop string
function VertexBuffer:assign(offset, span, prop)
  for i = 0, span.len - 1 do
    self.array[offset + i][prop] = span.ptr[i]
  end
end

return VertexBuffer
