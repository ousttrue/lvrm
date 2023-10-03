local ffi = require "ffi"
local bit = require "bit"
---@class cimgui
local imgui = require "cimgui"

---
--- Dock
---
---@class Dock: DockInstance
local Dock = {}
Dock.__index = Dock

---@param name string
---@param draw function
---@param include_begin boolean
---@return Dock
function Dock.new(name, draw, include_begin)
  ---@class DockInstance
  ---@field draw_callback function
  local instance = {
    name = name,
    p_open = ffi.new("bool[1]", true),
    window_flags = 0,
    window_styles = {},
  }

  if include_begin then
    instance.draw_callback = draw
  else
    instance.draw_callback = function(p_open)
      for _, s in ipairs(instance.window_styles) do
        s()
      end
      local is_begin = imgui.Begin(name, p_open, instance.window_flags)
      imgui.PopStyleVar(#instance.window_styles)

      if is_begin then
        draw()
      end
      imgui.End()
    end
  end

  ---@type Dock
  return setmetatable(instance, Dock)
end

---@return Dock
function Dock:no_padding()
  table.insert(self.window_styles, function()
    imgui.PushStyleVar_Vec2(imgui.ImGuiStyleVar_WindowPadding, { 0.0, 0.0 })
  end)
  return self
end

---@return Dock
function Dock:no_scrollbar()
  self.window_flags =
    bit.bor(self.window_flags, imgui.ImGuiWindowFlags_NoScrollbar, imgui.ImGuiWindowFlags_NoScrollWithMouse)
  return self
end

function Dock:draw()
  if self.p_open[0] then
    self.draw_callback(self.p_open)
  end
end

---
--- DockingSpace
---
---@class DockingSpace: DockingSpaceInstance
local DockingSpace = {}
DockingSpace.__index = DockingSpace

---@param name string
---@return DockingSpace
function DockingSpace.new(name)
  ---@class DockingSpaceInstance
  local instance = {
    name = name,
    ---@type Dock[]
    docks = {},
  }
  ---@type DockingSpace
  return setmetatable(instance, DockingSpace)
end

---@param name string
---@param draw function
---@param include_begin boolean?
---@return Dock
function DockingSpace:add(name, draw, include_begin)
  local dock
  dock = Dock.new(name, draw, include_begin)
  table.insert(self.docks, dock)
  return dock
end

local DOCKSPACE_WINDOW_FLAGS = imgui.love.WindowFlags(
  "NoDocking",
  "NoTitleBar",
  "NoCollapse",
  "NoResize",
  "NoMove",
  "NoBringToFrontOnFocus",
  "NoNavFocus",
  "NoBackground",
  "MenuBar"
)

---@return integer width
---@return integer height
function DockingSpace:begin()
  local dockspace_flags = imgui.love.DockNodeFlags "PassthruCentralNode"

  local viewport = imgui.GetMainViewport()
  imgui.SetNextWindowPos(viewport.WorkPos)
  imgui.SetNextWindowSize(viewport.WorkSize)
  imgui.SetNextWindowViewport(viewport.ID)
  imgui.PushStyleVar_Float(imgui.ImGuiStyleVar_WindowRounding, 0)
  imgui.PushStyleVar_Float(imgui.ImGuiStyleVar_WindowBorderSize, 0)

  imgui.PushStyleVar_Vec2(imgui.ImGuiStyleVar_WindowPadding, { 0, 0 })
  imgui.Begin(self.name, nil, DOCKSPACE_WINDOW_FLAGS)
  imgui.PopStyleVar()
  imgui.PopStyleVar(2)

  local size = imgui.GetContentRegionAvail()

  local dockspace_id = imgui.GetID_Str(self.name)
  imgui.DockSpace(dockspace_id, { 0.0, 0.0 }, dockspace_flags)

  self:show_menu()

  return size.x, size.y
end

function DockingSpace:show_menu()
  if imgui.BeginMenuBar() then
    if imgui.BeginMenu "docking" then
      for _, dock in ipairs(self.docks) do
        imgui.MenuItem_BoolPtr(dock.name, nil, dock.p_open)
      end
      imgui.EndMenu()
    end
    imgui.EndMainMenuBar()
  end
end

function DockingSpace:draw()
  for _, d in ipairs(self.docks) do
    d:draw()
  end
end

return DockingSpace
