local ffi = require "ffi"
local falg = require "falg"

---@type lvrm.Span
local Span = require "lvrm.Span"

---@class lvrm.Skinning: lvrm.SkinningInstance
local Skinning = {}
Skinning.__index = Skinning

local JOINTS_UNIFORM_LIMIT = 256
local FORMAT = { { format = "floatvec4", name = "" } }

---@param joints integer[]
---@param inversed_bind_matrices lvrm.Span mat4[N]
---@return lvrm.Skinning
function Skinning.new(joints, inversed_bind_matrices)
  assert(inversed_bind_matrices.len < JOINTS_UNIFORM_LIMIT)
  local buffer = love.data.newByteData(JOINTS_UNIFORM_LIMIT * 16 * 4)
  local span = Span.new(
    ffi.cast("Mat4*", buffer:getFFIPointer()),
    inversed_bind_matrices.len,
    16 * 4
  )
  ---@class lvrm.SkinningInstance
  local instance = {
    ---@type table<lvrm.Node, integer> 0 origin
    joints = joints,
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
---@param inversed_bind_matrices lvrm.Span
---@return lvrm.Skinning
function Skinning.load(gltf_skin, inversed_bind_matrices)
  return Skinning.new(gltf_skin.joints, inversed_bind_matrices)
end

--- copy inversed_bind_matrices to array
function Skinning:reset()
  ffi.copy(
    self.span.ptr,
    self.inversed_bind_matrices.ptr,
    4 * 16 * self.inversed_bind_matrices.len
  )
end

function Skinning:send(name, shader)
  -- shader:send(name, self.buffer)
  shader:send(name, "column", self.buffer)
end

-- function Skinning:set_matrix(node, m)
--   local index = self.joint_map[node]
--   assert(index)
--   self.span.ptr[index] = m
-- end

---@param nodes lvrm.Node[]
function Skinning:update(nodes)
  for i = 0, #self.joints - 1 do
    local node = nodes[self.joints[i + 1] + 1] -- 0to1 origin
    self.span.ptr[i] = self.inversed_bind_matrices.ptr[i] * node.world_matrix --1to0 origin
  end
end

---@param v falg.Float3
---@param j integer 0origin
---@param w number
---@return falg.Float3
function Skinning:calc(v, j, w)
  if w > 0 then
    return self.span.ptr[j]:transform_position(v):scale(w)
  else
    return falg.Float3(0, 0, 0)
  end
end

return Skinning
