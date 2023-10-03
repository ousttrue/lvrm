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
  local instance = {
    id = ffi.new "int[1]",
    ---@type string
    name = name,
    ---@type lvrm.Node[]
    children = {},

    ---@type falg.EuclideanTransform
    local_transform = falg.EuclideanTransform.new(),
    local_scale = falg.Float3(1, 1, 1),
  }
  ---@type lvrm.Node
  return setmetatable(instance, Node)
end

---@param gltf_node gltf.Node
---@param default_name string
---@return lvrm.Node
function Node.load(gltf_node, default_name)
  local node = Node.new(gltf_node.name and gltf_node.name or default_name)

  if gltf_node.matrix then
    node.local_matrix:set_array(gltf_node.matrix)
  else
    if gltf_node.translation then
      node.local_matrix:translation(unpack(gltf_node.translation))
    end
    if gltf_node.rotation then
      node.local_matrix:rotation(unpack(gltf_node.rotation))
    end
    if gltf_node.scale then
      --assert(false, "scale not implementd")
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
  local world = self.local_matrix * parent
  if self.mesh then
    self.mesh:draw(world, view, projection)
  end

  for _, child in ipairs(self.children) do
    child:draw_recursive(world, view, projection)
  end
end

return Node
