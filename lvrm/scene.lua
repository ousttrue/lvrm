local Mesh = require "lvrm.mesh"
local falg = require "falg"
local IDENTITY = falg.Mat4.new():identity()

---@class lvrm.SceneInstance
---@field meshes lvrm.Mesh[]

---@class lvrm.Scene: lvrm.SceneInstance
local Scene = {}
---@return lvrm.Scene
function Scene.new()
  local instance = {
    meshes = {
      Mesh:new(),
    },
  }
  return setmetatable(instance, { __index = Scene })
end

---@param reader GltfReader
---@return lvrm.Scene
function Scene.Load(reader)
  return Scene.new()
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
