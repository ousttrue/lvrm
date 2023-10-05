if os.getenv "LOCAL_LUA_DEBUGGER_VSCODE" == "1" then
  require("lldebugger").start()
end

package.path = package.cpath
  .. string.format(";%s\\libs\\?.lua;%s\\libs\\?\\init.lua", love.filesystem.getSource(), love.filesystem.getSource())

local falg = require "falg"
local lvrm_reader = require "lvrm.gltf_reader"
local RenderTarget = require "lvrm.rendertarget"
local Time = require "ui.time"

local UI = require "ui"
local DockingSpace = require "ui.docking_space"
local AssetViewer = require "ui.assetviewer"

local util = require "lvrm.util"
local Scene = require "lvrm.scene"
local Camera = require "lvrm.camera"
---@class cimgui
local imgui = require "cimgui"

---@class State: StateInstance
local State = {}
State.__index = State

---@return State
function State.new()
  ---@class StateInstance
  local instance = {
    docking_space = DockingSpace.new "DOCKSPACE",
    time = Time.new(),
    mesh = UI.MeshGui.new(),
    animation = UI.AnimationGui.new(),
  }
  ---@type State
  return setmetatable(instance, State)
end

---@param path string?
function State:load(path)
  if not path then
    return
  end
  local reader = lvrm_reader.read_from_path(path)
  if reader then
    self.json_root = reader.root
    self.scene = Scene.load(reader)
  end
end

function State:draw()
  self.time:update()
  self.docking_space:begin()
  self.docking_space:draw()
end

local STATE = State.new()

-- love.data.newByteData()
love.load = function(args)
  imgui.love.Init() -- or imgui.love.Init("RGBA32") or imgui.love.Init("Alpha8")

  do
    local io = imgui.GetIO()
    -- Enable Docking
    io.ConfigFlags = bit.bor(io.ConfigFlags, imgui.ImGuiConfigFlags_DockingEnable)
  end

  local data = util.readfile "C:/Windows/Fonts/meiryo.ttc"
  if data then
    local font = love.graphics.newFont(love.data.newByteData(data), 32)
    if font then
      love.graphics.setFont(font)
    end
  end

  STATE:load(args[1])

  STATE.docking_space
    :add("glTF", function()
      UI.ShowJson(STATE.json_root)
    end)
    :no_padding()

  STATE.docking_space
    :add("scene", function()
      UI.ShowScene(STATE.scene)
    end)
    :no_padding()

  STATE.docking_space
    :add("mesh", function()
      STATE.mesh:ShowMesh(STATE.json_root, STATE.scene)
    end)
    :no_padding()

  STATE.docking_space
    :add("animation", function()
      STATE.animation:ShowAnimation(STATE.scene)
    end)
    :no_padding()

  STATE.docking_space:add("time", function()
    STATE.time:show()
  end)

  STATE.docking_space:add("selected_mesh", function()
    STATE.mesh:ShowSelected(STATE.scene)
  end)

  local gltf_sample_models = os.getenv "GLTF_SAMPLE_MODELS"
  if gltf_sample_models then
    local asset = AssetViewer.new(gltf_sample_models .. '/2.0')

    STATE.docking_space:add("gltf_sample_models", function()
      asset:Show()
    end)
  end

  local r = RenderTarget.new()
  local camera = Camera.new()
  STATE.docking_space
    :add("RenderTarget", function()
      -- update canvas size
      local size = imgui.GetContentRegionAvail()
      r:update_size(size.x, size.y)
      local isActive, isHovered = UI.DraggableImage("image_button", r.colorcanvas, size)

      -- update camera
      camera:update(size.x, size.y, isActive, isHovered)

      -- render scene to rendertarget
      if STATE.scene then
        if STATE.animation.selected then
          STATE.scene:set_time(STATE.time.seconds, STATE.time.loop[0], STATE.animation.selected)
        end

        r:render(function()
          STATE.scene:draw(camera.view, camera.projection)
        end)
      end
    end)
    :no_padding()
    :no_scrollbar()

  if os.getenv "LOCAL_LUA_DEBUGGER_VSCODE" == "1" then
    STATE.docking_space:add("imgui demo", imgui.ShowDemoWindow, true)
  end
end

love.draw = function()
  STATE:draw()

  -- code to render imgui
  imgui.Render()
  imgui.love.RenderDrawLists()
end

love.update = function(dt)
  imgui.love.Update(dt)
  imgui.NewFrame()
end

love.mousemoved = function(x, y, ...)
  imgui.love.MouseMoved(x, y)
  if not imgui.love.GetWantCaptureMouse() then
    -- your code here
  end
end

love.mousepressed = function(x, y, button, ...)
  imgui.love.MousePressed(button)
  if not imgui.love.GetWantCaptureMouse() then
    -- your code here
  end
end

love.mousereleased = function(x, y, button, ...)
  imgui.love.MouseReleased(button)
  if not imgui.love.GetWantCaptureMouse() then
    -- your code here
  end
end

love.wheelmoved = function(x, y)
  imgui.love.WheelMoved(x, y)
  if not imgui.love.GetWantCaptureMouse() then
    -- your code here
    -- STATE.camera:dolly(y)
  end
end

love.keypressed = function(key, ...)
  imgui.love.KeyPressed(key)
  if not imgui.love.GetWantCaptureKeyboard() then
    -- your code here
  end
end

love.keyreleased = function(key, ...)
  imgui.love.KeyReleased(key)
  if not imgui.love.GetWantCaptureKeyboard() then
    -- your code here
  end
end

love.textinput = function(t)
  imgui.love.TextInput(t)
  if imgui.love.GetWantCaptureKeyboard() then
    -- your code here
  end
end

love.quit = function()
  return imgui.love.Shutdown()
end

-- for gamepad support also add the following:

love.joystickadded = function(joystick)
  imgui.love.JoystickAdded(joystick)
  -- your code here
end

love.joystickremoved = function(joystick)
  imgui.love.JoystickRemoved()
  -- your code here
end

love.gamepadpressed = function(joystick, button)
  imgui.love.GamepadPressed(button)
  -- your code here
end

love.gamepadreleased = function(joystick, button)
  imgui.love.GamepadReleased(button)
  -- your code here
end

-- choose threshold for considering analog controllers active, defaults to 0 if unspecified
local threshold = 0.2

love.gamepadaxis = function(joystick, axis, value)
  imgui.love.GamepadAxis(axis, value, threshold)
  -- your code here
end
