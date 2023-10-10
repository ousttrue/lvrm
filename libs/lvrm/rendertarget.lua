local Camera = require "lvrm.camera"

---@class RenderTarget: RenderTargetInstance
RenderTarget = {}
RenderTarget.__index = RenderTarget

---@return RenderTarget
function RenderTarget.new()
  ---@class RenderTargetInstance
  ---@field colorcanvas love.Canvas?
  ---@field depthcanvas love.Canvas?
  ---@field last_target lvrm.Scene|lvrm.Mesh|nil
  local instance = {
    camera = Camera.new(),
    width = 1,
    height = 1,
  }

  ---@type RenderTarget
  return setmetatable(instance, RenderTarget)
end

---@param w integer
---@param h integer
function RenderTarget:update_size(w, h)
  if
    not self.colorcanvas
    or self.colorcanvas:getWidth() ~= w
    or self.colorcanvas:getHeight() ~= h
  then
    self.colorcanvas = love.graphics.newCanvas(w, h)
    self.depthcanvas = love.graphics.newCanvas(w, h, { format = "depth24" })
    self.width = w
    self.height = h
  end
end

---@param render fun(view, projection)
---@param info {isActive: boolean, isHovered: boolean, target: lvrm.Scene|lvrm.Mesh|nil}
function RenderTarget:render(render, info)
  -- update camera
  self.camera:update(self.width, self.height, info.isActive, info.isHovered)
  if self.last_target ~= info.target then
    if info.target then
      self.camera:fit(info.target:get_bb())
    end
    self.last_target = info.target
  end

  love.graphics.setCanvas { self.colorcanvas, depthstencil = self.depthcanvas }
  do
    love.graphics.clear(0.4, 0.4, 0.4, 1)
    render(self.camera.view, self.camera.projection)
  end
  love.graphics.setCanvas()
end

return RenderTarget
