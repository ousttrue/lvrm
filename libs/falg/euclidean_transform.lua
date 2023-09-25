---@class falg.EuclideanTransform
local EuclideanTransform = {}
EuclideanTransform.__index = EuclideanTransform

---@param t falg.Float3
---@param r falg.Quat
---@return falg.EuclideanTransform
function EuclideanTransform.new(t, r)
  ---@class falg.EuclideanTransformInstance
  local instance = {
    tranlsation = t,
    rotation = r,
  }
  ---@type falg.EuclideanTransform
  return setmetatable(instance, EuclideanTransform)
end

return EuclideanTransform
