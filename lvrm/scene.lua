---@class Scene
---@operator call: Scene
local Scene = {}
setmetatable(Scene, {
  ---@param self Scene
  ---@return Scene
  __call = function(self)
    return setmetatable({}, { __index = self })
  end,
})

function Scene:draw() end

---
---comment
---@param reader GltfReader
function Scene:Load(reader) end

return Scene
