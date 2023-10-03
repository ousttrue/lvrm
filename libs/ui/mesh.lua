local bit = require "bit"
---@class cimgui
local imgui = require "cimgui"

local util = require "ui.util"

---@param root gltf.Root
---@param gltf_mesh gltf.Mesh
---@param n integer
local function show_prim(root, gltf_mesh, n)
  imgui.TableNextRow()
  -- name
  imgui.TableNextColumn()
  local flags = util.make_node_flags { is_leaf = true }
  local gltf_prim = gltf_mesh.primitives[n]
  local material_name = "__no_material__"
  if gltf_prim.material then
    material_name = root.materials[gltf_prim.material + 1].name
    if not material_name then
      material_name = "__no_material_name__"
    end
  end
  local node_open = imgui.TreeNodeEx_StrStr(string.format("%d", n), flags, string.format("%02d:%s", n, material_name))

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
---@param gltf_mesh gltf.Mesh
---@param mesh lvrm.Mesh
local function show_mesh(root, gltf_mesh, mesh)
  imgui.TableNextRow()
  -- name
  imgui.TableNextColumn()
  local flags = util.make_node_flags { is_leaf = false }
  imgui.SetNextItemOpen(true, imgui.ImGuiCond_FirstUseEver)
  local node_open = imgui.TreeNodeEx_Ptr(mesh.id, flags, "%s", gltf_mesh.name or "__no_name__")

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
    for i, _ in ipairs(gltf_mesh.primitives) do
      show_prim(root, gltf_mesh, i)
    end

    imgui.TreePop()
  end
end

---@param root gltf.Root?
---@param scene lvrm.Scene?
function ShowMesh(root, scene)
  if not root or not scene then
    return
  end
  util.show_table("sceneTreeTable", { "mesh/maerial name", "vertices", "indices", "morph" }, function()
    for i, m in ipairs(root.meshes) do
      show_mesh(root, m, scene.meshes[i])
    end
  end)
end

return ShowMesh
