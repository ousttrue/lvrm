--- [falg] Ffi linear ALGebra
---
--- * https://luajit.org/ext_ffi.html
---   * https://luajit.org/ext_ffi_tutorial.html
---   * https://luajit.org/ext_ffi_api.html
---   * https://luajit.org/ext_ffi_semantics.html

---@type falg.Float2
local Float2 = require "falg.float2"

---@type falg.Float3
local Float3 = require "falg.float3"

---@type falg.Float4
local Float4 = require "falg.float4"

---@type falg.Quat
local Quat = require "falg.quat"

---@type falg.Mat4
local Mat4 = require "falg.mat4"

---@type falg.EuclideanTransform
local EuclideanTransform = require "falg.euclidean_transform"

return {
  Float2 = Float2,
  Float3 = Float3,
  Float4 = Float4,
  Quat = Quat,
  Mat4 = Mat4,
  EuclideanTransform = EuclideanTransform,
}
