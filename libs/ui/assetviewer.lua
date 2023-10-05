---@class LuaFileSystem
local lfs = require "lfs"
---@class cimgui
local imgui = require "cimgui"
local util = require "ui.util"

local function basename(path)
  local m = string.match(path, "/[^/]*$")
  if m then
    return m:sub(2)
  end
  return path
end

---
--- Path
---
---@class Path: PathInstance
local Path = {}
Path.__index = Path

---@param path string
function Path.new(path)
  ---@class PathInstance
  ---@field children Path[]?
  local instance = {
    path = path,
    name = basename(path),
    ---@type 'file'|'directory'|'link'|'socket'|'char device'|"block device"|"named pipe"
    mode = lfs.attributes(path, "mode"),
  }
  ---@type Path
  return setmetatable(instance, Path)
end

function Path:add_child(child)
  if not self.children then
    self.children = {}
  end
  table.insert(self.children, child)
end

---@return Path[]
local function traverse(path)
  local p = Path.new(path)
  if p.mode == "directory" then
    for e in lfs.dir(path) do
      if e ~= "." and e ~= ".." then
        local child = traverse(path .. "/" .. e)
        p:add_child(child)
      end
    end
  end
  return p
end

---
--- AssetViewer
---
---@class AssetViewer: AssetViewerInstance
local AssetViewer = {}
AssetViewer.__index = AssetViewer

---@param path string
---@retun AssetViewer
function AssetViewer.new(path)
  ---@class AssetViewerInstance
  local instance = {
    root = traverse(path:gsub("\\", '/')),
  }
  ---@type AssetViewer
  return setmetatable(instance, AssetViewer)
end

---@param path Path
function AssetViewer:show_path(path)
  imgui.TableNextRow()

  -- name
  imgui.TableNextColumn()
  local flags = util.make_node_flags { is_leaf = path.mode ~= "directory" }
  local node_open = imgui.TreeNodeEx_StrStr(path.path, flags, "%s", path.name)

  -- mode
  imgui.TableNextColumn()
  imgui.TextUnformatted(path.mode)

  if node_open then
    if path.children then
      for _, child in ipairs(path.children) do
        self:show_path(child)
      end
    end
    imgui.TreePop()
  end
end

function AssetViewer:Show()
  imgui.TextUnformatted(self.root.path)

  util.show_table("assetTable", { "name", "mode" }, function()
    for i, child in ipairs(self.root.children) do
      self:show_path(child)
    end
  end)
end

return AssetViewer
