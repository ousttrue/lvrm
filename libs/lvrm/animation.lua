local ffi = require "ffi"

---@class lvrm.AnimationCurve: lvrm.AnimationCurveInstance
local AnimationCurve = {}
AnimationCurve.__index = AnimationCurve

---@param target gltf.AnimationChannelTarget
---@param count integer time[n] and values[n]
---@param time ffi.cdata* float[]
---@param values ffi.cdata* T[]
---@param stride integer value stride
---@return lvrm.AnimationCurve
function AnimationCurve.new(target, count, time, values, stride)
  ---@class lvrm.AnimationCurveInstance
  local instance = {
    target = target,
    count = count,
    time = time,
    values = values,
    value_stride = stride,
    duration = time[count - 1], -- 0origin
  }

  ---@type lvrm.AnimationCurve
  return setmetatable(instance, AnimationCurve)
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
  local instance = {
    id = ffi.new "int[1]",
    name = name,

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

---@param target string
---@param count integer time[n] and values[n]
---@param time ffi.cdata* float*
---@param values ffi.cdata*
---@param stride integer value stride
function Animation:AddCurve(target, count, time, values, stride)
  local curve = AnimationCurve.new(target, count, time, values, stride)
  table.insert(self.curves, curve)
end

return Animation
