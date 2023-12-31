local ffi = require "ffi"

---
--- Curve
---
---@class lvrm.AnimationCurve: lvrm.AnimationCurveInstance
local AnimationCurve = {}
AnimationCurve.__index = AnimationCurve

---@param target gltf.AnimationChannelTarget
---@param times Span float[]
---@param values Span T[]
---@return lvrm.AnimationCurve
function AnimationCurve.new(target, times, values)
  ---@class lvrm.AnimationCurveInstance
  local instance = {
    target = target,
    times = times,
    t0 = times.ptr[0], -- 0origin
    duration = times.ptr[times.len - 1], -- 0origin
    values = values,
  }

  ---@type lvrm.AnimationCurve
  return setmetatable(instance, AnimationCurve)
end

---@param i integer 0origin
---@param t string? Float3, Quat..etc
---@retun ffi.cdata*
function AnimationCurve:from_frame(i, cast_type)
  if cast_type then
    return ffi.cast(cast_type .. "*", self.values.ptr)[i]
  else
    return self.values.ptr[i]
  end
end

---@param seconds number
---@param t string? Float3, Quat..etc
function AnimationCurve:from_time(seconds, cast_type)
  assert(seconds)
  if seconds < self.t0 then
    return self.values.ptr[0]
  end

  for i = 0, self.times.len - 1 do
    local t = self.times.ptr[i]
    assert(t)
    if t >= seconds then
      local value = self:from_frame(i, cast_type)
      return value
    end
  end

  return self.values.ptr[self.times.len - 1]
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
---@param time Span float*
---@param values Span
function Animation:AddCurve(target, time, values)
  local curve = AnimationCurve.new(target, time, values)
  table.insert(self.curves, curve)
  if curve.duration > self.duration then
    -- get max duration
    self.duration = curve.duration
  end
end

return Animation
