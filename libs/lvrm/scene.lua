local ffi = require "ffi"
local Material = require "lvrm.material"
local Mesh = require "lvrm.mesh"
local Node = require "lvrm.node"
local Animation = require "lvrm.animation"
local Skinning = require "lvrm.skinning"
local falg = require "falg"

---@class lvrm.Scene: lvrm.SceneInstance
local Scene = {}
Scene.__index = Scene

---@return lvrm.Scene
function Scene.new()
  ---@class lvrm.SceneInstance
  local instance = {
    ---@type love.Texture[]
    textures = {},
    ---@type lvrm.Material[]
    materials = {},
    ---@type lvrm.Mesh[]
    meshes = {},
    ---@type lvrm.Node[]
    nodes = {},
    ---@type lvrm.Node[]
    root_nodes = {},
    ---@type lvrm.Skinning[]
    skins = {},
    ---@type lvrm.Animation[]
    animations = {},
  }
  ---@type lvrm.Scene
  return setmetatable(instance, Scene)
end

local WRAP_MAP = {
  [33071] = "clamp",
  [33648] = "mirroredrepeat",
  [10497] = "repeat",
}
-- clamp"|"clampzero"|"mirroredrepeat"|"repeat

---@param bytes string | Span
---@param sampler gltf.Sampler?
---@return love.Texture
local function load_texture(bytes, sampler)
  local data
  if type(bytes) == "string" then
    data = love.data.newByteData(bytes)
  else
    data = love.data.newByteData(bytes.len)
    ffi.copy(data:getFFIPointer(), bytes.ptr, bytes.len)
  end
  local image = love.image.newImageData(data)
  local texture = love.graphics.newImage(image)
  image:release()

  if sampler and sampler.wrapS and sampler.wrapT then
    texture:setWrap(WRAP_MAP[sampler.wrapS], WRAP_MAP[sampler.wrapT])
  end

  return texture
end

---@param reader GltfReader
---@return lvrm.Scene
function Scene.load(reader)
  local scene = Scene.new()

  -- volatile
  -- keep ffi array
  scene.reader = reader

  -- textures
  if reader.root.textures then
    for _, gltf_texture in ipairs(reader.root.textures) do
      local image_bytes = reader:read_image_bytes(gltf_texture.source)
      local gltf_samler
      if gltf_texture.sampler then
        gltf_samler = reader.root.samplers[gltf_texture.sampler + 1] --0to1origin
      end
      local texture = load_texture(image_bytes, gltf_samler)
      table.insert(scene.textures, texture)
    end
  end

  -- materials
  if reader.root.materials then
    for _, gltf_material in ipairs(reader.root.materials) do
      local material = Material.load(gltf_material, scene.textures)
      table.insert(scene.materials, material)
    end
  end

  -- meshes
  if reader.root.meshes then
    for _, gltf_mesh in ipairs(reader.root.meshes) do
      local mesh = Mesh.load(reader, gltf_mesh, scene.materials)
      table.insert(scene.meshes, mesh)
    end
  end

  -- skin
  if reader.root.skins then
    for i, gltf_skin in ipairs(reader.root.skins) do
      local inversed_bind_data =
        reader:read_accessor_bytes(gltf_skin.inverseBindMatrices)
      local skin = Skinning.load(gltf_skin, inversed_bind_data)
      table.insert(scene.skins, skin)
    end
  end

  -- nodes
  if reader.root.nodes then
    for i, gltf_node in ipairs(reader.root.nodes) do
      local node = Node.load(gltf_node, string.format("__node__:02d", i))

      -- mesh
      if gltf_node.mesh then
        node.mesh = scene.meshes[gltf_node.mesh + 1] --0to1origin
      end

      -- skin
      if gltf_node.skin then
        node.skinning = scene.skins[gltf_node.skin + 1] -- 0to1 origin
      end

      table.insert(scene.nodes, node)
    end

    -- chilldren / parent
    for i, gltf_node in ipairs(reader.root.nodes) do
      local node = scene.nodes[i]
      if gltf_node.children then
        for _, c in ipairs(gltf_node.children) do
          local child = scene.nodes[c + 1] --0to1origin
          node:add_child(child)
        end
      end
    end

    -- no prent to root
    for _, node in ipairs(scene.nodes) do
      if not node.parent then
        table.insert(scene.root_nodes, node)
      end
    end
  end

  -- animation
  if reader.root.animations then
    for i, gltf_animation in ipairs(reader.root.animations) do
      local animation = Animation.load(gltf_animation)
      for j, gltf_channel in ipairs(gltf_animation.channels) do
        local gltf_sampler = gltf_animation.samplers[gltf_channel.sampler + 1] --0to1origin
        local time = reader:read_accessor_bytes(gltf_sampler.input)
        local values = reader:read_accessor_bytes(gltf_sampler.output)

        animation:AddCurve(gltf_channel.target, time, values)
      end
      table.insert(scene.animations, animation)
    end
  end

  return scene
end

---@param view falg.Mat4
---@param projection falg.Mat4
function Scene:draw(view, projection)
  -- update world matrix
  for _, n in ipairs(self.root_nodes) do
    n:calc_world_matrix(falg.Mat4.new_identity())
  end
  -- update skinning matrix
  for i, skin in ipairs(self.skins) do
    skin:update(self.nodes)
  end

  love.graphics.push "all"
  for i, n in ipairs(self.nodes) do
    if n.mesh then
      n.mesh:draw(n.world_matrix, view, projection, nil, n.skinning)
    end
  end
  love.graphics.pop()
end

---@param seconds number
---@param loop boolean
---@param animation_selected number?
function Scene:set_time(seconds, loop, animation_selected)
  local active_animation = self.animations[animation_selected]
  if not active_animation then
    return
  end

  if loop then
    while seconds > active_animation.duration do
      seconds = seconds - active_animation.duration
    end
  end

  for _, curve in ipairs(active_animation.curves) do
    local node = self.nodes[curve.target.node + 1] --0to1origin
    if curve.target.path == "rotation" then
      -- cast Float4 to Quat
      local value = curve:from_time(seconds, "Quat")
      if value then
        node.local_transform.rotation = value
      end
    elseif curve.target.path == "translation" then
      local value = curve:from_time(seconds)
      if value then
        node.local_transform.translation = value
      end
    elseif curve.target.path == "scale" then
      local value = curve:from_time(seconds)
      if value then
        node.local_scale = value
      end
    else
      assert(false, curve.target.path, "not implemented")
    end
  end
end

---@return falg.AABB aabb
function Scene:get_bb()
  local aabb = falg.AABB.new()
  for _, root in ipairs(self.root_nodes) do
    root:calc_world_matrix(
      falg.Mat4.new_identity(),
      ---@param node lvrm.Node
      function(node)
        local m = node.world_matrix
        if node.mesh then
          local mesh_aabb = node.mesh:get_bb()
          mesh_aabb.min = m:apply_point(mesh_aabb.min)
          mesh_aabb.max = m:apply_point(mesh_aabb.max)
          aabb:extend(mesh_aabb.min)
          aabb:extend(mesh_aabb.max)
        else
          aabb:extend(falg.Float3(m._41, m._42, m._43))
        end
      end
    )
  end
  return aabb
end

return Scene
