local M = {}

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
  ---@param self BytesReader
  ---@param bytes string
  ---@return BytesReader
  __call = function(self, bytes)
    return setmetatable({
      data = bytes,
      pos = 1,
    }, { __index = self })
  end,
})

---@class GltfReader
---@operator call: GltfReader
---@field root Gltf
---@field bin string? glb bin_chunk
M.GltfReader = {}
---@return string
function M.GltfReader:tostring()
  if self.bin then
    return "<glb>"
  else
    return "<gltf>"
  end
end

setmetatable(M.GltfReader, {
  ---@param self GltfReader
  ---@param json_chunk string
  ---@param bin_chunk string?
  ---@return GltfReader
  __call = function(self, json_chunk, bin_chunk)
    local json = require "json"
    local instance = {
      root = json.decode(json_chunk),
      bin = bin_chunk,
    }
    setmetatable(instance, { __index = self })
    return instance
  end,
})

local GLB_MAGIC = "glTF"
local GLB_VERSION = 2
local JSON_CHUNK_TYPE = "JSON"
local BIN_CHUNK_TYPE = "BIN\0"

--- https://registry.khronos.org/glTF/specs/2.0/glTF-2.0.html
---@param bytes string
---@return GltfReader?
function M.read_from_bytes(bytes)
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
    return M.GltfReader(json_chunk, bin_chunk)
  else
    -- gltf
    return M.GltfReader(bytes)
  end
end

return M