local ffi = require "ffi"

local Float3 = require "falg.float3"
local Quat = require "falg.quat"

ffi.cdef [[
typedef struct {
  float _11, _12, _13, _14;
  float _21, _22, _23, _24;
  float _31, _32, _33, _34;
  float _41, _42, _43, _44;
} Mat4;
]]
local MAT4_SIZE = ffi.sizeof "Mat4"
assert(MAT4_SIZE == 4 * 16, "no size for cdef Mat4")

---@class falg.Mat4
---@field _11 number
---@field _12 number
---@field _13 number
---@field _14 number
---@field _21 number
---@field _22 number
---@field _23 number
---@field _24 number
---@field _31 number
---@field _32 number
---@field _33 number
---@field _34 number
---@field _41 number
---@field _42 number
---@field _43 number
---@field _44 number
local Mat4 = {}
Mat4.__index = Mat4

function Mat4:__tostring()
  return string.format(
    "[%0.2f, %0.2f, %0.2f, %0.2f][%0.2f, %0.2f, %0.2f, %0.2f][%0.2f, %0.2f, %0.2f, %0.2f][%0.2f, %0.2f, %0.2f, %0.2f]",
    self._11,
    self._12,
    self._13,
    self._14,
    self._21,
    self._22,
    self._23,
    self._24,
    self._31,
    self._32,
    self._33,
    self._34,
    self._41,
    self._42,
    self._43,
    self._44
  )
end

function Mat4.__eq(lhs, rhs)
  local l = lhs._11
  local r = lhs._11
  return l == r
  --   and self._12 == rhs._12
  --   and self._13 == rhs._13
  --   and self._14 == rhs._14
  --   and self._21 == rhs._21
  --   and self._22 == rhs._22
  --   and self._23 == rhs._23
  --   and self._24 == rhs._24
  --   and self._31 == rhs._31
  --   and self._32 == rhs._32
  --   and self._33 == rhs._33
  --   and self._34 == rhs._34
  --   and self._41 == rhs._41
  --   and self._42 == rhs._42
  --   and self._43 == rhs._43
  --   and self._44 == rhs._44
  -- )
end

-- ---Allocate a love.ByteData for Mat4(float16)
-- ---@return falg.Mat4
-- function Mat4.new()
--   local data = love.data.newByteData(MAT4_SIZE)
--   return setmetatable({
--     data = data,
--   }, Mat4)
-- end

-- function Mat4:get_cdata()
--   return ffi.cast("Mat4*", self.data:getFFIPointer())[0] -- ffi is 0 origin
-- end

---@param array number[] Must 16 values
---@return falg.Mat4 self
function Mat4:set_array(array)
  assert(#array == 16)
  -- local p = self:get_cdata()
  self._11 = array[1]
  self._12 = array[2]
  self._13 = array[3]
  self._14 = array[4]
  self._21 = array[5]
  self._22 = array[6]
  self._23 = array[7]
  self._24 = array[8]
  self._31 = array[9]
  self._32 = array[10]
  self._33 = array[11]
  self._34 = array[12]
  self._41 = array[13]
  self._42 = array[14]
  self._43 = array[15]
  self._44 = array[16]
  ---@type falg.Mat4
  return self
end

-- ---@param m falg.Mat4
-- function Mat4:set(m)
--   ffi.copy(self, m)
-- end

---@return falg.Mat4 self
function Mat4.new_identity()
  return Mat4(1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1)
end

---@param r falg.Mat4|number
function Mat4:__mul(r)
  local m = Mat4()
  m._11 = self._11 * r._11
    + self._12 * r._21
    + self._13 * r._31
    + self._14 * r._41
  m._12 = self._11 * r._12
    + self._12 * r._22
    + self._13 * r._32
    + self._14 * r._42
  m._13 = self._11 * r._13
    + self._12 * r._23
    + self._13 * r._33
    + self._14 * r._43
  m._14 = self._11 * r._14
    + self._12 * r._24
    + self._13 * r._34
    + self._14 * r._44

  m._21 = self._21 * r._11
    + self._22 * r._21
    + self._23 * r._31
    + self._24 * r._41
  m._22 = self._21 * r._12
    + self._22 * r._22
    + self._23 * r._32
    + self._24 * r._42
  m._23 = self._21 * r._13
    + self._22 * r._23
    + self._23 * r._33
    + self._24 * r._43
  m._24 = self._21 * r._14
    + self._22 * r._24
    + self._23 * r._34
    + self._24 * r._44

  m._31 = self._31 * r._11
    + self._32 * r._21
    + self._33 * r._31
    + self._34 * r._41
  m._32 = self._31 * r._12
    + self._32 * r._22
    + self._33 * r._32
    + self._34 * r._42
  m._33 = self._31 * r._13
    + self._32 * r._23
    + self._33 * r._33
    + self._34 * r._43
  m._34 = self._31 * r._14
    + self._32 * r._24
    + self._33 * r._34
    + self._34 * r._44

  m._41 = self._41 * r._11
    + self._42 * r._21
    + self._43 * r._31
    + self._44 * r._41
  m._42 = self._41 * r._12
    + self._42 * r._22
    + self._43 * r._32
    + self._44 * r._42
  m._43 = self._41 * r._13
    + self._42 * r._23
    + self._43 * r._33
    + self._44 * r._43
  m._44 = self._41 * r._14
    + self._42 * r._24
    + self._43 * r._34
    + self._44 * r._44
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
  self._11 = 2 * n / (r - l)
  self._22 = 2 * n / (t - b)

  self._31 = (r + l) / (r - l)
  self._32 = (t + b) / (t - b)
  self._33 = -(f + n) / (f - n)
  self._34 = -1

  self._43 = -2 * f * n / (f - n)
  ---@type falg.Mat4
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
function Mat4.new_translation(x, y, z)
  return Mat4(1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, x, y, z, 1)
end

---@param x number
---@param y number
---@param z number
---@param w number
---@return falg.Mat4 self
function Mat4.new_quat(x, y, z, w)
  return Mat4(
    1 - 2 * y * y - 2 * z * z,
    2 * x * y + 2 * w * z,
    2 * z * x - 2 * w * y,
    0,

    2 * x * y - 2 * w * z,
    1 - 2 * z * z - 2 * x * x,
    2 * y * z + 2 * w * x,
    0,

    2 * z * x + 2 * w * y,
    2 * y * z - 2 * w * x,
    1 - 2 * x * x - 2 * y * y,
    0,

    0,
    0,
    0,
    1
  )
end

---Update 3x3
---1
--- cS
--- sc
---@param rad number
---@return falg.Mat4 self
function Mat4.new_rotation_x(rad)
  local c = math.cos(rad)
  local s = math.sin(rad)
  return Mat4(1, 0, 0, 0, 0, c, -s, 0, 0, s, c, 0, 0, 0, 0, 1)
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
  self._11 = c
  self._22 = 1
  self._33 = c
  self._44 = 1
  self._13 = -s
  self._31 = s
  ---@type falg.Mat4
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
  self._11 = c
  self._22 = c
  self._33 = 1
  self._44 = 1
  self._21 = -s
  self._12 = s
  ---@type falg.Mat4
  return self
end

---@param forward falg.Float3
---@param up falg.Float3
---@return falg.Quat
function Mat4.from_forward_up(forward, up)
  local z = forward:normalized()
  local x = Float3.cross(up, z):normalized()
  local y = Float3.cross(z, x)
  return Mat4(x.X, x.Y, x.Z, 0, y.X, y.Y, y.Z, 0, z.X, z.Y, z.Z, 0, 0, 0, 0, 1)
end

---@return falg.Mat4
function Mat4:transpose()
  return Mat4(
    self._11,
    self._21,
    self._31,
    self._41,
    self._12,
    self._22,
    self._32,
    self._42,
    self._13,
    self._23,
    self._33,
    self._43,
    self._14,
    self._24,
    self._34,
    self._44
  )
end

---@return falg.Quat
function Mat4:to_quat()
  local elem = {
    self._11 - self._22 - self._33 + 1.0,
    -self._11 + self._22 - self._33 + 1.0,
    -self._11 - self._22 + self._33 + 1.0,
    self._11 + self._22 + self._33 + 1.0,
  }
  local biggestIndex = 1
  for i = 2, 4 do
    if elem[i] > elem[biggestIndex] then
      biggestIndex = i
    end
  end
  assert(elem[biggestIndex] >= 0.0)

  local v = math.sqrt(elem[biggestIndex]) * 0.5
  local mult = 0.25 / v
  if biggestIndex == 1 then
    return Quat(
      v,
      (self._12 + self._21) * mult,
      (self._31 + self._13) * mult,
      (self._23 - self._32) * mult
    )
  elseif biggestIndex == 2 then
    return Quat(
      (self._12 + self._21) * mult,
      v,
      (self._23 + self._32) * mult,
      (self._31 - self._13) * mult
    )
  elseif biggestIndex == 3 then
    return Quat(
      (self._31 + self._13) * mult,
      (self._23 + self._32) * mult,
      v,
      (self._12 - self._21) * mult
    )
  elseif biggestIndex == 4 then
    return Quat(
      (self._23 - self._32) * mult,
      (self._31 - self._13) * mult,
      (self._12 - self._21) * mult,
      v
    )
  else
    assert(false)
  end
end

---@param x number
---@param y number
---@param z number
---@return falg.Mat4
function Mat4.new_scale(x, y, z)
  return Mat4(x, 0, 0, 0, 0, y, 0, 0, 0, 0, z, 0, 0, 0, 0, 1)
end

---@param p falg.Float3
---@return falg.Float3
function Mat4:transform_position(p)
  local x = p.X * self._11 + p.Y * self._21 + p.Z * self._31 + self._41
  local y = p.X * self._12 + p.Y * self._22 + p.Z * self._32 + self._42
  local z = p.X * self._13 + p.Y * self._23 + p.Z * self._33 + self._43
  return Float3(x, y, z)
end

---@param row 1|2|3|4
---@return falg.Float3
function Mat4:row(row)
  if row == 1 then
    return Float3(self._11, self._12, self._13)
  elseif row == 2 then
    return Float3(self._21, self._22, self._23)
  elseif row == 3 then
    return Float3(self._31, self._32, self._33)
  elseif row == 4 then
    return Float3(self._41, self._42, self._43)
  end
  assert(false)
end

---@return falg.Float3 t
---@return falg.Quat r
---@return falg.Float3 s
function Mat4:decompose()
  local t = Float3(self._41, self._42, self._43)
  local rot = Mat4.from_forward_up(
    Float3(self._31, self._32, self._33),
    Float3(self._21, self._22, self._23)
  )
  local r = rot:to_quat()
  local s = Float3(
    Float3(self._11, self._12, self._13):norm(),
    Float3(self._21, self._22, self._23):norm(),
    Float3(self._31, self._32, self._33):norm()
  )
  return t, r, s
end

---@param p falg.Float3
---@return falg.Float3
function Mat4:apply_point(p)
  return Float3(
    p.X * self._11 + p.Y * self._21 + p.Z * self._31,
    p.X * self._12 + p.Y * self._22 + p.Z * self._32,
    p.X * self._13 + p.Y * self._23 + p.Z * self._33
  ) + Float3(self._41, self._42, self._43)
end

---@type falg.Mat4
Mat4 = ffi.metatype("Mat4", Mat4)

return Mat4
