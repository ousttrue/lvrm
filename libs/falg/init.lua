--- [falg] Ffi linear ALGebra
---
--- * https://luajit.org/ext_ffi.html
---   * https://luajit.org/ext_ffi_tutorial.html
---   * https://luajit.org/ext_ffi_api.html
---   * https://luajit.org/ext_ffi_semantics.html

local M = {
  ---@type falg.Float2
  Float2 = require "falg.float2",
  ---@type falg.Float3
  Float3 = require "falg.float3",
  ---@type falg.Float4
  Float4 = require "falg.float4",
  ---@type falg.Quat
  Quat = require "falg.quat",
  ---@type falg.Mat4
  Mat4 = require "falg.mat4",
  ---@type falg.EuclideanTransform
  EuclideanTransform = require "falg.euclidean_transform",
  ---@type falg.AABB
  AABB = require "falg.aabb",
}
return M
