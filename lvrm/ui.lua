local bit = require "bit"

---@class cimgui
local imgui = require "cimgui" -- cimgui is the folder containing the Lua module (the "src" folder in the github repository)

---@param is_leaf boolean
---@param is_selected boolean
local function NodeFlag(is_leaf, is_selected)
  local node_flags = imgui.love.TreeNodeFlags("OpenOnArrow", "OpenOnDoubleClick", "SpanAvailWidth")
  if is_leaf then
    node_flags = bit.bor(node_flags, imgui.love.TreeNodeFlags "Leaf")
  end
  if is_selected then
    node_flags = bit.bor(node_flags, imgui.love.TreeNodeFlags "Selected")
  end
  return node_flags
end

---@param jsonpath string
---@param prop string?
---@param node any
local function traverse(jsonpath, prop, node)
  local node_open = false
  local t = type(node)
  local is_leaf = t ~= "table"
  local flags = NodeFlag(is_leaf, false)
  if prop then
    imgui.TableNextRow()
    imgui.TableNextColumn()
    node_open = imgui.TreeNodeEx_StrStr(jsonpath, flags, "%s", prop)

    imgui.PushID_Str(jsonpath)
    imgui.TableNextColumn()
    if t == "nil" then
      imgui.TextUnformatted "nil"
    elseif t == "boolean" then
      imgui.Checkbox("", node)
    elseif t == "number" then
      imgui.Text("%f", node)
    elseif t == "string" then
      imgui.TextUnformatted(node)
    elseif t == "table" then
      if node[1] then
        -- array
        imgui.TextUnformatted(string.format("[%d]", #node))
      else
        -- dict
        imgui.TextUnformatted "{}"
      end
    end
    imgui.PopID()
  end

  if prop == nil or node_open then
    if t == "table" then
      if node[1] then
        -- array
        for i, v in ipairs(node) do
          local child_prop = string.format("%d", i)
          local child_jsonpath = jsonpath .. "." .. child_prop
          traverse(child_jsonpath, child_prop, v)
        end
      else
        -- dict
        for child_prop, v in pairs(node) do
          local child_jsonpath = jsonpath .. "." .. child_prop
          traverse(child_jsonpath, child_prop, v)
        end
      end
    end
  end

  if node_open then
    imgui.TreePop()
  end
end

local GLTF_JSON_COLS = { "prop", "value" }
local TABLE_FLAGS =
  imgui.love.TableFlags("Resizable", "RowBg", "Borders", "NoBordersInBody", "ScrollX", "ScrollY", "SizingFixedFit")

local M = {}

---@param root table
---@param title string
function M.ShowTree(root, title)
  imgui.PushStyleVar_Vec2(imgui.ImGuiStyleVar_WindowPadding, { 0.0, 0.0 })
  imgui.Begin(title)
  imgui.PopStyleVar()

  if imgui.BeginTable("glTFJsonTable", #GLTF_JSON_COLS, TABLE_FLAGS) then
    for _, col in ipairs(GLTF_JSON_COLS) do
      imgui.TableSetupColumn(col)
    end
    imgui.TableSetupScrollFreeze(0, 1)
    imgui.TableHeadersRow()
    imgui.PushStyleVar_Float(imgui.ImGuiStyleVar_IndentSpacing, 12)

    traverse("", nil, root)

    imgui.PopStyleVar()
    imgui.EndTable()
  end

  imgui.End()
end

return M
