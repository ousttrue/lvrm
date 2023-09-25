local falg = require "falg"

---@class lvrm.Camera
---@field x number
---@field y number
---@field z number
---@field yaw number
---@field pitch number
---@field view falg.Mat4
---@field screen_width integer
---@field screen_height integer
---@field fovy number
---@field znear number
---@field zfar number
---@field projection falg.Mat4
local Camera = {}
Camera.__index = Camera

---@return lvrm.Camera
function Camera.new()
  local camera = setmetatable({
    -- view
    x = 0,
    y = 0,
    z = -5,
    yaw = 0,
    pitch = 0,
    view = falg.Mat4():identity(),
    -- projection
    screen_width = 100,
    screen_height = 100,
    fovy = 30 / 180 * math.pi,
    znear = 0.1,
    zfar = 100,
    projection = falg.Mat4():identity(),
  }, Camera)
  camera:calc_matrix()
  return camera
end

function Camera:calc_matrix()
  -- self.view:identity()
  local yaw = falg.Mat4():rotation_y(self.yaw)
  local pitch = falg.Mat4():rotation_x(self.pitch)
  self.view = pitch * yaw
  self.view:translation(self.x, self.y, self.z)

  self.projection:perspective(self.fovy, self.screen_width / self.screen_height, self.znear, self.zfar)
end

---@param d number
function Camera:dolly(d)
  if d > 0 then
    self.z = self.z * 0.9
  elseif d < 0 then
    self.z = self.z * 1.1
  end
end

local FACTOR = 0.01

---@param dx integer mouse delta x
---@param dy integer mouse delta y
function Camera:yawpitch(dx, dy)
  self.yaw = self.yaw + dx * FACTOR
  self.pitch = self.pitch - dy * FACTOR
end

---@param dx integer mouse delta x
---@param dy integer mouse delta y
function Camera:shift(dx, dy)
  local t = math.tan(self.fovy)
  self.x = self.x - (dx / self.screen_height) * t * self.z * 2
  self.y = self.y + (dy / self.screen_height) * t * self.z * 2
end

return Camera
