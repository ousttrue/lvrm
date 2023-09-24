local Mesh = require "lvrm.mesh"
local Node = require "lvrm.node"

---@class lvrm.Scene: lvrm.SceneInstance
local Scene = {}
Scene.__index = Scene

---@return lvrm.Scene
function Scene.new()
  ---@class  lvrm.SceneInstance
  local instance = {
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

---@param reader GltfReader
---@return lvrm.Scene
function Scene.load(reader)
  local scene = Scene.new()

  -- meshes
  for _, gltf_mesh in ipairs(reader.root.meshes) do
    local mesh = Mesh.load(reader, gltf_mesh)
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
  for _, n in ipairs(self.root_nodes) do
    n:draw_recursive(view, projection)
  end
  love.graphics.pop()
end

return Scene
