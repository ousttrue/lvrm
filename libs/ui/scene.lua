local bit = require "bit"
---@class cimgui
local imgui = require "cimgui"

local util = require "ui.util"

---@class Scene: SceneInstance
local Scene = {}
Scene.__index = Scene

---@return Scene
function Scene.new()
  ---@class SceneInstance
  ---@field selected lvrm.Node?
  local instance = {
    splitter = util.Splitter.new(),
  }
  ---@type Scene
  return setmetatable(instance, Scene)
end

---@param node lvrm.Node
function Scene:traverse_node(node)
  imgui.TableNextRow()

  -- 1
  imgui.TableNextColumn()
  local flags = util.make_node_flags {
    is_leaf = #node.children == 0,
    is_selected = node == self.selected,
  }
  local node_open = imgui.TreeNodeEx_Ptr(node.id, flags, "%s", node.name)
  if imgui.IsItemClicked() and not imgui.IsItemToggledOpen() then
    self.selected = node
  end

  -- 2
  imgui.TableNextColumn()
  if node.mesh then
    imgui.TextUnformatted(string.format("%d", #node.mesh.submeshes))
  end

  if node_open then
    for _, child in ipairs(node.children) do
      self:traverse_node(child)
    end

    imgui.TreePop()
  end
end

---@param scene lvrm.Scene
function Scene:ShowScene(scene)
  if not scene then
    return
  end

  local size = imgui.GetContentRegionAvail()

  local left, right = self.splitter:SplitVertical { size.x, size.y }

  imgui.PushStyleVar_Vec2(imgui.ImGuiStyleVar_WindowPadding, { 0.0, 0.0 })
  if imgui.BeginChild_Str("selectNode", { left, -1 }, true) then
    util.show_table(
      "sceneTreeTable",
      { "name", "mesh/skin/morph/humanoid/spring/constraint...etc" },
      function()
        for _, n in ipairs(scene.root_nodes) do
          self:traverse_node(n)
        end
      end
    )
  end
  imgui.EndChild()

  imgui.SameLine()

  if imgui.BeginChild_Str("selectedNode", { right, -1 }, true) then
    if self.selected then
      local node = self.selected
      -- local
      do
        imgui.TextUnformatted "local"
        imgui.TextUnformatted(
          string.format("%s", node.local_transform.translation)
        )
        imgui.TextUnformatted(
          string.format("%s", node.local_transform.rotation)
        )
        imgui.TextUnformatted(string.format("%s", node.local_scale))
      end

      -- world
      do
        imgui.TextUnformatted "world"
        local m = node.world_matrix
        local t, r, s = m:decompose()
        imgui.TextUnformatted(string.format("%s", t))
        imgui.TextUnformatted(string.format("%s", r))
        imgui.TextUnformatted(string.format("%s", s))
      end
    end
  end
  imgui.EndChild()

  imgui.PopStyleVar()
end

return Scene
