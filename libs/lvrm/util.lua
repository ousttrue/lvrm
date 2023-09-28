local M = {}

---@param path string?
---@return string?
function M.readfile(path)
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

---@param path string
---@return string
function M.basedir(path)
  path = path:gsub("\\", "/")
  local s, e = path:find "/[^/]+$"
  if s then
    return path:sub(1, s - 1)
  else
    return ""
  end
end

return M
