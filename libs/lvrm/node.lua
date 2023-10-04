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
  if self.local_scale then
    assert(false, "local_scale not impl")
  end
  return self.local_transform:matrix()
end

---@param gltf_node gltf.Node
---@param default_name string
---@return lvrm.Node
function Node.load(gltf_node, default_name)
  local node = Node.new(gltf_node.name and gltf_node.name or default_name)

  if gltf_node.matrix then
    assert(false, "decompose")
    -- node.local_matrix:set_array(gltf_node.matrix)
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

return Node
