local Float3 = require "falg.float3"
local Quat = require "falg.quat"

---@class falg.EuclideanTransform
local EuclideanTransform = {}
EuclideanTransform.__index = EuclideanTransform

---@param t falg.Float3
---@param r falg.Quat
---@return falg.EuclideanTransform
function EuclideanTransform.new(t, r)
  ---@class falg.EuclideanTransformInstance
  local instance = {
    tranlsation = t and t or Float3(1, 1, 1),
    rotation = r and r or Quat(0, 0, 0, 1),
  }
  ---@type falg.EuclideanTransform
  return setmetatable(instance, EuclideanTransform)
end

return EuclideanTransform
