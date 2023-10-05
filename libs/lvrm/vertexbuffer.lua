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
  MorphVertexn = {
    { "VertexPosition", "float", 3 },
    { "VertexNormal", "float", 3 },
  },
}

---@param array ffi.cdata* Vertex[N]
---@param format table
---@return VertexBuffer
function VertexBuffer.new(array, format)
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
  return VertexBuffer.new(array, VertexBuffer.VERTEX_FORMAT[t])
end

function VertexBuffer:to_lg_mesh()
  ---@type integer
  local size = ffi.sizeof(self.array)
  local data = love.data.newByteData(size)
  ffi.copy(data:getFFIPointer(), self.array, size)
  return love.graphics.newMesh(self.format, data, "triangles", "static")
end

return VertexBuffer
