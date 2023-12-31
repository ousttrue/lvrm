if os.getenv "LOCAL_LUA_DEBUGGER_VSCODE" == "1" then
  require("lldebugger").start()
end

package.path = package.cpath
  .. string.format(
    ";%s\\libs\\?.lua;%s\\libs\\?\\init.lua",
    love.filesystem.getSource(),
    love.filesystem.getSource()
  )

local ffi = require "ffi"
local falg = require "falg"
local logging = require "logging"
local UI = require "ui"

---@class cimgui
local imgui = require "cimgui"

---
--- State
---
---@class State: StateInstance
local State = {}
State.__index = State

---@return State
function State.new()
  ---@class StateInstance
  local instance = {
    docking_space = require("ui.docking_space").new "DOCKSPACE",
    time = require("lvrm.time").new(),
    mesh = require("ui.mesh").new(),
    animation = require("ui.animation").new(),
    logger = require("ui.logger").new(),
    skin = require("ui.skin").new(),
    scene_ui = require("ui.scene").new(),
    renderer = require("lvrm.rendertarget").new(),
  }
  ---@type State
  return setmetatable(instance, State)
end

---@param path string?
function State:load(path)
  if not path then
    return
  end
  logging.info("load %s...", path)
  local lvrm_reader = require "lvrm.gltf_reader"
  local reader = lvrm_reader.read_from_path(path)
  if reader then
    self.scene = nil
    self.error = nil
    self.json_root = reader.root
    local Scene = require "lvrm.scene"
    local ok, result = pcall(Scene.load, reader)
    if ok then
      self.scene = result
    else
      self.error = result
    end
  end
end

function State:draw()
  self.docking_space:begin()
  self.docking_space:draw()
end

local STATE = State.new()

-- love.data.newByteData()
love.load = function(args)
  imgui.love.Init "RGBA32" -- or imgui.love.Init("RGBA32") or imgui.love.Init("Alpha8")

  do
    local io = imgui.GetIO()
    -- Enable Docking
    io.ConfigFlags =
      bit.bor(io.ConfigFlags, imgui.ImGuiConfigFlags_DockingEnable)
  end

  local ja_font = "C:/Windows/Fonts/meiryo.ttc"
  do
    local util = require "lvrm.util"
    local data = util.readfile(ja_font)
    if not data then
      return
    end
    local font = love.graphics.newFont(love.data.newByteData(data), 32)
    if font then
      love.graphics.setFont(font)
    end
  end

  do
    local io = imgui.GetIO()
    local font =
      UI.AddFont(0, ja_font, 20, false, io.Fonts:GetGlyphRangesJapanese())
    -- emoji
    UI.AddFont(
      1,
      "C:/Windows/Fonts/Seguiemj.ttf",
      15,
      true,
      ffi.new("uint32_t[3]", 0x1, 0x1FFFF, 0)
    )
    io.FontDefault = font
    imgui.love.BuildFontAtlas "RGBA32"
  end

  STATE:load(args[1])

  local ShowJson = require "ui.gltf_json"
  STATE.docking_space
    :add("glTF", function()
      ShowJson(STATE.json_root)
    end)
    :no_padding()

  STATE.docking_space
    :add("scene", function()
      STATE.scene_ui:ShowScene(STATE.scene)
    end)
    :no_padding()

  STATE.docking_space
    :add("error", function()
      imgui.TextUnformatted "emoji: 🌻"
      if STATE.error then
        imgui.TextWrapped(STATE.error)
      end
    end)
    :no_padding()

  STATE.docking_space
    :add("mesh", function()
      STATE.mesh:ShowMesh(STATE.json_root, STATE.scene)
    end)
    :no_padding()

  STATE.docking_space
    :add("selected_mesh", function()
      STATE.mesh:ShowSelected(STATE.scene)
    end)
    :no_padding()

  local ShowTime = require "ui.time"
  STATE.docking_space:add("time", function()
    ShowTime(STATE.time)
  end)

  STATE.docking_space
    :add("animation", function()
      STATE.animation:ShowAnimation(STATE.scene)
    end)
    :no_padding()

  STATE.docking_space
    :add("skin", function()
      STATE.skin:ShowSkin(STATE.scene)
    end)
    :no_padding()

  STATE.docking_space
    :add("logger", function()
      STATE.logger:show()
    end)
    :no_padding()

  local gltf_sample_models = os.getenv "GLTF_SAMPLE_MODELS"
  if gltf_sample_models then
    local AssetViewer = require "ui.assetviewer"
    local asset = AssetViewer.new(gltf_sample_models .. "/2.0")

    STATE.docking_space
      :add("gltf_sample_models", function()
        local new_path = asset:Show()
        if new_path then
          STATE:load(new_path.path)
        end
      end)
      :no_padding()
  end

  STATE.docking_space
    :add("3d view", function()
      -- update canvas size
      local size = imgui.GetContentRegionAvail()
      STATE.renderer:update_size(size.x, size.y)
      local isActive, isHovered =
        UI.DraggableImage("image_button", STATE.renderer.colorcanvas, size)

      -- render scene to rendertarget
      if STATE.scene and STATE.animation.selected then
        STATE.scene:set_time(
          STATE.time.seconds,
          STATE.time.loop[0],
          STATE.animation.selected
        )
      end

      STATE.renderer:render(function(view, projection)
        if STATE.scene then
          STATE.scene:draw(view, projection)
        end
      end, {
        isActive = isActive,
        isHovered = isHovered,
        target = STATE.scene,
      })
    end)
    :no_padding()
    :no_scrollbar()

  if os.getenv "LOCAL_LUA_DEBUGGER_VSCODE" == "1" then
    STATE.docking_space:add("imgui demo", imgui.ShowDemoWindow, true)
  end
end

love.draw = function()
  imgui.NewFrame()

  local io = imgui.GetIO()
  STATE.time:update(io.DeltaTime)
  STATE:draw()

  -- code to render imgui
  imgui.Render()
  imgui.love.RenderDrawLists()
end

love.update = function(dt)
  imgui.love.Update(dt)
end

love.mousemoved = function(x, y, ...)
  imgui.love.MouseMoved(x, y)
end

love.mousepressed = function(x, y, button, ...)
  imgui.love.MousePressed(button)
end

love.mousereleased = function(x, y, button, ...)
  imgui.love.MouseReleased(button)
end

love.wheelmoved = function(x, y)
  logging.debug("wheel: %f, %f", x, y)
  imgui.love.WheelMoved(x, y)
end

love.keypressed = function(key, ...)
  imgui.love.KeyPressed(key)
end

love.keyreleased = function(key, ...)
  imgui.love.KeyReleased(key)
end

love.textinput = function(t)
  imgui.love.TextInput(t)
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
