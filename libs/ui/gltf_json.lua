local bit = require "bit"
---@class cimgui
local imgui = require "cimgui"

local util = require "ui.util"

---@param jsonpath string
---@param prop string?
---@param node any
local function traverse_json(jsonpath, prop, node)
  local node_open = false
  local t = type(node)
  local is_leaf = t ~= "table"
  local flags = util.make_node_flags { is_leaf = is_leaf }
  if prop then
    imgui.TableNextRow()
    imgui.TableNextColumn()
    node_open = imgui.TreeNodeEx_StrStr(jsonpath, flags, "%s", prop)

    imgui.PushID_Str(jsonpath)
    imgui.TableNextColumn()
    if t == "nil" then
      imgui.TextUnformatted "nil"
    elseif t == "boolean" then
      if node then
        imgui.TextUnformatted "true"
      else
        imgui.TextUnformatted "false"
      end
    elseif t == "number" then
      imgui.Text("%f", node)
    elseif t == "string" then
      imgui.TextUnformatted('"' .. node .. '"')
    elseif t == "table" then
      if node[1] then
        -- array
        imgui.TextUnformatted(string.format("[%d]", #node))
      else
        -- dict
        local name = node.name
        if not name then
          name = node.type
        end
        if not name then
          name = node.bone
        end
        if not name then
          name = ""
        end

        imgui.TextUnformatted("{" .. name .. "}")
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
        local tmp = {}
        for child_prop, v in pairs(node) do
          table.insert(tmp, { child_prop, v })
        end
        table.sort(tmp, function(a, b)
          return a[1] < b[1]
        end)
        for _, kv in ipairs(tmp) do
          local child_jsonpath = jsonpath .. "." .. kv[1]
          traverse_json(child_jsonpath, kv[1], kv[2])
        end
      end
    end
  end

  if node_open then
    imgui.TreePop()
  end
end

---@param root gltf.Root?
function ShowJson(root)
  if not root then
    return
  end
  util.show_table("glTFJsonTable", { "prop", "value" }, function()
    traverse_json("", nil, root)
  end)
end

return ShowJson
