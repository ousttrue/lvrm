local M = {
  ---@type table<string, love.Shader>
  caches = {},
}

---@param path string?
---@return string?
local function readfile(path)
  if not path then
    return
  end
  local r = io.open(path, "rb")
  if r then
    local data = r:read "*a"
    r:close()
    return data
  end
end

---@param name string
---@return love.Shader?
function M.get(name)
  local cache = M.caches[name]
  if cache then
    return cache
  end

  local vs_path = string.format("%s/shaders/%s.vs", love.filesystem.getSource(), name)
  local vs = readfile(vs_path)
  local fs_path = string.format("%s/shaders/%s.fs", love.filesystem.getSource(), name)
  local fs = readfile(fs_path)
  if vs and fs then
    local shader = love.graphics.newShader(vs, fs)
    M.caches[name] = shader
    return shader
  end
end

return M
