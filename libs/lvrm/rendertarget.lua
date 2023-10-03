---@class RenderTarget: RenderTargetInstance
RenderTarget = {}
RenderTarget.__index = RenderTarget

---@return RenderTarget
function RenderTarget.new()
  ---@class RenderTargetInstance
  ---@field colorcanvas love.Canvas?
  ---@field depthcanvas love.Canvas?
  local instance = {}

  ---@type RenderTarget
  return setmetatable(instance, RenderTarget)
end

---@param w integer
---@param h integer
function RenderTarget:update_size(w, h)
  if not self.colorcanvas or self.colorcanvas:getWidth() ~= w or self.colorcanvas:getHeight() ~= h then
    self.colorcanvas = love.graphics.newCanvas(w, h)
    self.depthcanvas = love.graphics.newCanvas(w, h, { format = "depth24" })
  end
end

---@param callback function
function RenderTarget:render(callback)
  love.graphics.setCanvas { self.colorcanvas, depthstencil = self.depthcanvas }
  love.graphics.clear(0,0,0,1)
  callback()
  love.graphics.setCanvas()
end

return RenderTarget
