local ffi = require "ffi"

local Material = require "lvrm.material"

---@class lvrm.SubMesh
---@field start integer
---@field drawcount integer
---@field material lvrm.Material

---@class lvrm.MeshInstance
---@field vertex_buffer love.Mesh
---@field submeshes lvrm.SubMesh[]
local Submesh = {}

---@param material lvrm.Material
---@param start integer
---@param drawcount integer
function Submesh.new(material, start, drawcount)
  return {
    material = material,
    start = start,
    drawcount = drawcount,
  }
end

---@class lvrm.Mesh: lvrm.MeshInstance
local Mesh = {}

function Mesh.new()
  local vertexformat = {
    { "VertexPosition", "float", 3 },
    { "VertexTexCoord", "float", 2 },
    { "VertexNormal", "float", 3 },
  }
  local vertex_size = 8 * 4
  local data = love.data.newByteData(vertex_size * 3)

  ffi.cdef [[
    typedef struct Float2{
      float X, Y;
    } Float2;
    typedef struct Float3{
      float X, Y, Z;      
    } Float3;
    typedef struct Vertex{
      Float3 Position;
      Float2 TexCoord;
      Float3 Normal;
    } Vertex;
  ]]
  -- local buffer = ffi.new "Vertex[3]"
  local buffer = ffi.cast("Vertex*", data:getPointer())
  buffer[0].Position.X = -1
  buffer[0].Position.Y = -1
  buffer[1].Position.X = 1
  buffer[1].Position.Y = -1
  buffer[2].Position.X = 0
  buffer[2].Position.Y = 1

  local lg_mesh = love.graphics.newMesh(vertexformat, data, "triangles", "static")

  return setmetatable({
    vertex_buffer = lg_mesh,
    submeshes = {
      Submesh.new(Material.new(), 1, 3), -- 1 origin !
    },
  }, { __index = Mesh })
end

---@param model falg.Mat4
---@param view falg.Mat4
---@param projection falg.Mat4
function Mesh:draw(model, view, projection)
  for _, s in ipairs(self.submeshes) do
    s.material:use()
    s.material.shader:send("m_model", model.data, "column")
    s.material.shader:send("m_view", view.data, "column")
    s.material.shader:send("m_projection", projection.data, "column")
    self.vertex_buffer:setDrawRange(s.start, s.drawcount)
    love.graphics.draw(self.vertex_buffer)
  end
end

return Mesh
