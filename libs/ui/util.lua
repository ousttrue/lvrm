local bit = require "bit"
---@class cimgui
local imgui = require "cimgui"

local M = {}

---@param opts {is_leaf: boolean, is_selected: boolean}?
function M.make_node_flags(opts)
  local node_flags = imgui.love.TreeNodeFlags("OpenOnArrow", "OpenOnDoubleClick", "SpanAvailWidth")
  if opts and opts.is_leaf then
    node_flags = bit.bor(node_flags, imgui.love.TreeNodeFlags "Leaf")
  end
  if opts and opts.is_selected then
    node_flags = bit.bor(node_flags, imgui.love.TreeNodeFlags "Selected")
  end
  return node_flags
end

local TABLE_FLAGS =
  imgui.love.TableFlags("Resizable", "RowBg", "Borders", "NoBordersInBody", "ScrollX", "ScrollY", "SizingFixedFit")

---@param name string
---@param cols string[]
---@param body function
function M.show_table(name, cols, body)
  if imgui.BeginTable(name, #cols, TABLE_FLAGS) then
    for _, col in ipairs(cols) do
      imgui.TableSetupColumn(col)
    end
    imgui.TableSetupScrollFreeze(0, 1)
    imgui.TableHeadersRow()
    imgui.PushStyleVar_Float(imgui.ImGuiStyleVar_IndentSpacing, 12)

    body()

    imgui.PopStyleVar()
    imgui.EndTable()
  end
end

return M
