---@class Mesh
---@operator call: Mesh
local Mesh = {}
setmetatable(Mesh, {
  ---@param self Mesh
  ---@return Mesh
  __call = function(self)
    return setmetatable({}, { __index = self })
  end,
})

return Mesh
