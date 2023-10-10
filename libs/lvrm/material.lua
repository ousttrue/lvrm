require "falg"
local ffi = require "ffi"
local Shader = require "lvrm.shader"

local function make_texture()
  -- Create some buffer with size 2x2.
  local image = love.image.newImageData(2, 2)

  -- Update certain pixels:
  image:setPixel(0, 1, 128, 0, 0, 255)

  local texture = love.graphics.newImage(image)
  image:release()

  -- Texture will update automatically if changed.
  return texture
end

---@class lvrm.Material:lvrm.MaterialInstance
local Material = {
  gpu_skinning = true,
}
Material.__index = Material

---@param name string
---@param shader_type lvrm.ShaderType
---@return lvrm.Material
function Material.new(name, shader_type)
  -- if type(shader) == "string" then
  --   shader = lvrm_shader.get(shader)
  -- end
  assert(shader_type)
  ---@class lvrm.MaterialInstance
  ---@field color_texture love.Texture?
  local instance = {
    name = name,
    shader = Shader.new(shader_type),
  }
  ---@type lvrm.Material
  return setmetatable(instance, Material)
end

---@param gltf_material gltf.Material
---@param textures love.Texture[]
---@return lvrm.Material
function Material.load(gltf_material, textures)
  local material = Material.new(gltf_material.name, Shader.ShaderType.Unlit)

  local pbr = gltf_material.pbrMetallicRoughness
  if pbr then
    if pbr.baseColorTexture then
      material.color_texture = textures[pbr.baseColorTexture.index + 1] -- 1origin
    end
  end

  return material
end

---@param skinning lvrm.Skinning?
function Material:use(skinning)
  self.shader:use(skinning, Material.gpu_skinning)
  love.graphics.setFrontFaceWinding "cw"
  love.graphics.setMeshCullMode "back"
  love.graphics.setDepthMode("lequal", true)
end

local MAT4_SIZE = ffi.sizeof "Mat4"
assert(MAT4_SIZE)
local M = love.data.newByteData(MAT4_SIZE)
---@param name string
---@param m falg.Mat4
function Material:send_mat4(name, m)
  ffi.copy(M:getFFIPointer(), m, MAT4_SIZE)
  self.shader.lg_shader:send(name, M, "column")
end

return Material
