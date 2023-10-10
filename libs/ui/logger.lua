---@class cimgui
local imgui = require "cimgui"

local logging = require "logging"
local util = require "ui.util"

---@class Message
---@field message string
local Message = {}

---@class Logger: LoggerInstance
local Logger = {}
Logger.__index = Logger

---@return Logger
function Logger.new()
  ---@class LoggerInstance
  local instance = {
    ---@type Message[]
    logs = {},
  }
  ---@type Logger
  return setmetatable(instance, Logger)
end

function Logger:show()
  util.show_table("loggerTable", { "severity", "time", "msg" }, function()
    for i, msg in ipairs(logging.logs) do
      imgui.TableNextRow()
      imgui.TableNextColumn()
      imgui.TextUnformatted(msg:severity_str())

      imgui.TableNextColumn()
      imgui.TextUnformatted(msg:time_str())

      imgui.TableNextColumn()
      imgui.TextUnformatted(msg.msg)
    end
  end)
end

return Logger
