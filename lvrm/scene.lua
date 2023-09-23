local Mesh = require "lvrm.mesh"

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


function Scene:draw() 
  for _, m in ipairs(self.meshes) do
    m:draw()
  end
end


return Scene
