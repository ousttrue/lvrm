---@class cimgui
local imgui = require "cimgui"

---@param time lvrm.Time
function ShowTime(time)
  if imgui.Button "rewind" then
    time.seconds = 0
  end

  imgui.SameLine()
  imgui.Checkbox("play", time.is_play)
  imgui.SameLine()
  imgui.Checkbox("loop", time.loop)

  imgui.TextUnformatted(string.format("%f", time.seconds))
end

return ShowTime
