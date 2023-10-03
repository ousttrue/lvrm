local ffi = require "ffi"

---
--- Curve
---
---@class lvrm.AnimationCurve: lvrm.AnimationCurveInstance
local AnimationCurve = {}
AnimationCurve.__index = AnimationCurve

local STRIDE_MAP = {
  [16] = "Float4",
}

---@param target gltf.AnimationChannelTarget
---@param count integer time[n] and values[n]
---@param times ffi.cdata* float[]
---@param values ffi.cdata* T[]
---@param stride integer value stride
---@return lvrm.AnimationCurve
function AnimationCurve.new(target, count, times, values, stride)
  -- volatile? workaround
  local time_array = ffi.new("float[?]", count)
  ffi.copy(time_array, times, count * 4)
  local value_array = ffi.new(STRIDE_MAP[stride] .. "[?]", count)
  ffi.copy(value_array, values, count * stride)

  ---@class lvrm.AnimationCurveInstance
  local instance = {
    target = target,
    count = count,
    times = time_array,
    t0 = times[0], -- 0origin
    duration = times[count - 1], -- 0origin
    values = value_array,
    value_stride = stride,
  }

  ---@type lvrm.AnimationCurve
  return setmetatable(instance, AnimationCurve)
end

---@param i integer 0origin
---@retun ffi.cdata*
function AnimationCurve:from_frame(i)
  return self.values[i]
end

---@param seconds number
function AnimationCurve:from_time(seconds)
  assert(seconds)
  if seconds < self.t0 then
    return self.values[0]
  end

  for i = 0, self.count do
    local t = self.times[i]
    assert(t)
    if t >= seconds then
      local value = self:from_frame(i)
      return value
    end
  end

  return self.values[self.count - 1]
end

---
--- Animation
---
---@class lvrm.Animation: lvrm.AnimationInstance
local Animation = {}
Animation.__index = Animation

---@param name string
---@return lvrm.Animation
function Animation.new(name)
  ---@class lvrm.AnimationInstance
  ---@field duration number?
  local instance = {
    id = ffi.new "int[1]",
    name = name,
    duration = 0,
    ---@type lvrm.AnimationCurve[]
    curves = {},
    ---@type table<string, lvrm.AnimationCurve>
    curve_map = {},
  }

  ---@type lvrm.Animation
  return setmetatable(instance, Animation)
end

---@param gltf_animation gltf.Animation
---@return lvrm.Animation
function Animation.load(gltf_animation)
  return Animation.new(gltf_animation.name)
end

---@param target gltf.AnimationChannelTarget
---@param count integer time[n] and values[n]
---@param time ffi.cdata* float*
---@param values ffi.cdata*
---@param stride integer value stride
function Animation:AddCurve(target, count, time, values, stride)
  local curve = AnimationCurve.new(target, count, time, values, stride)
  table.insert(self.curves, curve)
  if curve.duration > self.duration then
    -- get max duration
    self.duration = curve.duration
  end
end

return Animation
