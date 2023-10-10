---@class cimgui
local imgui = require "cimgui"
local util = require "ui.util"
local bit = require "bit"

---@class AnimationGui: AnimationGuiInstance
local AnimationGui = {}
AnimationGui.__index = AnimationGui

---@return AnimationGui
function AnimationGui.new()
  ---@class AnimationGuiInstance
  ---@field selected integer?
  local instance = {}
  ---@type AnimationGui
  return setmetatable(instance, AnimationGui)
end

---@param n integer
---@param curve lvrm.AnimationCurve
function AnimationGui:show_animation_curve(n, curve)
  imgui.TableNextRow()

  imgui.TableNextColumn()
  imgui.TextUnformatted(string.format("%d", n))

  imgui.TableNextColumn()
  imgui.TextUnformatted(curve.target.path)

  imgui.TableNextColumn()
  imgui.TextUnformatted(string.format("%f", curve.duration))
end

---@param n integer
---@param animation lvrm.Animation
function AnimationGui:show_animation(n, animation)
  imgui.TableNextRow()

  -- num
  imgui.TableNextColumn()
  local flags = util.make_node_flags { is_leaf = false, is_selected = n == self.selected }
  -- imgui.SetNextItemOpen(true, imgui.ImGuiCond_FirstUseEver)
  local node_open = imgui.TreeNodeEx_Ptr(animation.id, flags, string.format("%d", n))
  if imgui.IsItemClicked() and not imgui.IsItemToggledOpen() then
    self.selected = n
  end

  -- name
  imgui.TableNextColumn()
  if animation.name then
    imgui.TextUnformatted(animation.name)
  end

  -- duration
  imgui.TableNextColumn()
  if animation.duration then
    imgui.TextUnformatted(string.format("%f", animation.duration))
  end

  if node_open then
    for i, c in ipairs(animation.curves) do
      self:show_animation_curve(i, c)
    end

    imgui.TreePop()
  end
end

---@param scene lvrm.Scene?
function AnimationGui:ShowAnimation(scene)
  if not scene then
    return
  end
  util.show_table("sceneAnimationTable", { "num", "name/target", "duration" }, function()
    for i, a in ipairs(scene.animations) do
      self:show_animation(i, a)
    end
  end)
end

return AnimationGui
