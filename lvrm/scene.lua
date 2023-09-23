local Mesh = require "lvrm.mesh"
local falg = require "falg"
local IDENTITY = falg.Mat4.new():identity()

---@class lvrm.Scene: lvrm.SceneInstance
local Scene = {}
Scene.__index = Scene

---@return lvrm.Scene
function Scene.new()
  ---@class  lvrm.SceneInstance
  local instance = {
    ---@type lvrm.Mesh[]
    meshes = {},
  }
  ---@type lvrm.Scene
  return setmetatable(instance, Scene)
end

---@param reader GltfReader
---@return lvrm.Scene
function Scene.load(reader)
  local scene = Scene.new()

  for _, m in ipairs(reader.root.meshes) do
    local mesh = Mesh.load(reader, m)
    -- local mesh = Mesh.new_triangle()
    table.insert(scene.meshes, mesh)
  end

  return scene
end

---@param view falg.Mat4
---@param projection falg.Mat4
function Scene:draw(view, projection)
  love.graphics.push "all"
  for _, m in ipairs(self.meshes) do
    m:draw(IDENTITY, view, projection)
  end
  love.graphics.pop()
end

return Scene
