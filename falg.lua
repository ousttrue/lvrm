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

---@return falg.Mat4
function Mat4.new_identity()
  local m = Mat4.new()
  m:set_array {
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
  return m
end

---@param array number[] Must 16 values
function Mat4:set_array(array)
  assert(#array == 16)
  local p = ffi.cast("Mat4*", self.data:getFFIPointer())[0] -- ffi is 0 origin
  for i, v in ipairs(array) do
    p.array[i - 1] = v -- ffi is 0 origin
  end
end

return {
  Mat4 = Mat4,
}
