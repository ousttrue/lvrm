require "falg"
local ffi = require "ffi"
local lvrm_shader = require "lvrm.shader"

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
local Material = {}

---@param name string
---@param shader love.Shader | string
---@return lvrm.Material
function Material.new(name, shader)
  if type(shader) == "string" then
    shader = lvrm_shader.get(shader)
  end
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
  local shader = lvrm_shader.get "skinning"
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
  self.shader:send(name, M, "column")
end

return Material
