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
    translation = t,
    rotation = r,
  }
  ---@type falg.EuclideanTransform
  return setmetatable(instance, EuclideanTransform)
end

---@return falg.Mat4
function EuclideanTransform:matrix()
  ---@type falg.Mat4
  local m
  if self.rotation then
    m = Mat4.new_quat(
      self.rotation.X,
      self.rotation.Y,
      self.rotation.Z,
      self.rotation.W
    )
  else
    m = Mat4.new_identity()
  end

  if self.translation then
    m._41 = self.translation.X
    m._42 = self.translation.Y
    m._43 = self.translation.Z
  end
  return m
end

return EuclideanTransform
