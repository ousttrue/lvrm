local ffi = require "ffi"

---@class lvrm.Time: lvrm.TimeInstance
local Time = {}
Time.__index = Time

---@return lvrm.Time
function Time.new()
  ---@class lvrm.TimeInstance
  local instance = {
    ---@type number
    seconds = 0,
    loop = ffi.new("bool[1]", true),
    is_play = ffi.new("bool[1]", false),
  }

  ---@type lvrm.Time
  return setmetatable(instance, Time)
end

---@param delta number
function Time:update(delta)
  if self.is_play[0] then -- 0origin
    self.seconds = self.seconds + delta
  end
end

return Time
