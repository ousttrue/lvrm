---@class Scene
---@operator call: Scene
local Scene = {}
setmetatable(Scene, {
  ---@param self Scene
  ---@return Scene
  __call = function(self)
    return setmetatable({
      ---@type Mesh
      meshes = {},
    }, { __index = self })
  end,
})

function Scene:draw() end

---
---comment
---@param reader GltfReader
---@return Scene
function Scene:Load(reader)
  return Scene()
end

return Scene
