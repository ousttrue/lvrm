local lvrm_shader = require "lvrm.shader"

---@class lvrm.Material:lvrm.MaterialInstance
local Material = {}

---@param name string
---@param shader love.Shader
---@return lvrm.Material
function Material.new(name, shader)
  assert(shader)
  ---@class lvrm.MaterialInstance
  ---@field color_texture love.Texture?
  local instance = {
    name = name,
    shader = shader,
  }
  ---@type lvrm.Material
  return setmetatable(instance, { __index = Material })
end

---@param gltf_material gltf.Material
---@param textures love.Texture[]
---@return lvrm.Material
function Material.load(gltf_material, textures)
  local shader = lvrm_shader.get "simple"
  assert(shader)
  local material = Material.new(gltf_material.name, shader)

  local pbr = gltf_material.pbrMetallicRoughness
  if pbr then
    if pbr.baseColorTexture then
      material.color_texture = textures[pbr.baseColorTexture.index + 1] -- 1origin
    end
  end

  return material
end

function Material:use()
  love.graphics.setShader(self.shader)
end

return Material
