local M = {}

---
--- Severity
---
---@enum logging.Severity
M.Severity = {
  Debug = 0,
  Info = 1,
  Warning = 2,
  Error = 3,
}

---@type table<logging.Severity, string>
M.SeverityToString = {}
for k, v in pairs(M.Severity) do
  M.SeverityToString[v] = k
end

---
--- Message
---
---@class logging.Message: logging.MessageInstance
local Message = {}
Message.__index = Message

---@return logging.Message
function Message.new(severity, msg)
  ---@class logging.MessageInstance
  local instance = {
    severity = severity,
    msg = msg,
    time = os.time(),
  }
  ---@type logging.Message
  return setmetatable(instance, Message)
end

---@return string
function Message:severity_str()
  return M.SeverityToString[self.severity]
end

---@return string
function Message:time_str()
  return os.date("%X", self.time)
end

---@type logging.Message[]
M.logs = {}

---
--- push log
---
---@param severity logging.Severity
---@param fmt string
---@vararg any
function M.log(severity, fmt, ...)
  table.insert(M.logs, Message.new(severity, string.format(fmt, ...)))
end

---@param fmt string
---@vararg any
function M.debug(fmt, ...)
  M.log(M.Severity.Debug, fmt, ...)
end

---@param fmt string
---@vararg any
function M.info(fmt, ...)
  M.log(M.Severity.Info, fmt, ...)
end

---@param fmt string
---@vararg any
function M.warn(fmt, ...)
  M.log(M.Severity.Warning, fmt, ...)
end

---@param fmt string
---@vararg any
function M.error(fmt, ...)
  M.log(M.Severity.Error, fmt, ...)
end

return M
