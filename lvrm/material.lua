---@class lvrm.Material
---@field shader love.Shader
local Material = {}

local vs=[[
vec4 position(mat4 transform_projection, vec4 vertex_position) {
  return vertex_position;
}
]]

local fs=[[
vec4 effect(vec4 color, Image t, vec2 texture_coords, vec2 screen_coords) {
  return vec4(1,1,1,1);
}
]]

function Material.new()
  local shader = love.graphics.newShader(vs, fs)
  return setmetatable({
    shader=shader,
  }, { __index = Material })
end

function Material:use()
  love.graphics.setShader(self.shader)
end

return Material