local ffi = require "ffi"
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
---@return Dock
function Dock.new(name, draw)
  local p_open = ffi.new("bool[1]", true)

  ---@class DockInstance
  ---@field draw function
  local instance = {
    name = name,
    p_open = p_open,
    draw_callback = draw,
  }

  ---@type Dock
  return setmetatable(instance, Dock)
end

function Dock:no_padding() end

function Dock:no_scrollbar() end

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
  if include_begin then
    dock = Dock.new(name, draw)
  else
    local wrap = function(p_open)
      imgui.PushStyleVar_Vec2(imgui.ImGuiStyleVar_WindowPadding, { 0.0, 0.0 })
      local is_begin = imgui.Begin(name, p_open)
      imgui.PopStyleVar()

      if is_begin then
        draw()
      end
      imgui.End()
    end
    dock = Dock.new(name, wrap)
  end
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

  return size.x, size.y
end

function DockingSpace:draw()
  for _, d in ipairs(self.docks) do
    d:draw()
  end
end

return DockingSpace
