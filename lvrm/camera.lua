local falg = require "falg"

---@class lvrm.Camera
---@field x number
---@field y number
---@field z number
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
    view = falg.Mat4.new():identity(),
    -- projection
    screen_width = 100,
    screen_height = 100,
    fovy = 30 / 180 * math.pi,
    znear = 0.1,
    zfar = 100,
    projection = falg.Mat4.new():identity(),
  }, Camera)
  camera:calc_matrix()
  return camera
end

function Camera:calc_matrix()
  self.view:translation(self.x, self.y, self.z)
  self.projection:perspective(self.fovy, self.screen_width / self.screen_height, self.znear, self.zfar)
end

---@param d number
function Camera:dolly(d)
  if d > 0 then
    self.z = self.z * 0.9
    self:calc_matrix()
  elseif d < 0 then
    self.z = self.z * 1.1
    self:calc_matrix()
  end
end

---@param dx integer mouse delta x
---@param dy integer mouse delta y
function Camera:shift(dx, dy)
  local t = math.tan(self.fovy / 2)
  self.x = self.x - (dx / self.screen_height / 2) * t * self.z
  self.y = self.y + (dy / self.screen_height / 2) * t * self.z
  self:calc_matrix()
end

return Camera
