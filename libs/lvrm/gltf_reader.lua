local ffi = require "ffi"
local util = require "lvrm.util"

local GLB_MAGIC = "glTF"
local GLB_VERSION = 2
local JSON_CHUNK_TYPE = "JSON"
local BIN_CHUNK_TYPE = "BIN\0"

---@class Span: SpanInstance
local Span = {}
Span.__index = Span

---@param ptr ffi.cdata* T*
---@param len integer T count
---@return Span
function Span.new(ptr, len)
  ---@class SpanInstance
  local instance = {
    ptr = ptr,
    len = len,
  }
  ---@type Span
  return setmetatable(instance, Span)
end

---@param offset integer
---@param len integer
---@return Span
function Span:subspan(offset, len)
  return Span.new(self.ptr + offset, len)
end

---@param t string
---@param count integer
---@retun Span
function Span:cast(t, count)
  local ct = t .. "*"
  return Span.new(ffi.cast(ct, self.ptr), count)
end

---@type lvrm.BytesReader
local BytesReader = require "lvrm.bytes_reader"

---@class GltfReader: GltfReaderInstance
local GltfReader = {}
GltfReader.__index = GltfReader

---@param json_chunk string
---@param bin_chunk string | ffi.cdata* | nil
---@param base_dir string?
---@return GltfReader
function GltfReader.new(json_chunk, bin_chunk, base_dir)
  -- shrink
  while json_chunk:sub(-1) == "\0" do
    json_chunk = json_chunk:sub(1, -2)
  end
  local json = require "json"
  local root = json.decode(json_chunk)

  if type(bin_chunk) == "string" then
    local array_type = string.format("uint8_t[%d]", #bin_chunk)
    local buffer = ffi.new(array_type)
    ffi.copy(buffer, bin_chunk)
    bin_chunk = buffer
  end

  ---@class GltfReaderInstance
  local instance = {
    ---@type gltf.Root
    root = root,

    ---@type ffi.cdata*? uint8_t[N]
    bin = bin_chunk,

    base_dir = base_dir,

    ---@type {uri:string, bytes:string}
    uri_cache = {},
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
---@param base_dir string?
---@return GltfReader?
function GltfReader.read_from_bytes(bytes, base_dir)
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
    return GltfReader.new(json_chunk, bin_chunk, base_dir)
  else
    -- gltf
    return GltfReader.new(bytes, nil, base_dir)
  end
end

---@param path string
---@return GltfReader?
function GltfReader.read_from_path(path)
  local data = util.readfile(path)
  if data then
    return GltfReader.read_from_bytes(data, util.basedir(path))
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

---@param buffer_index integer 0 origin
---@return string | ffi.cdata*
function GltfReader:get_buffer(buffer_index)
  local buffer = self.root.buffers[buffer_index + 1]
  if buffer.uri then
    local cache = self.uri_cache[buffer.uri]
    if cache then
      return cache
    end

    local path = self.base_dir .. "/" .. buffer.uri
    local data = util.readfile(path)
    assert(data, path)
    self.uri_cache[buffer.uri] = data
    return data
  else
    assert(self.bin)
    return self.bin
  end
end

---@param bufferview_index integer 0 origin
---@return string | Span
function GltfReader:read_bufferview_bytes(bufferview_index)
  assert(bufferview_index)
  local buffer_view = self.root.bufferViews[bufferview_index + 1] -- 1origin
  local buffer_view_offset = 0
  if buffer_view.byteOffset then
    buffer_view_offset = buffer_view.byteOffset
  end
  assert(buffer_view_offset)

  local bin = self:get_buffer(buffer_view.buffer)

  if type(bin) == "string" then
    return bin:sub(buffer_view_offset + 1, buffer_view_offset + buffer_view.byteLength)
  else
    local span = Span.new(ffi.cast("uint8_t*", bin), ffi.sizeof(bin))
    return span:subspan(buffer_view_offset, buffer_view.byteLength)
  end
end

---@param image_index integer 0 origin
---@return string | Span
function GltfReader:read_image_bytes(image_index)
  local image = self.root.images[image_index + 1] -- 1origin
  return self:read_bufferview_bytes(image.bufferView)
end

---@param accessor_index integer 0 origin
---@return Span
function GltfReader:read_accessor_bytes(accessor_index)
  local accessor = self.root.accessors[accessor_index + 1] -- 1origin

  if accessor.sparse then
    assert(false, "sparse not impl")
  else
    ---@type Span
    local bufferview_bytes = self:read_bufferview_bytes(accessor.bufferView)

    local accessor_offset = 0
    if accessor.byteOffset then
      accessor_offset = accessor.byteOffset
    end
    assert(accessor_offset)
    local accessor_item_size = get_item_size(accessor)
    local accessor_length = accessor.count * accessor_item_size
    local accessor_bytes = bufferview_bytes:subspan(accessor_offset, accessor_length)

    -- return accessor_bytes
    if accessor.componentType == 5123 then
      -- short
      assert(accessor.type == "SCALAR")
      return accessor_bytes:cast("unsigned short", accessor.count)
    elseif accessor.componentType == 5125 then
      -- int
      assert(accessor.type == "SCALAR")
      return accessor_bytes:cast("unsigned int", accessor.count)
    elseif accessor.componentType == 5126 then
      -- float
      if accessor.type == "SCALAR" then
        return accessor_bytes:cast("float", accessor.count)
      elseif accessor.type == "VEC2" then
        return accessor_bytes:cast("Float2", accessor.count)
      elseif accessor.type == "VEC3" then
        return accessor_bytes:cast("Float3", accessor.count)
      elseif accessor.type == "VEC4" then
        return accessor_bytes:cast("Float4", accessor.count)
      else
        assert(false, "unknown type", accessor.componentType, accessor.type)
      end
    else
      assert(false, "unknown type", accessor.componentType)
    end
  end
end

return GltfReader
