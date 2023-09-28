local ffi = require "ffi"

---@class lvrm.AnimationCurve: lvrm.AnimationCurveInstance
local AnimationCurve = {}
AnimationCurve.__index = AnimationCurve

---@return lvrm.AnimationCurve
function AnimationCurve.new()
  ---@class lvrm.AnimationCurveInstance
  local instance = {}

  ---@type lvrm.AnimationCurve
  return setmetatable(instance, AnimationCurve)
end

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
---@param time ffi.cdata* float*
---@param values ffi.cdata*
function Animation:AddCurve(target, time, values)
  local curve = AnimationCurve.new()
  table.insert(self.curves, curve)
  self.curve_map[target] = curve
end

return Animation
