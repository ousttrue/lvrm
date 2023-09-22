if os.getenv "LOCAL_LUA_DEBUGGER_VSCODE" == "1" then
  require("lldebugger").start()
end

local bit = require "bit"

-- Make sure the shared library can be found through package.cpath before loading the module.
-- For example, if you put it in the LÖVE save directory, you could do something like this:
local lib_path = love.filesystem.getSaveDirectory() .. "/libraries"
local extension = jit.os == "Windows" and "dll" or jit.os == "Linux" and "so" or jit.os == "OSX" and "dylib"
package.cpath = string.format("%s;%s/?.%s", package.cpath, lib_path, extension)

---@class cimgui
local imgui = require "cimgui" -- cimgui is the folder containing the Lua module (the "src" folder in the github repository)

local lvrm_reader = require "lvrm.gltf_reader"
local LvrmMesh = require "lvrm.mesh"

local STATE = {}

---@param path string
---@return string?
local function readfile(path)
  local r = io.open(path, "rb")
  if r then
    local data = r:read "*a"
    r:close()
    return data
  end
end

-- love.data.newByteData()
love.load = function(args)
  local data = readfile "C:/Windows/Fonts/meiryo.ttc"
  if data then
    local font = love.graphics.newFont(love.data.newByteData(data), 32)
    if font then
      love.graphics.setFont(font)
    end
  end

  imgui.love.Init() -- or imgui.love.Init("RGBA32") or imgui.love.Init("Alpha8")

  STATE.model = lvrm_reader.read_from_bytes(readfile(args[1]))
  local root = STATE.model.root
  if root then
    if root.meshes then
      for _, mesh in ipairs(root.meshes) do
        local lmesh = LvrmMesh()
        for _, prim in ipairs(mesh.primitives) do
          -- local data = STATE.model:read_accessor_bytes(prim.attributes.POSITION)
        end
      end
    end
  end
end

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
---@param prop string
---@param node boolean|string|table
local function Traverse(jsonpath, prop, node)
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
          Traverse(child_jsonpath, child_prop, v)
        end
      else
        -- dict
        for child_prop, v in pairs(node) do
          local child_jsonpath = jsonpath .. "." .. child_prop
          Traverse(child_jsonpath, child_prop, v)
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

local function ShowTree()
  imgui.PushStyleVar_Vec2(imgui.ImGuiStyleVar_WindowPadding, { 0.0, 0.0 })
  imgui.Begin "glTF"
  imgui.PopStyleVar()
  if STATE.model then
    if imgui.BeginTable("glTFJsonTable", #GLTF_JSON_COLS, TABLE_FLAGS) then
      for _, col in ipairs(GLTF_JSON_COLS) do
        imgui.TableSetupColumn(col)
      end
      imgui.TableSetupScrollFreeze(0, 1)
      imgui.TableHeadersRow()
      imgui.PushStyleVar_Float(imgui.ImGuiStyleVar_IndentSpacing, 12)

      Traverse("", nil, STATE.model.root)

      imgui.PopStyleVar()
      imgui.EndTable()
    end
  end
  imgui.End()
end

love.draw = function()
  if STATE.model then
    love.graphics.print(STATE.model:tostring(), 400, 300)
  end

  -- example window
  imgui.ShowDemoWindow()

  -- TODO: JsonTree
  if STATE.model then
    ShowTree(STATE.model.root)
  end

  -- TODO: 3D View

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
