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

---@param name string
---@return integer width
---@return integer height
function M.BeginDockspace(name)
  local dockspace_flags = imgui.love.DockNodeFlags "PassthruCentralNode"

  local viewport = imgui.GetMainViewport()
  imgui.SetNextWindowPos(viewport.WorkPos)
  imgui.SetNextWindowSize(viewport.WorkSize)
  imgui.SetNextWindowViewport(viewport.ID)
  imgui.PushStyleVar_Float(imgui.ImGuiStyleVar_WindowRounding, 0)
  imgui.PushStyleVar_Float(imgui.ImGuiStyleVar_WindowBorderSize, 0)

  local window_flags = imgui.love.WindowFlags(
    "NoDocking",
    "NoTitleBar",
    "NoCollapse",
    "NoResize",
    "NoMove",
    "NoBringToFrontOnFocus",
    "NoNavFocus",
    "NoBackground",
    "MenuBar"
  )

  imgui.PushStyleVar_Vec2(imgui.ImGuiStyleVar_WindowPadding, { 0, 0 })
  imgui.Begin(name, nil, window_flags)
  imgui.PopStyleVar()
  imgui.PopStyleVar(2)

  local size = imgui.GetContentRegionAvail()

  local dockspace_id = imgui.GetID_Str(name)
  imgui.DockSpace(dockspace_id, { 0.0, 0.0 }, dockspace_flags)

  return size.x, size.y
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

---@param root table
function M.ShowJson(root)
  imgui.PushStyleVar_Vec2(imgui.ImGuiStyleVar_WindowPadding, { 0.0, 0.0 })
  imgui.Begin "glTF"
  imgui.PopStyleVar()

  show_table("glTFJsonTable", { "prop", "value" }, function()
    traverse_json("", nil, root)
  end)

  imgui.End()
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
  imgui.PushStyleVar_Vec2(imgui.ImGuiStyleVar_WindowPadding, { 0.0, 0.0 })
  imgui.Begin "scene"
  imgui.PopStyleVar()

  show_table("sceneTreeTable", { "name", "TRS", "mesh" }, function()
    for _, n in ipairs(scene.root_nodes) do
      traverse_node(n)
    end
  end)

  imgui.End()
end

---@param root gltf.Root
---@param gltf_mesh gltf.Mesh
---@param n integer
local function show_prim(root, gltf_mesh, n)
  imgui.TableNextRow()
  imgui.TableNextColumn()
  local flags = make_node_flags { is_leaf = true }
  local prim = gltf_mesh.primitives[n]
  local material_name = "__no_material__"
  if prim.material then
    material_name = root.materials[prim.material + 1].name
    if not material_name then
      material_name = "__no_material_name__"
    end
  end
  local node_open = imgui.TreeNodeEx_StrStr(string.format("%d", n), flags, "%02d:%s", n, material_name)

  imgui.TableNextColumn()
  local position_accessor = root.accessors[prim.attributes.POSITION + 1]
  imgui.TextUnformatted(string.format("%d", position_accessor.count))

  imgui.TableNextColumn()
  -- imgui.TextUnformatted(string.format())

  imgui.TableNextColumn()
  -- imgui.TextUnformatted(string.format())

  if node_open then
    imgui.TreePop()
  end
end

---@param root gltf.Root
---@param gltf_mesh gltf.Mesh
---@param mesh lvrm.Mesh
local function show_mesh(root, gltf_mesh, mesh)
  imgui.TableNextRow()
  imgui.TableNextColumn()
  local flags = make_node_flags { is_leaf = false }
  imgui.SetNextItemOpen(true, imgui.ImGuiCond_FirstUseEver)
  local node_open = imgui.TreeNodeEx_Ptr(mesh.id, flags, "%s", gltf_mesh.name or "__no_name__")

  if node_open then
    for i, _ in ipairs(gltf_mesh.primitives) do
      show_prim(root, gltf_mesh, i)
    end

    imgui.TreePop()
  end
end

---@param root gltf.Root
---@param scene lvrm.Scene
function M.ShowMesh(root, scene)
  imgui.PushStyleVar_Vec2(imgui.ImGuiStyleVar_WindowPadding, { 0.0, 0.0 })
  imgui.Begin "mesh"
  imgui.PopStyleVar()

  show_table("sceneTreeTable", { "name", "vertices", "indices", "morph" }, function()
    for i, m in ipairs(root.meshes) do
      show_mesh(root, m, scene.meshes[i])
    end
  end)

  imgui.End()
end

return M
