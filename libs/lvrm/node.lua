local ffi = require "ffi"
local falg = require "falg"

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
  local instance = {
    id = ffi.new "int[1]",
    ---@type string
    name = name,
    ---@type lvrm.Node[]
    children = {},

    ---@type falg.EuclideanTransform
    local_transform = falg.EuclideanTransform.new(),
  }
  ---@type lvrm.Node
  return setmetatable(instance, Node)
end

---@retun falg.Mat4
function Node:local_matrix()
  local m = self.local_transform:matrix()
  if self.local_scale then
    return falg.Mat4.new_scale(self.local_scale.X, self.local_scale.Y, self.local_scale.Z)
  else
    return m
  end
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
      node.local_transform.translation = falg.Float3(unpack(gltf_node.translation))
    end
    if gltf_node.rotation then
      node.local_transform.rotation = falg.Quat(unpack(gltf_node.rotation))
    end
    if gltf_node.scale then
      if gltf_node.scale[1] ~= 1 or gltf_node.scale[2] ~= 1 or gltf_node.scale[3] ~= 1 then
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

---@param parent falg.Mat4
---@param view falg.Mat4
---@param projection falg.Mat4
function Node:draw_recursive(parent, view, projection)
  local world = self:local_matrix() * parent
  if self.mesh then
    self.mesh:draw(world, view, projection)
  end

  for _, child in ipairs(self.children) do
    child:draw_recursive(world, view, projection)
  end
end

---@param parent_matrix falg.Mat4
---@param callback fun(lvrm.Node, falg.Mat4)
function Node:calc_world_matrix(parent_matrix, callback)
  local world = parent_matrix * self:local_matrix()
  callback(self, world)
  for _, child in ipairs(self.children) do
    child:calc_world_matrix(world, callback)
  end
end

return Node
