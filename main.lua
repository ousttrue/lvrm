if os.getenv "LOCAL_LUA_DEBUGGER_VSCODE" == "1" then
  require("lldebugger").start()
end

-- Make sure the shared library can be found through package.cpath before loading the module.
-- For example, if you put it in the LÖVE save directory, you could do something like this:
local lib_path = love.filesystem.getSaveDirectory() .. "/libraries"
local extension = jit.os == "Windows" and "dll" or jit.os == "Linux" and "so" or jit.os == "OSX" and "dylib"
package.cpath = string.format("%s;%s/?.%s", package.cpath, lib_path, extension)

---@class cimgui
local imgui = require "cimgui"

local lvrm_reader = require "lvrm.gltf_reader"
local lvrm_ui = require "lvrm.ui"
local Scene = require "lvrm.scene"
local Camera = require "lvrm.camera"

local STATE = {
  camera = Camera.new(),
}

---@param path string?
---@return string?
local function readfile(path)
  if not path then
    return
  end
  local r = io.open(path, "rb")
  if r then
    local data = r:read "*a"
    r:close()
    return data
  end
end

-- love.data.newByteData()
love.load = function(args)
  imgui.love.Init() -- or imgui.love.Init("RGBA32") or imgui.love.Init("Alpha8")

  local data = readfile "C:/Windows/Fonts/meiryo.ttc"
  if data then
    local font = love.graphics.newFont(love.data.newByteData(data), 32)
    if font then
      love.graphics.setFont(font)
    end
  end

  data = readfile(args[1])
  if data then
    local model = lvrm_reader.read_from_bytes(data)
    if model then
      STATE.json_root = model.root
      STATE.scene = Scene.Load(model)
    end
  end
end

love.draw = function()
  if STATE.scene then
    STATE.scene:draw(STATE.camera.view, STATE.camera.projection)
  end

  -- example window
  imgui.ShowDemoWindow()

  if STATE.json_root then
    lvrm_ui.ShowTree(STATE.json_root, "glTF")
  end

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
    local io = imgui.GetIO()
    local v =io.MouseDown[imgui.ImGuiMouseButton_Middle]
    if io.MouseDown[imgui.ImGuiMouseButton_Middle] then
      STATE.camera:shift(io.MouseDelta.x, io.MouseDelta.y)
    end
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
    STATE.camera:dolly(y)
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
