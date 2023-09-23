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

---Allocate a love.ByteData for Mat4(float16)
---@return falg.Mat4
function Mat4.new()
  local size = ffi.sizeof "Mat4"
  assert(size, "no size for cdef Mat4")
  local data = love.data.newByteData(size)
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

return {
  Mat4 = Mat4,
}
