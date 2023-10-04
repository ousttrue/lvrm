require "lvrm.gltf_reader"
local ffi = require "ffi"
require "falg"

local Material = require "lvrm.material"

---@class lvrm.SubMesh
---@field start integer
---@field drawcount integer
---@field material lvrm.Material

local Submesh = {}

---@param material lvrm.Material
---@param start integer
---@param drawcount integer
function Submesh.new(material, start, drawcount)
  return {
    material = material,
    start = start,
    drawcount = drawcount,
  }
end

ffi.cdef [[
typedef struct {
  Float3 Position;
  Float2 TexCoord;
  Float3 Normal;
} Vertex;
]]

local VERTEX_FORMAT = {
  { "VertexPosition", "float", 3 },
  { "VertexTexCoord", "float", 2 },
  { "VertexNormal", "float", 3 },
}
local VERTEX_SIZE = ffi.sizeof "Vertex"

---@class lvrm.Mesh: lvrm.MeshInstance
local Mesh = {}
Mesh.__index = Mesh

---@param data love.ByteData
---@param submeshes lvrm.SubMesh[]
---@param indices {data: love.ByteData, format: "uint16"|"uint32"}?
---@return lvrm.Mesh
function Mesh.new(vertexformat, data, submeshes, indices)
  local lg_mesh = love.graphics.newMesh(vertexformat, data, "triangles", "static")
  if indices then
    lg_mesh:setVertexMap(indices.data, indices.format)
  end

  ---@class lvrm.MeshInstance
  local instance = {
    id = ffi.new "int[1]",
    ---@type love.Mesh
    vertex_buffer = lg_mesh,
    ---@type lvrm.SubMesh[]
    submeshes = submeshes,
  }

  ---@type lvrm.Mesh
  return setmetatable(instance, Mesh)
end

---@return lvrm.Mesh
function Mesh.new_triangle()
  local data = love.data.newByteData(VERTEX_SIZE * 3)

  -- local buffer = ffi.new "Vertex[3]"
  local buffer = ffi.cast("Vertex*", data:getPointer())
  buffer[0].Position.X = -1
  buffer[0].Position.Y = -1
  buffer[1].Position.X = 1
  buffer[1].Position.Y = -1
  buffer[2].Position.X = 0
  buffer[2].Position.Y = 1

  return Mesh.new(VERTEX_FORMAT, data, {
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

  local data = love.data.newByteData(VERTEX_SIZE * total_vertex_count)
  local p_vertices = ffi.cast("Vertex*", data:getFFIPointer())
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
      p_vertices[vertex_offset + i].Position = positions_data.ptr[i]
    end

    if attributes.TEXCOORD_0 then
      local uv_data = r:read_accessor_bytes(attributes.TEXCOORD_0)
      for i = 0, uv_data.len - 1 do
        p_vertices[vertex_offset + i].TexCoord = uv_data.ptr[i]
      end
    end

    vertex_offset = vertex_offset + positions_data.len
  end

  return Mesh.new(VERTEX_FORMAT, data, submeshes, indices)
end

---@param model falg.Mat4
---@param view falg.Mat4
---@param projection falg.Mat4
function Mesh:draw(model, view, projection)
  for _, s in ipairs(self.submeshes) do
    s.material:use()
    if s.material.color_texture then
      self.vertex_buffer:setTexture(s.material.color_texture)
    else
      self.vertex_buffer:setTexture()
    end

    s.material:send_mat4("m_model", model)
    s.material:send_mat4("m_view", view)
    s.material:send_mat4("m_projection", projection)
    assert(s.drawcount > 0, "empty submesh")
    self.vertex_buffer:setDrawRange(s.start, s.drawcount)
    love.graphics.draw(self.vertex_buffer)
  end
end

return Mesh
