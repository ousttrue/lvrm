local bit = require "bit"
local ffi = require "ffi"
---@class cimgui
local imgui = require "cimgui"

local util = require "ui.util"

---@class MeshGui: MeshGuiInstance
local MeshGui = {}
MeshGui.__index = MeshGui

---@return MeshGui
function MeshGui.new()
  ---@class MeshGuiInstance
  ---@field mesh integer? selected
  ---@field prim integer? selected
  local instance = {
    splitter = util.Splitter.new(),
  }
  ---@type MeshGui
  return setmetatable(instance, MeshGui)
end

---@param root gltf.Root
---@param m integer mesh
---@param n integer prim
function MeshGui:show_prim(root, m, n)
  local gltf_mesh = root.meshes[m]

  imgui.TableNextRow()
  -- name
  imgui.TableNextColumn()
  local flags = util.make_node_flags { is_leaf = true, is_selected = (m == self.mesh and n == self.prim) }
  local gltf_prim = gltf_mesh.primitives[n]
  local material_name = "__no_material__"
  if gltf_prim.material then
    material_name = root.materials[gltf_prim.material + 1].name
    if not material_name then
      material_name = "__no_material_name__"
    end
  end
  local node_open =
    imgui.TreeNodeEx_StrStr(string.format("##__prim__%d", n), flags, string.format("%02d:%s", n, material_name))
  if imgui.IsItemClicked() and not imgui.IsItemToggledOpen() then
    self.mesh = m
    self.prim = n
  end

  -- vertices
  imgui.TableNextColumn()
  local position_accessor = root.accessors[gltf_prim.attributes.POSITION + 1]
  imgui.TextUnformatted(string.format("%d", position_accessor.count))

  -- indices
  imgui.TableNextColumn()
  local index_accessor = root.accessors[gltf_prim.indices + 1]
  imgui.TextUnformatted(string.format("%d", index_accessor.count))

  -- morph
  imgui.TableNextColumn()
  if gltf_prim.targets then
    imgui.TextUnformatted(string.format("%d", #gltf_prim.targets))
  end

  if node_open then
    imgui.TreePop()
  end
end

---@param root gltf.Root
---@param m integer number
---@param mesh lvrm.Mesh
function MeshGui:show_mesh(root, m, mesh)
  local gltf_mesh = root.meshes[m]

  imgui.TableNextRow()
  -- name
  imgui.TableNextColumn()
  local flags = util.make_node_flags { is_leaf = false, is_selected = (m == self.mesh and self.prim == nil) }
  imgui.SetNextItemOpen(true, imgui.ImGuiCond_FirstUseEver)
  local node_open = imgui.TreeNodeEx_Ptr(mesh.id, flags, "%s", gltf_mesh.name or "__no_name__")
  local new_select = false
  if imgui.IsItemClicked() and not imgui.IsItemToggledOpen() then
    self.mesh = m
    self.prim = nil
  end

  -- vertices
  imgui.TableNextColumn()
  imgui.TextUnformatted(string.format("%d", mesh.vertex_buffer:getVertexCount()))

  -- indices
  imgui.TableNextColumn()
  local drawcount = 0
  for _, submesh in ipairs(mesh.submeshes) do
    drawcount = drawcount + submesh.drawcount
  end
  imgui.TextUnformatted(string.format("%d", drawcount))

  if node_open then
    for n = 1, #gltf_mesh.primitives do
      self:show_prim(root, m, n)
    end

    imgui.TreePop()
  end
end

---@param root gltf.Root?
---@param scene lvrm.Scene?
function MeshGui:ShowMesh(root, scene)
  if not root or not scene then
    return
  end
  util.show_table("sceneTreeTable", { "mesh/maerial name", "vertices", "indices", "morph" }, function()
    for m, mesh in ipairs(scene.meshes) do
      self:show_mesh(root, m, mesh)
    end
  end)
end

---@param scene lvrm.Scene
function MeshGui:show_morph_targets(scene)
  if not self.mesh then
    return
  end

  local mesh = scene.meshes[self.mesh]
  if not mesh then
    return
  end

  if self.prim then
    imgui.TextUnformatted(string.format("%s:%d", mesh.name, self.prim))
  else
    imgui.TextUnformatted(string.format("%s", mesh.name))
  end

  local submesh = mesh.submeshes[1]
  if not submesh then
    return
  end

  -- for i, m in ipairs(submesh.morph) do
  -- end
end

---@param scene lvrm.Scene
function MeshGui:render_selected(scene)
  --
end

---@param scene lvrm.Scene
function MeshGui:ShowSelected(scene)
  if not scene then
    return
  end
  local size = imgui.GetContentRegionAvail()
  local sz1, sz2 = self.splitter:SplitHorizontal { size.x, size.y }

  imgui.BeginChild_Str("1", ffi.new("ImVec2", -1, sz1), true)
  self:show_morph_targets(scene)
  imgui.EndChild()
  -- imgui.SameLine()
  imgui.BeginChild_Str("2", ffi.new("ImVec2", -1, sz2), true)
  self:render_selected(scene)
  imgui.EndChild()
end

return MeshGui
