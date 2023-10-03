local bit = require "bit"
---@class cimgui
local imgui = require "cimgui"

local util = require "ui.util"

---@param node lvrm.Node
local function traverse_node(node)
  imgui.TableNextRow()
  imgui.TableNextColumn()
  local flags = util.make_node_flags { is_leaf = #node.children == 0 }
  local node_open = imgui.TreeNodeEx_Ptr(node.id, flags, "%s", node.name)

  imgui.TableNextColumn()

  imgui.TableNextColumn()
  if node.mesh then
    imgui.TextUnformatted(string.format("%d", #node.mesh.submeshes))
  end

  if node_open then
    for _, child in ipairs(node.children) do
      traverse_node(child)
    end

    imgui.TreePop()
  end
end

---@param scene lvrm.Scene
function ShowScene(scene)
  if not scene then
    return
  end
  util.show_table("sceneTreeTable", { "name", "TRS", "mesh" }, function()
    for _, n in ipairs(scene.root_nodes) do
      traverse_node(n)
    end
  end)
end

return ShowScene
