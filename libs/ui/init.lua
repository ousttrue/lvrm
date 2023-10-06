local ffi = require "ffi"
local bit = require "bit"
---@class cimgui
local imgui = require "cimgui"

local M = {}

---
--- image button. capture mouse event
---
---@param id string
---@param texture love.Texture
---@param size falg.Float2
---@return boolean isActive
---@return boolean isHover
function M.DraggableImage(id, texture, size)
  -- imgui.PushStyleVar_Float(imgui.ImGuiStyleVar_FrameBorderSize, 0.0)
  imgui.PushStyleVar_Vec2(imgui.ImGuiStyleVar_FramePadding, { 0, 0 })
  imgui.ImageButton(id, texture, size, { 0, 1 }, { 1, 0 }, { 1, 1, 1, 1 }, { 1, 1, 1, 1 })
  imgui.PopStyleVar()
  imgui.ButtonBehavior(
    imgui.GetCurrentContext().LastItemData.Rect,
    imgui.GetCurrentContext().LastItemData.ID,
    bit.bor(imgui.ImGuiButtonFlags_MouseButtonMiddle, imgui.ImGuiButtonFlags_MouseButtonRight)
  )
  return imgui.IsItemActive(), imgui.IsItemHovered()
end

-- ?
local ImGuiFreeTypeBuilderFlags_LoadColor = bit.lshift(1, 8)

---@param i integer
---@param path string
---@param size integer font pixel height
---@param is_icon boolean
---@param range ffi.cdecl* ImWchar[b0,e0,b1,e1,...,0]
---@return any
function M.AddFont(i, path, size, is_icon, range)
  local io = imgui.GetIO()
  -- local config = ffi.new "ImFontConfig"
  local config = imgui.ImFontConfig()
  -- it's important to set this, or imgui.love.Shutdown() will crash
  -- trying to free already freed memory
  config.FontDataOwnedByAtlas = false

  config.SizePixels = size
  config.PixelSnapH = true
  config.OversampleH = 1
  config.OversampleV = 1
  -- config.FontBuilderFlags = bit.bor(config.FontBuilderFlags, Flags);
  if i > 0 then
    -- PLOG_INFO << "merge_font: " << (const char*)Path.u8string().c_str();
    config.MergeMode = true
  else
    -- PLOG_INFO << "add_font: " << (const char*)Path.u8string().c_str();
  end

  if is_icon then
    config.GlyphMinAdvanceX = config.SizePixels
    -- config.GlyphMaxAdvanceX = config.SizePixels;
    config.FontBuilderFlags = bit.bor(config.FontBuilderFlags, ImGuiFreeTypeBuilderFlags_LoadColor)
  end

  return io.Fonts:AddFontFromFileTTF(path, config.SizePixels, config, range)
end

return M
