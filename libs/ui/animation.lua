local util = require "ui.util"
local bit = require "bit"
---@class cimgui
local imgui = require "cimgui"

---
--- ShowAnimation
---
---@param n integer
---@param curve lvrm.AnimationCurve
local function show_animation_curve(n, curve)
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
---@param selected integer?
---@return boolean
local function show_animation(n, animation, selected)
  imgui.TableNextRow()

  --- num
  imgui.TableNextColumn()
  local flags = util.make_node_flags { is_leaf = false, is_selected = n == selected }
  imgui.SetNextItemOpen(true, imgui.ImGuiCond_FirstUseEver)
  local node_open = imgui.TreeNodeEx_Ptr(animation.id, flags, string.format("%d", n))
  local new_select = false
  if imgui.IsItemClicked() and not imgui.IsItemToggledOpen() then
    new_select = true
  end

  imgui.TableNextColumn()
  if animation.name then
    imgui.TextUnformatted(animation.name)
  end

  if node_open then
    for i, c in ipairs(animation.curves) do
      show_animation_curve(i, c)
    end

    imgui.TreePop()
  end

  return new_select
end

local selected = {}

---@param scene lvrm.Scene?
---@return integer?
function ShowAnimation(scene)
  if not scene then
    return
  end
  util.show_table("sceneAnimationTable", { "num", "name/target", "duration" }, function()
    for i, a in ipairs(scene.animations) do
      if show_animation(i, a, selected[1]) then
        selected[1] = i
      end
    end
  end)
  return selected[1]
end

return ShowAnimation
