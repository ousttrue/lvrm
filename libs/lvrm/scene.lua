local Material = require "lvrm.material"
local Mesh = require "lvrm.mesh"
local Node = require "lvrm.node"
local falg = require "falg"

local IDENTITY = falg.Mat4.new():identity()

---@class lvrm.Scene: lvrm.SceneInstance
local Scene = {}
Scene.__index = Scene

---@return lvrm.Scene
function Scene.new()
  ---@class  lvrm.SceneInstance
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
  }
  ---@type lvrm.Scene
  return setmetatable(instance, Scene)
end

---@param bytes string
---@return love.Texture
local function load_texture(bytes)
  local data = love.data.newByteData(bytes)
  local image = love.image.newImageData(data)
  local texture = love.graphics.newImage(image)
  image:release()
  return texture
end

---@param reader GltfReader
---@return lvrm.Scene
function Scene.load(reader)
  local scene = Scene.new()

  -- textures
  for _, gltf_texture in ipairs(reader.root.textures) do
    local image_bytes = reader:read_image_bytes(gltf_texture.source)
    local texture = load_texture(image_bytes)
    table.insert(scene.textures, texture)
  end

  -- materials
  for _, gltf_material in ipairs(reader.root.materials) do
    local material = Material.load(gltf_material, scene.textures)
    table.insert(scene.materials, material)
  end

  -- meshes
  for _, gltf_mesh in ipairs(reader.root.meshes) do
    local mesh = Mesh.load(reader, gltf_mesh, scene.materials)
    table.insert(scene.meshes, mesh)
  end

  -- nodes
  for i, gltf_node in ipairs(reader.root.nodes) do
    local node = Node.load(string.format("%d", i), gltf_node, string.format("__node__:02d", i))

    if gltf_node.mesh then
      node.mesh = scene.meshes[gltf_node.mesh + 1] -- 1origin
    end

    table.insert(scene.nodes, node)
  end

  -- chilldren / parent
  for i, gltf_node in ipairs(reader.root.nodes) do
    local node = scene.nodes[i]
    if gltf_node.children then
      for _, c in ipairs(gltf_node.children) do
        local child = scene.nodes[c + 1] -- 1origin
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

  return scene
end

---@param view falg.Mat4
---@param projection falg.Mat4
function Scene:draw(view, projection)
  love.graphics.push "all"
  love.graphics.setDepthMode("lequal", true)
  for _, n in ipairs(self.root_nodes) do
    n:draw_recursive(IDENTITY, view, projection)
  end
  love.graphics.pop()
end

return Scene
