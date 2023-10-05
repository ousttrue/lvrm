require "lvrm.gltf_reader"
local ffi = require "ffi"
require "falg"
local VertexBuffer = require "lvrm.vertexbuffer"
local Material = require "lvrm.material"

---
--- MorphTarget
---
---@class MorphTarget: MorphTargetInstance
local MorphTarget = {}
MorphTarget.__index = MorphTarget

---@param name string
---@param vertex_count integer
---@return MorphTarget
function MorphTarget.new(name, vertex_count)
  ---@class MorphTargetInstance
  local instance = {
    name = name,
    value = ffi.new "float[1]",
    vertexbuffer = VertexBuffer.create("MorphVertex", vertex_count),
  }
  ---@type MorphTarget
  return setmetatable(instance, MorphTarget)
end

---
--- Submesh
---
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

---
--- Mesh
---
---@class lvrm.Mesh: lvrm.MeshInstance
local Mesh = {}
Mesh.__index = Mesh

---@param name string?
---@param vertexbuffer VertexBuffer
---@param submeshes lvrm.Submesh[]
---@param indices {data: love.ByteData, format: "uint16"|"uint32"}?
---@param morphtargets MorphTarget[]?
---@return lvrm.Mesh
function Mesh.new(name, vertexbuffer, submeshes, indices, morphtargets)
  ---@type integer
  local size = ffi.sizeof(vertexbuffer.array)
  local lg_data = love.data.newByteData(size)
  ffi.copy(lg_data:getFFIPointer(), vertexbuffer.array, size)
  local lg_mesh = love.graphics.newMesh(vertexbuffer.format, lg_data, "triangles", "stream")

  -- e  local lg_mesh = vertexbuffer:to_lg_mesh(morphtargets and "stream" or "static")
  if indices then
    lg_mesh:setVertexMap(indices.data, indices.format)
  end

  ---@class lvrm.MeshInstance
  local instance = {
    id = ffi.new "int[1]",
    name = name and name or "",
    vertexbuffer = vertexbuffer,
    lg_data = lg_data,
    lg_mesh = lg_mesh,
    submeshes = submeshes,
    morphtargets = morphtargets,
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
  local vertexbuffer = VertexBuffer.new(buffer, VertexBuffer.VERTEX_FORMAT.Vertex)

  return Mesh.new("__triangle__", vertexbuffer, {
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

  local morphtarget_names
  if gltf_mesh.extras then
    morphtarget_names = gltf_mesh.extras.targetNames
  end
  if not morphtarget_names then
    for _, p in ipairs(gltf_mesh.primitives) do
      if p.extras and p.extras.targetNames then
        morphtarget_names = p.extras.targetNames
        break
      end
    end
  end

  --
  -- create VertexBuffer
  --
  local vertexbuffer = VertexBuffer.create("Vertex", total_vertex_count)
  local vertex_offset = 0
  local index_offset = 0

  ---@type MorphTarget[]
  local morphtargets = {}

  for _, p in ipairs(gltf_mesh.primitives) do
    -- fill indices
    if p.indices then
      local indices_data = r:read_accessor_bytes(p.indices)
      for i = 0, indices_data.len - 1 do
        p_indices[index_offset] = indices_data.ptr[i] + vertex_offset
        index_offset = index_offset + 1
      end
    end

    -- fill vertices
    local attributes = p.attributes

    local positions_data = r:read_accessor_bytes(attributes.POSITION)
    vertexbuffer:assign(vertex_offset, positions_data, "Position")

    if attributes.TEXCOORD_0 then
      local uv_data = r:read_accessor_bytes(attributes.TEXCOORD_0)
      vertexbuffer:assign(vertex_offset, uv_data, "TexCoord")
    end

    -- TODO: skinning

    -- morph target
    if p.targets then
      for j, t in ipairs(p.targets) do
        local morphtarget = morphtargets[j]
        if not morphtarget then
          local name = string.format("%d", j)
          if morphtarget_names then
            name = morphtarget_names[j]
          end
          morphtarget = MorphTarget.new(name, total_vertex_count)
          morphtargets[j] = morphtarget
        end

        local morph_positions_data = r:read_accessor_bytes(t.POSITION)
        morphtarget.vertexbuffer:assign(vertex_offset, morph_positions_data, "Position")
      end
    end

    vertex_offset = vertex_offset + positions_data.len
  end

  return Mesh.new(gltf_mesh.name, vertexbuffer, submeshes, indices, morphtargets)
end

---@param model falg.Mat4
---@param view falg.Mat4
---@param projection falg.Mat4
function Mesh:draw(model, view, projection)
  if self.morphtargets then
    -- clear base mesh
    local size = ffi.sizeof(self.vertexbuffer.array)
    local ptr = ffi.cast("MorphVertex*", self.lg_data:getFFIPointer())
    ffi.copy(ptr, self.vertexbuffer.array, size)

    -- add morph target
    local w = 0
    for _, t in ipairs(self.morphtargets) do
      if t.value[0] > 0 then
        w = w + t.value[0]
        for i = 0, t.vertexbuffer:count() do
          ptr[i].Position.X = ptr[i].Position.X + t.vertexbuffer.array[i].Position.X -- * t.value
          ptr[i].Position.Y = ptr[i].Position.Y + t.vertexbuffer.array[i].Position.Y -- * t.value
          ptr[i].Position.Z = ptr[i].Position.Z + t.vertexbuffer.array[i].Position.Z -- * t.value
        end
      end
    end

    if w > 0 then
      -- update mesh
      self.lg_mesh:setVertices(self.lg_data)
      -- self.lg_mesh:flush()
    end
  end

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
