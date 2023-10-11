local bit = require "bit"
local ffi = require "ffi"
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

-- https://github.com/ocornut/imgui/issues/319
--
-- [usage]
-- auto size = ImGui::GetContentRegionAvail();
-- static float sz1 = 300;
-- float sz2 = size.x - sz1 - 5;
-- grapho::imgui::Splitter(true, 5.0f, &sz1, &sz2, 100, 100);
-- ImGui::BeginChild("1", ImVec2(sz1, -1), true);
-- ImGui::EndChild();
-- ImGui::SameLine();
-- ImGui::BeginChild("2", ImVec2(sz2, -1), true);
-- ImGui::EndChild();
---@param split_vertically boolean
---@param thickness number
---@param size1 ffi.cdata* float[1]
---@param size2 ffi.cdata* float[1]
---@param min_size1 number
---@param min_size2 number
---@param splitter_long_axis_size number?
local function split(split_vertically, thickness, size1, size2, min_size1, min_size2, splitter_long_axis_size)
  splitter_long_axis_size = splitter_long_axis_size and splitter_long_axis_size or -1.0
  -- using namespace ImGui;
  -- ImGuiContext& g = *GImGui;
  -- ImGuiWindow* window = g.CurrentWindow;
  local window = imgui.GetCurrentWindow()
  local id = imgui.GetID_Str "##split"
  local Min = window.DC.CursorPos
    + (split_vertically and ffi.new("ImVec2", size1[0], 0.0) or ffi.new("ImVec2", 0.0, size1[0]))
  local Max = Min
    + imgui.CalcItemSize(
      split_vertically and { thickness, splitter_long_axis_size } or { splitter_long_axis_size, thickness },
      0.0,
      0.0
    )
  imgui.SplitterBehavior(
    { Min, Max },
    id,
    split_vertically and imgui.ImGuiAxis_X or imgui.ImGuiAxis_Y,
    size1,
    size2,
    min_size1,
    min_size2,
    0.0
  )
end

---@class Splitter: SplitterInstance
local Splitter = {}
Splitter.__index = Splitter

---@return Splitter
function Splitter.new()
  ---@class SplitterInstance
  local instance = {
    -- size1 = ffi.new "float[1]",
    size2 = ffi.new "float[1]",
  }
  ---@type Splitter
  return setmetatable(instance, Splitter)
end

-- +-+
-- +-+
-- +-+
---@param size number[]
---@return number top
---@return number bottom
function Splitter:SplitHorizontal(size)
  if not self.size1 then
    self.size1 = ffi.new("float[1]", size[2] * 0.5)
  end
  self.size2[0] = size[2] - self.size1[0] - 5
  split(false, 5.0, self.size1, self.size2, 100, 100)
  return self.size1[0], self.size2[0]
end

-- +-+-+
-- +-+-+
---@param size number[]
---@return number left
---@return number right
function Splitter:SplitVertical(size)
  if not self.size1 then
    self.size1 = ffi.new("float[1]", size[1] * 0.5)
  end
  self.size2[0] = size[1] - self.size1[0] - 5
  split(true, 5.0, self.size1, self.size2, 1, 1)
  return self.size1[0], self.size2[0]
end

M.Splitter = Splitter

return M
