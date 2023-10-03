local bit = require "bit"
---@class cimgui
local imgui = require "cimgui"

local M = {
  ShowMesh = require "ui.mesh",
  ShowJson = require "ui.gltf_json",
  ShowScene = require "ui.scene",
  ShowAnimation = require "ui.animation",
}

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

return M
