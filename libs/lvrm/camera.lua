---@class cimgui
local imgui = require "cimgui"

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
    view = falg.Mat4.new_identity(),
    -- projection
    screen_width = 100,
    screen_height = 100,
    fovy = 30 / 180 * math.pi,
    znear = 0.01,
    zfar = 100,
    projection = falg.Mat4.new_identity(),
  }, Camera)
  camera:calc_matrix()
  return camera
end

function Camera:calc_matrix()
  local yaw = falg.Mat4():rotation_y(self.yaw)
  local pitch = falg.Mat4():rotation_x(self.pitch)
  self.view = yaw * pitch
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

---@param width number
---@param height number
---@param isActive boolean
---@param isHovered boolean
function Camera:update(width, height, isActive, isHovered)
  local io = imgui.GetIO()
  if isActive then
    if io.MouseDown[imgui.ImGuiMouseButton_Right] then
      self:yawpitch(io.MouseDelta.x, io.MouseDelta.y)
    end
    if io.MouseDown[imgui.ImGuiMouseButton_Middle] then
      self:shift(io.MouseDelta.x, io.MouseDelta.y)
    end
  end

  -- local io = imgui.GetIO()
  -- local is_ctrl = imgui.IsKeyDown_Nil(imgui.ImGuiKey_LeftCtrl) or imgui.IsKeyDown_Nil(imgui.ImGuiKey_RightCtrl)
  -- if io.MouseDown[imgui.ImGuiMouseButton_Right] then
  --   -- if is_ctrl then
  --   --   STATE.camera:dolly(-io.MouseDelta.y)
  --   -- else
  --   --   STATE.camera:yawpitch(io.MouseDelta.x, io.MouseDelta.y)
  --   -- end
  -- end
  -- if io.MouseDown[imgui.ImGuiMouseButton_Middle] then
  --   -- if is_ctrl then
  --   --   STATE.camera:dolly(-io.MouseDelta.y)
  --   -- else
  --   --   STATE.camera:shift(io.MouseDelta.x, io.MouseDelta.y)
  --   -- end
  -- end

  if isHovered then
    self:dolly(io.MouseWheel)
  end
  self.screen_width = width
  self.screen_height = height
  self:calc_matrix()
end

return Camera
