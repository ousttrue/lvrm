local ffi = require "ffi"
---@class cimgui
local imgui = require "cimgui"

---@class Time: TimeInstance
local Time = {}
Time.__index = Time

---@return Time
function Time.new()
  ---@class TimeInstance
  local instance = {
    seconds = 0,
    loop = ffi.new("bool[1]", true),
    is_play = ffi.new("bool[1]", false),
  }

  ---@type Time
  return setmetatable(instance, Time)
end

function Time:update()
  if self.is_play[0] then -- 0origin
    local io = imgui.GetIO()
    self.seconds = self.seconds + io.DeltaTime
  end
end

function Time:show()
  if imgui.Button "rewind" then
    self.seconds = 0
  end

  imgui.SameLine()
  imgui.Checkbox("play", self.is_play)
  imgui.SameLine()
  imgui.Checkbox("loop", self.loop)

  imgui.TextUnformatted(string.format("%f", self.seconds))
end

return Time
