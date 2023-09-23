--- [falg] Ffi linear ALGebra
local ffi = require "ffi"

---@class falg.Mat4Instance
---@field data love.ByteData

---@class falg.Mat4: falg.Mat4Instance
local Mat4 = {}
Mat4.__index = Mat4
ffi.cdef [[
typedef union {
    struct {
        float _11, _12, _13, _14;
        float _21, _22, _23, _24;
        float _31, _32, _33, _34;
        float _41, _42, _43, _44;
    };
    float array[16];
} Mat4;
]]
local MAT4_SIZE = ffi.sizeof "Mat4"
assert(MAT4_SIZE == 4 * 16, "no size for cdef Mat4")
---@cast MAT4_SIZE number

---Allocate a love.ByteData for Mat4(float16)
---@return falg.Mat4
function Mat4.new()
  local data = love.data.newByteData(MAT4_SIZE)
  return setmetatable({
    data = data,
  }, Mat4)
end

function Mat4:get_cdata()
  return ffi.cast("Mat4*", self.data:getFFIPointer())[0] -- ffi is 0 origin
end

---@param array number[] Must 16 values
---@return falg.Mat4 self
function Mat4:set_array(array)
  assert(#array == 16)
  local p = self:get_cdata()
  for i, v in ipairs(array) do
    p.array[i - 1] = v -- ffi is 0 origin
  end
  return self
end

---@param m falg.Mat4
function Mat4:set(m)
  assert(getmetatable(m) == Mat4)
  ffi.copy(self:get_cdata(), m:get_cdata(), MAT4_SIZE)
end

---@return falg.Mat4 self
function Mat4:identity()
  return self:set_array {
    1,
    0,
    0,
    0,
    --
    0,
    1,
    0,
    0,
    --
    0,
    0,
    1,
    0,
    --
    0,
    0,
    0,
    1,
  }
end

---
function Mat4:__mul(rhs)
  local m = Mat4.new()
  local p = m:get_cdata()
  local l = self:get_cdata()
  local r = rhs:get_cdata()
  p._11 = l._11 * r._11 + l._12 * r._21 + l._13 * r._31 + l._14 * r._41
  p._12 = l._11 * r._12 + l._12 * r._22 + l._13 * r._32 + l._14 * r._42
  p._13 = l._11 * r._13 + l._12 * r._23 + l._13 * r._33 + l._14 * r._43
  p._14 = l._11 * r._14 + l._12 * r._24 + l._13 * r._34 + l._14 * r._44

  p._21 = l._21 * r._11 + l._22 * r._21 + l._23 * r._31 + l._24 * r._41
  p._22 = l._21 * r._12 + l._22 * r._22 + l._23 * r._32 + l._24 * r._42
  p._23 = l._21 * r._13 + l._22 * r._23 + l._23 * r._33 + l._24 * r._43
  p._24 = l._21 * r._14 + l._22 * r._24 + l._23 * r._34 + l._24 * r._44

  p._31 = l._31 * r._11 + l._32 * r._21 + l._33 * r._31 + l._34 * r._41
  p._32 = l._31 * r._12 + l._32 * r._22 + l._33 * r._32 + l._34 * r._42
  p._33 = l._31 * r._13 + l._32 * r._23 + l._33 * r._33 + l._34 * r._43
  p._34 = l._31 * r._14 + l._32 * r._24 + l._33 * r._34 + l._34 * r._44

  p._41 = l._41 * r._11 + l._42 * r._21 + l._43 * r._31 + l._44 * r._41
  p._42 = l._41 * r._12 + l._42 * r._22 + l._43 * r._32 + l._44 * r._42
  p._43 = l._41 * r._13 + l._42 * r._23 + l._43 * r._33 + l._44 * r._43
  p._44 = l._41 * r._14 + l._42 * r._24 + l._43 * r._34 + l._44 * r._44
  return m
end

---@param b number bottom
---@param t number top
---@param l number left
---@param r number right
---@param n number near
---@param f number far
---@return falg.Mat4 self
function Mat4:frustum(b, t, l, r, n, f)
  local p = self:get_cdata()
  p._11 = 2 * n / (r - l)
  p._22 = 2 * n / (t - b)

  p._31 = (r + l) / (r - l)
  p._32 = (t + b) / (t - b)
  p._33 = -(f + n) / (f - n)
  p._34 = -1

  p._43 = -2 * f * n / (f - n)
  return self
end

---like gluPerspective
---@param fovy number
---@param aspectRatio number
---@param near number
---@param far number
---@return falg.Mat4 self
function Mat4:perspective(fovy, aspectRatio, near, far)
  local scale = math.tan(fovy) * near
  local r = aspectRatio * scale
  local l = -r
  local t = scale
  local b = -t
  return self:frustum(b, t, l, r, near, far)
end

---Set _41, _42, _43.
---@param x number
---@param y number
---@param z number
---@return falg.Mat4 self
function Mat4:translation(x, y, z)
  local p = self:get_cdata()
  p._41 = x
  p._42 = y
  p._43 = z
  return self
end

---Update 3x3
---1
--- cS
--- sc
---@param rad number
---@return falg.Mat4 self
function Mat4:rotation_x(rad)
  local c = math.cos(rad)
  local s = math.sin(rad)
  local m = self:get_cdata()
  m._11 = 1
  m._22 = c
  m._33 = c
  m._44 = 1
  m._23 = -s
  m._32 = s
  return self
end

---Update 3x3
---c S
--- 1
---s c
---@param rad number
---@return falg.Mat4 self
function Mat4:rotation_y(rad)
  local c = math.cos(rad)
  local s = math.sin(rad)
  local m = self:get_cdata()
  m._11 = c
  m._22 = 1
  m._33 = c
  m._44 = 1
  m._13 = -s
  m._31 = s
  return self
end

---Update 3x3
---cS
---sc
---  1
---@param rad number
---@return falg.Mat4 self
function Mat4:rotation_z(rad)
  local c = math.cos(rad)
  local s = math.sin(rad)
  local m = self:get_cdata()
  m._11 = c
  m._22 = c
  m._33 = 1
  m._44 = 1
  m._21 = -s
  m._12 = s
  return self
end

return {
  Mat4 = Mat4,
}
