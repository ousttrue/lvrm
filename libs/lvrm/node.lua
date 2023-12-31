local ffi = require "ffi"
local falg = require "falg"

local Skinning = require "lvrm.Skinning"

---@class lvrm.Node: lvrm.NodeInstance
local Node = {}
Node.__index = Node

---@param name string
---@return lvrm.Node
function Node.new(name)
  ---@class lvrm.NodeInstance
  ---@field parent lvrm.Node?
  ---@field mesh lvrm.Mesh?
  ---@field local_scale falg.Float3?
  ---@field skinning lvrm.Skinning?
  local instance = {
    id = ffi.new "int[1]",
    ---@type string
    name = name,
    ---@type lvrm.Node[]
    children = {},
    ---@type falg.EuclideanTransform
    local_transform = falg.EuclideanTransform.new(),

    world_matrix = falg.Mat4.new_identity(),
  }
  ---@type lvrm.Node
  return setmetatable(instance, Node)
end

---@return string
function Node:__tostring()
  return string.format("{%s}", self.name)
end

---@retun falg.Mat4
function Node:local_matrix()
  local m = self.local_transform:matrix()
  if self.local_scale then
    m = falg.Mat4.new_scale(
      self.local_scale.X,
      self.local_scale.Y,
      self.local_scale.Z
    ) * m
  end
  return m
end

---@param gltf_node gltf.Node
---@param default_name string
---@return lvrm.Node
function Node.load(gltf_node, default_name)
  local node = Node.new(gltf_node.name and gltf_node.name or default_name)

  if gltf_node.matrix then
    local m = falg.Mat4(unpack(gltf_node.matrix))
    local t, r, s = m:decompose()
    node.local_transform.translation = t
    node.local_transform.rotation = r
    node.local_scale = s
  else
    if gltf_node.translation then
      node.local_transform.translation =
        falg.Float3(unpack(gltf_node.translation))
    end
    if gltf_node.rotation then
      node.local_transform.rotation = falg.Quat(unpack(gltf_node.rotation))
    end
    if gltf_node.scale then
      if
        gltf_node.scale[1] ~= 1
        or gltf_node.scale[2] ~= 1
        or gltf_node.scale[3] ~= 1
      then
        node.local_scale = falg.Float3(unpack(gltf_node.scale))
      end
    end
  end

  return node
end

---@param child lvrm.Node
function Node:remove_child(child)
  for i, c in ipairs(self.children) do
    if c == child then
      table.remove(self.children, i)
      child.parent = nil
      return
    end
  end
end

---@param child lvrm.Node
function Node:add_child(child)
  if child.parent then
    child.parent:remove_child(child)
  end
  table.insert(self.children, child)
  child.parent = self
end

---@param callback fun(Node)?
---@param parent_matrix falg.Mat4
function Node:calc_world_matrix(parent_matrix, callback)
  self.world_matrix = self:local_matrix() * parent_matrix
  if callback then
    callback(self)
  else
    local a = 0
  end
  for _, child in ipairs(self.children) do
    child:calc_world_matrix(self.world_matrix, callback)
  end
end

return Node
