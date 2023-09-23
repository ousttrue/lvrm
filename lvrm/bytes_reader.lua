---@class lvrm.BytesReader: lvrm.BytesReaderInstance
local BytesReader = {}
BytesReader.__index = BytesReader

---@param data string
---@return lvrm.BytesReader
function BytesReader.new(data)
  ---@class lvrm.BytesReaderInstance
  local instance = {
    ---@type string
    data = data,
    ---@type integer
    pos = 1,
  }
  ---@type lvrm.BytesReader
  return setmetatable(instance, BytesReader)
end

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

return BytesReader
