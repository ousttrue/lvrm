local Float3 = require "falg.float3"
local Quat = require "falg.quat"
local Mat4 = require "falg.mat4"

---@class falg.EuclideanTransform: falg.EuclideanTransformInstance
local EuclideanTransform = {}
EuclideanTransform.__index = EuclideanTransform

---@param t falg.Float3?
---@param r falg.Quat?
---@return falg.EuclideanTransform
function EuclideanTransform.new(t, r)
  ---@class falg.EuclideanTransformInstance
  ---@field translation falg.Float3?
  ---@field rotation falg.Quat?
  local instance = {
    tranlsation = t,
    rotation = r,
  }
  ---@type falg.EuclideanTransform
  return setmetatable(instance, EuclideanTransform)
end

---@return falg.Mat4
function EuclideanTransform:matrix()
  ---@type falg.Mat4
  local m = Mat4()
  if self.rotation then
    ---@type falg.Quat
    local q = self.rotation
    m:from_quat(q.X, q.Y, q.Z, q.W)
  else
    m = Mat4.new_identity()
  end

  if self.translation then
    ---@type falg.Float3
    local t = self.translation
    m._41 = t.X
    m._42 = t.Y
    m._43 = t.Z
  end
  return m
end

return EuclideanTransform
