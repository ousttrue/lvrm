local falg = require "libs.falg"

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
    ---@type string
    name = name,
    ---@type lvrm.Node[]
    children = {},
    ---@type falg.Mat4
    matrix = falg.Mat4.new():identity(),
  }
  ---@type lvrm.Node
  return setmetatable(instance, Node)
end

---@param gltf_node gltf.Node
---@param default_name string
---@return lvrm.Node
function Node.load(gltf_node, default_name)
  return Node.new(gltf_node.name and gltf_node.name or default_name)
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

---@param view falg.Mat4
---@param projection falg.Mat4
function Node:draw_recursive(view, projection)
  if self.mesh then
    self.mesh:draw(self.matrix, view, projection)
  end

  for _, child in ipairs(self.children) do
    child:draw_recursive(view, projection)
  end
end

return Node
