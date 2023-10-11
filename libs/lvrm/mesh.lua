require "lvrm.gltf_reader"
local ffi = require "ffi"
local falg = require "falg"
local VertexBuffer = require "lvrm.vertexbuffer"
local Material = require "lvrm.material"
local Shader = require "lvrm.shader"

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
    weight = ffi.new "float[1]",
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
---@param indexbuffer VertexBuffer? --{count: integer, data: love.ByteData, format: "uint16"|"uint32"}?
---@param submeshes lvrm.Submesh[]
---@param morphtargets MorphTarget[]?
---@return lvrm.Mesh
function Mesh.new(name, vertexbuffer, indexbuffer, submeshes, morphtargets)
  ---@type integer
  local size = ffi.sizeof(vertexbuffer.array)
  local lg_data = love.data.newByteData(size)
  ffi.copy(lg_data:getFFIPointer(), vertexbuffer.array, size)
  local lg_mesh = love.graphics.newMesh(
    VertexBuffer.TYPE_MAP[vertexbuffer.value_type],
    lg_data,
    "triangles",
    "stream"
  )

  if indexbuffer then
    local data = love.data.newByteData(ffi.sizeof(indexbuffer.array))
    ffi.copy(
      data:getFFIPointer(),
      indexbuffer.array,
      ffi.sizeof(indexbuffer.array)
    )
    lg_mesh:setVertexMap(data, VertexBuffer.TYPE_MAP[indexbuffer.value_type])
  end

  ---@class lvrm.MeshInstance
  ---@field aabb falg.AABB?
  local instance = {
    id = ffi.new "int[1]",
    name = name and name or "",
    vertexbuffer = vertexbuffer,
    indexbuffer = indexbuffer,
    lg_data = lg_data,
    lg_mesh = lg_mesh,
    submeshes = submeshes,
    morphtargets = morphtargets,
    index_count = indexbuffer and indexbuffer:count() or nil,
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
  local vertexbuffer = VertexBuffer.new(buffer, "Vertex")

  return Mesh.new("__triangle__", vertexbuffer, nil, {
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
      table.insert(
        submeshes,
        Submesh.new(material, total_index_count + 1, index_count)
      ) -- 1origin
    else
      table.insert(
        submeshes,
        Submesh.new(material, total_vertex_count + 1, vertex_count)
      ) -- 1origin
    end

    total_vertex_count = total_vertex_count + vertex_count
    total_index_count = total_index_count + index_count
  end

  -- make indices
  local indexbuffer
  if total_index_count > 0 then
    local index_type =
      r.root.accessors[gltf_mesh.primitives[1].indices + 1].componentType
    if index_type == 5123 then
      local array = ffi.new(string.format("uint16_t[%d]", total_index_count))
      indexbuffer = VertexBuffer.new(array, "uint16_t")
    elseif index_type == 5125 then
      local array = ffi.new(string.format("uint32_t[%d]", total_index_count))
      indexbuffer = VertexBuffer.new(array, "uint32_t")
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
  local has_skinning = false
  for _, p in ipairs(gltf_mesh.primitives) do
    if p.attributes.JOINTS_0 and p.attributes.WEIGHTS_0 then
      has_skinning = true
      break
    end
  end

  local vertexbuffer = VertexBuffer.create(
    has_skinning and "VertexSkinning" or "Vertex",
    total_vertex_count
  )
  local vertex_offset = 0
  local index_offset = 0

  ---@type MorphTarget[]
  local morphtargets = {}

  for _, p in ipairs(gltf_mesh.primitives) do
    -- fill indices
    if p.indices then
      local indices_data = r:read_accessor_bytes(p.indices)
      indexbuffer:assign_index(vertex_offset, index_offset, indices_data)
      index_offset = index_offset + indices_data.len
    end

    -- fill vertices
    local attributes = p.attributes

    local positions_data = r:read_accessor_bytes(attributes.POSITION)
    vertexbuffer:assign(vertex_offset, positions_data, "Position")

    if attributes.TEXCOORD_0 then
      local uv_data = r:read_accessor_bytes(attributes.TEXCOORD_0)
      vertexbuffer:assign(vertex_offset, uv_data, "TexCoord")
    end

    if attributes.JOINTS_0 and attributes.WEIGHTS_0 then
      local joint_data = r:read_accessor_bytes(attributes.JOINTS_0)
      for i = 0, joint_data.len - 1 do
        local src = joint_data.ptr[i]
        local dst = vertexbuffer.array[vertex_offset + i].Joints
        dst.X = src.X
        dst.Y = src.Y
        dst.Z = src.Z
        dst.W = src.W
      end

      local weight_data = r:read_accessor_bytes(attributes.WEIGHTS_0)
      vertexbuffer:assign(vertex_offset, weight_data, "Weights")
    end

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
        morphtarget.vertexbuffer:assign(
          vertex_offset,
          morph_positions_data,
          "Position"
        )
      end
    end

    vertex_offset = vertex_offset + positions_data.len
  end

  return Mesh.new(
    gltf_mesh.name,
    vertexbuffer,
    indexbuffer,
    submeshes,
    morphtargets
  )
end

---@return falg.AABB
function Mesh:get_bb()
  if not self.aabb then
    self.aabb = falg.AABB.new()
    for i = 0, self.vertexbuffer:count() - 1 do
      self.aabb:extend(self.vertexbuffer.array[i].Position)
    end
  end
  return self.aabb
end

---@param model falg.Mat4
---@param view falg.Mat4
---@param projection falg.Mat4
---@param submesh_num integer? draw only specific submesh
---@param skinning lvrm.Skinning?
function Mesh:draw(model, view, projection, submesh_num, skinning)
  local update_mesh = false

  if self.morphtargets then
    -- clear base mesh
    local size = ffi.sizeof(self.vertexbuffer.array)
    local ptr = ffi.cast(
      self.vertexbuffer.value_type .. "*",
      self.lg_data:getFFIPointer()
    )
    ffi.copy(ptr, self.vertexbuffer.array, size)

    -- add morph target
    for _, t in ipairs(self.morphtargets) do
      local w = t.weight[0]
      if w > 0 then
        for i = 0, t.vertexbuffer:count() do
          ptr[i].Position = ptr[i].Position
            + t.vertexbuffer.array[i].Position:scale(w)
        end
      end
    end

    update_mesh = true
  end

  if skinning and not Material.GPU_SKINNING then
    local ptr = ffi.cast(
      self.vertexbuffer.value_type .. "*",
      self.lg_data:getFFIPointer()
    )
    for i = 0, self.vertexbuffer:count() - 1 do
      local v = self.vertexbuffer.array[i]
      local p = v.Position
      local j = v.Joints
      local w = v.Weights

      local dst = falg.Float3(0, 0, 0)
      dst = dst + skinning:calc(p, j.X, w.X)
      dst = dst + skinning:calc(p, j.Y, w.Y)
      dst = dst + skinning:calc(p, j.Z, w.Z)
      dst = dst + skinning:calc(p, j.W, w.W)
      ptr[i].Position = dst
    end

    update_mesh = true
  end

  if update_mesh then
    self.lg_mesh:setVertices(self.lg_data)
  end

  for i, s in ipairs(self.submeshes) do
    if not submesh_num or i == submesh_num then
      if s.drawcount > 0 then
        s.material:use(skinning)
        if s.material.color_texture then
          self.lg_mesh:setTexture(s.material.color_texture)
        else
          self.lg_mesh:setTexture()
        end

        s.material:send_mat4("m_model", model)
        s.material:send_mat4("m_view", view)
        s.material:send_mat4("m_projection", projection)

        self.lg_mesh:setDrawRange(s.start, s.drawcount)
        love.graphics.draw(self.lg_mesh)
      end
    end
  end
end

return Mesh
