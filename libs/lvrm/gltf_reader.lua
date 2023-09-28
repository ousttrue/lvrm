local ffi = require "ffi"

local GLB_MAGIC = "glTF"
local GLB_VERSION = 2
local JSON_CHUNK_TYPE = "JSON"
local BIN_CHUNK_TYPE = "BIN\0"

---@type lvrm.BytesReader
local BytesReader = require "lvrm.bytes_reader"

---@class GltfReader: GltfReaderInstance
local GltfReader = {}
GltfReader.__index = GltfReader

---@param json_chunk string
---@param bin_chunk string?
---@return GltfReader
function GltfReader.new(json_chunk, bin_chunk)
  -- shrink
  while json_chunk:sub(-1) == "\0" do
    json_chunk = json_chunk:sub(1, -2)
  end
  local json = require "json"
  local root = json.decode(json_chunk)

  ---@class GltfReaderInstance
  local instance = {
    ---@type gltf.Root
    root = root,
    ---@type string? glb bin_chunk
    bin = bin_chunk,
  }
  ---@type GltfReader
  return setmetatable(instance, GltfReader)
end

---@return string
function GltfReader:tostring()
  if self.bin then
    return "<glb>"
  else
    return "<gltf>"
  end
end

--- https://registry.khronos.org/glTF/specs/2.0/glTF-2.0.html
---@param bytes string
---@return GltfReader?
function GltfReader.read_from_bytes(bytes)
  local r = BytesReader.new(bytes)
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
    return GltfReader.new(json_chunk, bin_chunk)
  else
    -- gltf
    return GltfReader.new(bytes)
  end
end

local component_type_size_map = {
  [5120] = 1,
  [5121] = 1,
  [5122] = 2,
  [5123] = 2,
  [5125] = 4,
  [5126] = 4,
}

local type_count_map = {
  SCALAR = 1,
  VEC2 = 2,
  VEC3 = 3,
  VEC4 = 4,
  MAT2 = 4,
  MAT3 = 9,
  MAT4 = 16,
}

---@param accessor gltf.Accessor
---@return integer
local function get_item_size(accessor)
  return component_type_size_map[accessor.componentType] * type_count_map[accessor.type]
end

---@param bufferview_index integer 0 origin
---@return string
function GltfReader:read_bufferview_bytes(bufferview_index)
  local buffer_view = self.root.bufferViews[bufferview_index + 1] -- 1origin
  local buffer_view_offset = 0
  if buffer_view.byteOffset then
    buffer_view_offset = buffer_view.byteOffset
  end
  return self.bin:sub(buffer_view_offset + 1, buffer_view_offset + buffer_view.byteLength)
end

---@param image_index integer 0 origin
---@return string
function GltfReader:read_image_bytes(image_index)
  local image = self.root.images[image_index + 1] -- 1origin
  return self:read_bufferview_bytes(image.bufferView)
end

---@param accessor_index integer 0 origin
---@return ffi.cdata* pointer
---@return integer count
---@return integer stride
function GltfReader:read_accessor_bytes(accessor_index)
  local accessor = self.root.accessors[accessor_index + 1] -- 1origin
  local bufferview_bytes = self:read_bufferview_bytes(accessor.bufferView)

  local accessor_offset = 0
  if accessor.byteOffset then
    accessor_offset = accessor.byteOffset
  end
  local accessor_item_size = get_item_size(accessor)
  local accessor_length = accessor.count * accessor_item_size
  local accessor_bytes = bufferview_bytes:sub(accessor_offset + 1, accessor_offset + accessor_length)

  -- return accessor_bytes
  if accessor.componentType == 5123 then
    -- short
    assert(accessor.type == "SCALAR")
    return ffi.cast("unsigned short*", accessor_bytes), accessor.count, accessor_item_size
  elseif accessor.componentType == 5125 then
    -- int
    assert(accessor.type == "SCALAR")
    return ffi.cast("unsigned int*", accessor_bytes), accessor.count, accessor_item_size
  elseif accessor.componentType == 5126 then
    if accessor.type == "VEC2" then
      return ffi.cast("Float2*", accessor_bytes), accessor.count, accessor_item_size
    elseif accessor.type == "VEC3" then
      return ffi.cast("Float3*", accessor_bytes), accessor.count, accessor_item_size
    else
      assert(false, "unknown type", accessor.componentType, accessor.type)
    end
  else
    assert(false, "unknown type", accessor.componentType)
  end
end

return GltfReader
