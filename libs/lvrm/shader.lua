---@param path string?
---@return string?
local function readfile(path)
  if not path then
    return
  end
  local r = io.open(path, "rb")
  if r then
    local data = r:read "*a"
    r:close()
    return data
  end
end

---@class lvrm.Shader: lvrm.ShaderInstance
local Shader = {}
Shader.__index = Shader

local Cache = {}

local ShaderTypeToName = {}

---@return string
function Cache:get_source(vs_fs, shader_type, skinning_type)
  local path = string.format(
    "%s/shaders/%s.%s",
    love.filesystem.getSource(),
    shader_type,
    vs_fs
  )
  local content = readfile(path)
  assert(content)
  if skinning_type ~= Shader.SkinningType.None then
    content = "#define USE_SKINNING 1\n\n" .. content
  end
  return content
end

---@param shader_type lvrm.ShaderType
---@param skinning_type lvrm.SkinningType
---@return love.Shader
function Cache:get_or_create_shader(shader_type, skinning_type)
  local type_cache = self[shader_type]
  if not type_cache then
    type_cache = {}
    self[shader_type] = type_cache
  end

  local shader_cache = type_cache[skinning_type]
  if shader_cache then
    return shader_cache
  end

  local vs = self:get_source("vs", shader_type, skinning_type)
  local fs = self:get_source("fs", shader_type, skinning_type)

  local shader = love.graphics.newShader(vs, fs)
  type_cache[skinning_type] = shader
  return shader
end

---@enum lvrm.ShaderType
Shader.ShaderType = {
  Unlit = "unlit",
  Pbr = "pbr",
}

---@enum lvrm.SkinningType
Shader.SkinningType = {
  None = 0,
  Cpu = 1,
  Gpu = 2,
}

---@param shader_type lvrm.ShaderType
---@return lvrm.Shader
function Shader.new(shader_type)
  ---@class lvrm.ShaderInstance
  ---@field lg_shader love.Shader?
  local instance = {
    shader_type = shader_type,
    skinning = Shader.SkinningType.None,
  }
  ---@type lvrm.Shader
  return setmetatable(instance, Shader)
end

---@param skinning lvrm.Skinning?
---@param gpu_skinning boolean
function Shader:use(skinning, gpu_skinning)
  if not self.lg_shader then
    -- initialize
    local skinning_type = Shader.SkinningType.None
    if skinning then
      if gpu_skinning then
        skinning_type = Shader.SkinningType.Gpu
      else
        skinning_type = Shader.SkinningType.Cpu
      end
    end
    self.lg_shader = Cache:get_or_create_shader(self.shader_type, skinning_type)
  end
  assert(self.lg_shader)
  love.graphics.setShader(self.lg_shader)
  if skinning and gpu_skinning then
    skinning:send("joints_matrices", self.lg_shader)
  end
end

return Shader
