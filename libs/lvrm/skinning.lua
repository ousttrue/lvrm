local ffi = require "ffi"

---@type lvrm.Span
local Span = require "lvrm.Span"

---@class lvrm.Skinning: lvrm.SkinningInstance
local Skinning = {}
Skinning.__index = Skinning

local JOINTS_UNIFORM_LIMIT = 256
local FORMAT = { { format = "floatvec4", name = "" } }

---@param inversed_bind_matrices lvrm.Span mat4[N]
---@return lvrm.Skinning
function Skinning.new(inversed_bind_matrices)
  assert(inversed_bind_matrices.len < JOINTS_UNIFORM_LIMIT)
  local buffer = love.data.newByteData(JOINTS_UNIFORM_LIMIT * 16 * 4)
  local span = Span.new(ffi.cast("Mat4*", buffer:getFFIPointer()), inversed_bind_matrices.len, 16 * 4)
  ---@class lvrm.SkinningInstance
  local instance = {
    ---@type lvrm.Node[]
    joints = {},
    inversed_bind_matrices = inversed_bind_matrices,
    buffer = buffer,
    span = span,
  }
  ---@type lvrm.Skinning
  local skin = setmetatable(instance, Skinning)
  skin:reset()
  return skin
end

---@param gltf_skin gltf.Skin
---@return lvrm.Skinning
function Skinning.load(gltf_skin, nodes, inversed_bind_matrices)
  local skin = Skinning.new(inversed_bind_matrices)
  for i, joint in ipairs(gltf_skin.joints) do
    table.insert(skin.joints, nodes[i])
  end
  return skin
end

--- copy inversed_bind_matrices to array
function Skinning:reset()
  ffi.copy(self.span.ptr, self.inversed_bind_matrices.ptr, 4 * 16 * self.inversed_bind_matrices.len)
end

function Skinning:send(name, shader)
  -- shader:send(name, self.buffer)
  shader:send(name, "column", self.buffer)
end

return Skinning
