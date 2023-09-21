local M = {}

local json = require "json"

---@class BytesReader
---@operator call: BytesReader
---@field data string
---@field pos integer
local BytesReader = {}

---@param length integer
---@return string
function BytesReader:read(length)
  local value = self.data:sub(self.pos, self.pos + length - 1)
  self.pos = self.pos + length
  return value
end

---@return integer
function BytesReader:uint32()
  local value = love.data.unpack("I", self:read(4))
  ---@cast value integer
  return value
end

setmetatable(BytesReader, {
  ---@param bytes string
  ---@return BytesReader
  __call = function(self, bytes)
    local instance = {
      data = bytes,
      pos = 1,
    }
    setmetatable(instance, { __index = BytesReader })
    return instance
  end,
})

---@class Gltf
---@operator call: Gltf
---@field root table
---@field bin string? glb bin_chunk
M.Gltf = {}
---@return string
function M.Gltf:tostring()
  if self.bin then
    return string.format "<glb>"
  else
    return string.format "<gltf>"
  end
end

setmetatable(M.Gltf, {
  ---@param json_chunk string
  ---@param bin_chunk string?
  __call = function(self, json_chunk, bin_chunk)
    local instance = {
      root = json.decode(json_chunk),
      bin = bin_chunk,
    }
    setmetatable(instance, { __index = M.Gltf })
    return instance
  end,
})

local GLB_MAGIC = "glTF"
local GLB_VERSION = 2
local JSON_CHUNK_TYPE = "JSON"
local BIN_CHUNK_TYPE = "BIN\0"

--- https://registry.khronos.org/glTF/specs/2.0/glTF-2.0.html
---@param bytes string
---@return Gltf?
function M.load_from_bytes(bytes)
  local r = BytesReader(bytes)
  if r:read(4) == GLB_MAGIC then
    -- glb
    local version = r:uint32()
    if version ~= GLB_VERSION then
      return
    end
    local length = r:uint32()

    local json_chunk = ""
    local bin_chunk = ""

    while r.pos <= length do
      local chunk_length = r:uint32()
      local chunk_type = r:read(4)
      if chunk_type == JSON_CHUNK_TYPE then
        json_chunk = r:read(chunk_length)
      elseif chunk_type == BIN_CHUNK_TYPE then
        bin_chunk = r:read(chunk_length)
      else
        assert(false, "unknown chunk_type: ", chunk_type)
      end
    end
    return M.Gltf(json_chunk, bin_chunk)
  else
    -- gltf
    return M.Gltf(bytes)
  end
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
