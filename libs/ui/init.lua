local bit = require "bit"
---@class cimgui
local imgui = require "cimgui"

local M = {}

local TABLE_FLAGS =
  imgui.love.TableFlags("Resizable", "RowBg", "Borders", "NoBordersInBody", "ScrollX", "ScrollY", "SizingFixedFit")

---@param name string
---@param cols string[]
---@param body function
local function show_table(name, cols, body)
  if imgui.BeginTable(name, #cols, TABLE_FLAGS) then
    for _, col in ipairs(cols) do
      imgui.TableSetupColumn(col)
    end
    imgui.TableSetupScrollFreeze(0, 1)
    imgui.TableHeadersRow()
    imgui.PushStyleVar_Float(imgui.ImGuiStyleVar_IndentSpacing, 12)

    body()

    imgui.PopStyleVar()
    imgui.EndTable()
  end
end

---@param opts {is_leaf: boolean, is_selected: boolean}?
local function make_node_flags(opts)
  local node_flags = imgui.love.TreeNodeFlags("OpenOnArrow", "OpenOnDoubleClick", "SpanAvailWidth")
  if opts and opts.is_leaf then
    node_flags = bit.bor(node_flags, imgui.love.TreeNodeFlags "Leaf")
  end
  if opts and opts.is_selected then
    node_flags = bit.bor(node_flags, imgui.love.TreeNodeFlags "Selected")
  end
  return node_flags
end

---@param jsonpath string
---@param prop string?
---@param node any
local function traverse_json(jsonpath, prop, node)
  local node_open = false
  local t = type(node)
  local is_leaf = t ~= "table"
  local flags = make_node_flags { is_leaf = is_leaf }
  if prop then
    imgui.TableNextRow()
    imgui.TableNextColumn()
    node_open = imgui.TreeNodeEx_StrStr(jsonpath, flags, "%s", prop)

    imgui.PushID_Str(jsonpath)
    imgui.TableNextColumn()
    if t == "nil" then
      imgui.TextUnformatted "nil"
    elseif t == "boolean" then
      imgui.Checkbox("", node)
    elseif t == "number" then
      imgui.Text("%f", node)
    elseif t == "string" then
      imgui.TextUnformatted(node)
    elseif t == "table" then
      if node[1] then
        -- array
        imgui.TextUnformatted(string.format("[%d]", #node))
      else
        -- dict
        imgui.TextUnformatted "{}"
      end
    end
    imgui.PopID()
  end

  if prop == nil or node_open then
    if t == "table" then
      if node[1] then
        -- array
        for i, v in ipairs(node) do
          local child_prop = string.format("%d", i)
          local child_jsonpath = jsonpath .. "." .. child_prop
          traverse_json(child_jsonpath, child_prop, v)
        end
      else
        -- dict
        for child_prop, v in pairs(node) do
          local child_jsonpath = jsonpath .. "." .. child_prop
          traverse_json(child_jsonpath, child_prop, v)
        end
      end
    end
  end

  if node_open then
    imgui.TreePop()
  end
end

---@param root gltf.Root?
function M.ShowJson(root)
  if not root then
    return
  end
  show_table("glTFJsonTable", { "prop", "value" }, function()
    traverse_json("", nil, root)
  end)
end

---@param node lvrm.Node
local function traverse_node(node)
  imgui.TableNextRow()
  imgui.TableNextColumn()
  local flags = make_node_flags { is_leaf = #node.children == 0 }
  local node_open = imgui.TreeNodeEx_Ptr(node.id, flags, "%s", node.name)

  imgui.TableNextColumn()

  imgui.TableNextColumn()
  if node.mesh then
    imgui.TextUnformatted(string.format("%d", #node.mesh.submeshes))
  end

  if node_open then
    for _, child in ipairs(node.children) do
      traverse_node(child)
    end

    imgui.TreePop()
  end
end

---@param scene lvrm.Scene
function M.ShowScene(scene)
  if not scene then
    return
  end
  show_table("sceneTreeTable", { "name", "TRS", "mesh" }, function()
    for _, n in ipairs(scene.root_nodes) do
      traverse_node(n)
    end
  end)
end

---@param root gltf.Root
---@param gltf_mesh gltf.Mesh
---@param n integer
local function show_prim(root, gltf_mesh, n)
  imgui.TableNextRow()
  -- name
  imgui.TableNextColumn()
  local flags = make_node_flags { is_leaf = true }
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
  local flags = make_node_flags { is_leaf = false }
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
function M.ShowMesh(root, scene)
  if not root or not scene then
    return
  end
  show_table("sceneTreeTable", { "mesh/maerial name", "vertices", "indices", "morph" }, function()
    for i, m in ipairs(root.meshes) do
      show_mesh(root, m, scene.meshes[i])
    end
  end)
end

---@param n integer
---@param curve lvrm.AnimationCurve
local function show_animation_curve(n, curve)
  imgui.TableNextRow()
  imgui.TableNextColumn()
  imgui.TextUnformatted(string.format("%d", n))

  imgui.TableNextColumn()
end

---@param n integer
---@param animation lvrm.Animation
local function show_animation(n, animation)
  imgui.TableNextRow()
  imgui.TableNextColumn()
  local flags = make_node_flags { is_leaf = false }
  imgui.SetNextItemOpen(true, imgui.ImGuiCond_FirstUseEver)
  local node_open = imgui.TreeNodeEx_Ptr(animation.id, flags, string.format("%d", n))

  if node_open then
    for i, c in ipairs(animation.curves) do
      show_animation_curve(i, c)
    end

    imgui.TreePop()
  end
end

---@param scene lvrm.Scene?
function M.ShowAnimation(scene)
  if not scene then
    return
  end
  show_table("sceneAnimationTable", { "num", "name", "duration" }, function()
    for i, a in ipairs(scene.animations) do
      show_animation(i, a)
    end
  end)
end

--- image button. capture mouse event
---@param id string
---@param texture love.Texture
---@param size falg.Float2
function M.DraggableImage(id, texture, size)
  imgui.ImageButton(id, texture, size, { 0, 1 }, { 1, 0 }, { 1, 1, 1, 1 }, { 1, 1, 1, 1 })
  imgui.ButtonBehavior(
    imgui.GetCurrentContext().LastItemData.Rect,
    imgui.GetCurrentContext().LastItemData.ID,
    bit.bor(imgui.ImGuiButtonFlags_MouseButtonMiddle, imgui.ImGuiButtonFlags_MouseButtonRight)
  )

  return imgui.IsItemActive(), imgui.IsItemHovered()
end

---@class CanvasRenderer: CanvasRendererInstance
CanvasRenderer = {}
CanvasRenderer.__index = CanvasRenderer

---@return CanvasRenderer
function CanvasRenderer.new()
  ---@class CanvasRendererInstance
  ---@field canvas love.Canvas?
  local instance = {}

  ---@type CanvasRenderer
  return setmetatable(instance, CanvasRenderer)
end

---@param w integer
---@param h integer
---@return love.Canvas
function CanvasRenderer:render(w, h)
  if not self.canvas or self.canvas:getWidth() ~= w or self.canvas:getHeight() ~= h then
    self.canvas = love.graphics.newCanvas(w, h)
  end
  return self.canvas
end

M.CanvasRenderer = CanvasRenderer

return M
