local Mesh = require "lvrm.mesh"
local falg  = require 'falg'
local IDENTITY = falg.Mat4.new_identity()

---@class lvrm.Camera
---@field view ffi.cdata*
---@field projection ffi.cdata*
local Camera = {}

function Camera.new()
  return {

  }
end

---@class lvrm.SceneInstance
---@field meshes lvrm.Mesh[]
---@field camera lvrm.Camera

---@class lvrm.Scene: lvrm.SceneInstance
local Scene = {}
---@return lvrm.Scene
function Scene.new()
  local instance = {
    camera = Camera.new(),
    meshes = {
      Mesh:new(),
    },
  }  
    return setmetatable(instance, { __index = Scene })
end


---@param reader GltfReader
---@return lvrm.Scene
function Scene.Load(reader)
  return Scene.new() 
end


function Scene:draw() 
  love.graphics.push "all"
  for _, m in ipairs(self.meshes) do
    -- shader:send("m_view", 'column', camera.m_view.data)
    -- shader:send("m_projection", 'column', temp_projection_m.data)  
    m:draw(IDENTITY.data, IDENTITY.data, IDENTITY.data)
  end
  love.graphics.pop()
end


return Scene
