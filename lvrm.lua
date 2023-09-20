local M = {}

---@class Gltf
---@field bytes string
M.Gltf = {}
---@return string
function M.Gltf:tostring()
  return string.format("%d バイト", #self.bytes)
end

---@param bytes string
---@return Gltf?
function M.load_from_bytes(bytes)
  local instance = {
    bytes = bytes,
  }
  setmetatable(instance, {
    __index = M.Gltf,
  })
  return instance
end

---@param path string?
---@return Gltf?
function M.load_from_path(path)
  if not path then
    return
  end

  local r = io.open(path, "rb")
  if not r then
    return
  end

  local contents = r:read "*a"
  r:close()
  if not contents then
    return
  end

  return M.load_from_bytes(contents)
end

return M
