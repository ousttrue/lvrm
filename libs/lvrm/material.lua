local lvrm_shader = require "lvrm.shader"

---@class lvrm.Material
---@field shader love.Shader
local Material = {}

function Material.new()
  local shader = lvrm_shader.get "simple"
  return setmetatable({
    shader = shader,
  }, { __index = Material })
end

function Material:use()
  love.graphics.setShader(self.shader)
end

return Material
