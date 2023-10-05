require "lvrm.gltf_reader"
local ffi = require "ffi"
require "falg"

local Material = require "lvrm.material"

---@class lvrm.Submesh: lvrm.SubmeshInsance
local Submesh = {}

---@param material lvrm.Material
---@param start integer
---@param drawcount integer
function Submesh.new(material, start, drawcount)
  ---@class lvrm.SubmeshInsance
  local instance = {
    material = material,
    start = start,
    drawcount = drawcount,
  }
  ---@type lvrm.Submesh
  return setmetatable(instance, Submesh)
end

ffi.cdef [[
typedef struct {
  Float3 Position;
  Float2 TexCoord;
  Float3 Normal;
} Vertex;
]]

local VERTEX_FORMAT = {
  Vertex = {
    { "VertexPosition", "float", 3 },
    { "VertexTexCoord", "float", 2 },
    { "VertexNormal", "float", 3 },
  },
}

---@class VertexBuffer: VertexBufferInstance
local VertexBuffer = {}
VertexBuffer.__index = VertexBuffer

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
  return VertexBuffer.new(array, VERTEX_FORMAT[t])
end

function VertexBuffer:to_lg_mesh()
  ---@type integer
  local size = ffi.sizeof(self.array)
  local data = love.data.newByteData(size)
  ffi.copy(data:getFFIPointer(), self.array, size)
  return love.graphics.newMesh(self.format, data, "triangles", "static")
end

---@class lvrm.Mesh: lvrm.MeshInstance
local Mesh = {}
Mesh.__index = Mesh

---@param name string?
---@param vertexbuffer VertexBuffer
---@param submeshes lvrm.Submesh[]
---@param indices {data: love.ByteData, format: "uint16"|"uint32"}?
---@return lvrm.Mesh
function Mesh.new(name, vertexbuffer, submeshes, indices)
  local lg_mesh = vertexbuffer:to_lg_mesh()
  if indices then
    lg_mesh:setVertexMap(indices.data, indices.format)
  end

  ---@class lvrm.MeshInstance
  local instance = {
    id = ffi.new "int[1]",
    name = name and name or "",
    lg_mesh = lg_mesh,
    submeshes = submeshes,
  }

  ---@type lvrm.Mesh
  return setmetatable(instance, Mesh)
end

---@return lvrm.Mesh
function Mesh.new_triangle()
  -- local buffer = ffi.new "Vertex[3]"
  local buffer = ffi.new "Vertex[3]"
  buffer[0].Position.X = -1
  buffer[0].Position.Y = -1
  buffer[1].Position.X = 1
  buffer[1].Position.Y = -1
  buffer[2].Position.X = 0
  buffer[2].Position.Y = 1
  local vertex_buffer = VertexBuffer.new(buffer, VERTEX_FORMAT.Vertex)

  return Mesh.new("__triangle__", vertex_buffer, {
    Submesh.new(Material.new("default", "default"), 1, 3), -- 1origin
  })
end

---@param r GltfReader
---@param gltf_mesh gltf.Mesh
---@param materials lvrm.Material[]
---@return lvrm.Mesh
function Mesh.load(r, gltf_mesh, materials)
  local total_vertex_count = 0
  local total_index_count = 0
  local submeshes = {}
  for _, p in ipairs(gltf_mesh.primitives) do
    local vertex_count = r.root.accessors[p.attributes.POSITION + 1].count -- 1origin
    local index_count = 0

    local material
    if p.material then
      material = materials[p.material + 1] -- 1origin
      assert(material)
    else
      -- defualt grayscale
      material = Material.new("default", "default")
    end

    if p.indices then
      index_count = r.root.accessors[p.indices + 1].count -- 1origin
      table.insert(submeshes, Submesh.new(material, total_index_count + 1, index_count)) -- 1origin
    else
      table.insert(submeshes, Submesh.new(material, total_vertex_count + 1, vertex_count)) -- 1origin
    end

    total_vertex_count = total_vertex_count + vertex_count
    total_index_count = total_index_count + index_count
  end

  -- make indices
  local indices
  local p_indices
  if total_index_count > 0 then
    indices = {}
    local index_type = r.root.accessors[gltf_mesh.primitives[1].indices + 1].componentType
    if index_type == 5123 then
      indices.format = "uint16"
      indices.data = love.data.newByteData(2 * total_index_count)
      p_indices = ffi.cast("unsigned short*", indices.data:getFFIPointer())
    elseif index_type == 5125 then
      indices.format = "uint32"
      indices.data = love.data.newByteData(4 * total_index_count)
      p_indices = ffi.cast("unsigned int*", indices.data:getFFIPointer())
    else
      assert(false, "unknown index type", index_type)
    end
  end

  local vertex_buffer = VertexBuffer.create("Vertex", total_vertex_count)

  -- fill data0
  local vertex_offset = 0
  local index_offset = 0
  for _, p in ipairs(gltf_mesh.primitives) do
    if p.indices then
      local indices_data = r:read_accessor_bytes(p.indices)
      for i = 0, indices_data.len - 1 do
        p_indices[index_offset] = indices_data.ptr[i] + vertex_offset
        index_offset = index_offset + 1
      end
    end

    local attributes = p.attributes
    local positions_data = r:read_accessor_bytes(attributes.POSITION)
    for i = 0, positions_data.len - 1 do
      vertex_buffer.array[vertex_offset + i].Position = positions_data.ptr[i]
    end

    if attributes.TEXCOORD_0 then
      local uv_data = r:read_accessor_bytes(attributes.TEXCOORD_0)
      for i = 0, uv_data.len - 1 do
        vertex_buffer.array[vertex_offset + i].TexCoord = uv_data.ptr[i]
      end
    end

    vertex_offset = vertex_offset + positions_data.len
  end

  return Mesh.new(gltf_mesh.name, vertex_buffer, submeshes, indices)
end

---@param model falg.Mat4
---@param view falg.Mat4
---@param projection falg.Mat4
function Mesh:draw(model, view, projection)
  for _, s in ipairs(self.submeshes) do
    s.material:use()
    if s.material.color_texture then
      self.lg_mesh:setTexture(s.material.color_texture)
    else
      self.lg_mesh:setTexture()
    end

    s.material:send_mat4("m_model", model)
    s.material:send_mat4("m_view", view)
    s.material:send_mat4("m_projection", projection)
    assert(s.drawcount > 0, "empty submesh")
    self.lg_mesh:setDrawRange(s.start, s.drawcount)
    love.graphics.draw(self.lg_mesh)
  end
end

return Mesh
