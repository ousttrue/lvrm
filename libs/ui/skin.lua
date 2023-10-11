local util = require "ui.util"
---@class cimgui
local imgui = require "cimgui"

---@class Skin: SkinInstance
local Skin = {}
Skin.__index = Skin

---@return Skin
function Skin.new()
  ---@class SkinInstance
  ---@field selected integer?
  local instance = {
    splitter = util.Splitter.new(),
  }
  ---@type Skin
  return setmetatable(instance, Skin)
end

---@param scene lvrm.Scene
function Skin:ShowSkin(scene)
  if not scene then
    return
  end

  local size = imgui.GetContentRegionAvail()

  local l, r = self.splitter:SplitVertical { size.x, size.y }

  imgui.PushStyleVar_Vec2(imgui.ImGuiStyleVar_WindowPadding, { 0.0, 0.0 })
  if imgui.BeginChild_Str("selectSkin", { l, -1 }, true) then
    for i, skin in ipairs(scene.skins) do
      if imgui.Selectable_Bool(string.format("%d", i), i == self.selected) then
        self.selected = i
      end
    end
  end
  imgui.EndChild()

  imgui.SameLine()

  if imgui.BeginChild_Str("inversedMatrices", { r, -1 }, true) then
    local skin = scene.skins[self.selected]
    if skin then
      util.show_table(
        "inversedBindMatrices",
        { "i", "node", "t", "r", "s", "mat4" },
        function()
          assert(#skin.joints == skin.inversed_bind_matrices.len)
          for i, joint_index in ipairs(skin.joints) do
            imgui.TableNextRow()
            imgui.TableNextColumn()
            imgui.TextUnformatted(string.format("%d", i))

            imgui.TableNextColumn()
            local node = scene.nodes[joint_index + 1] -- 0to1origin
            if node then
              local nt, nr, ns = node.world_matrix:decompose()
              local str = string.format(
                "[%d]%s, %s, %s, %s",
                joint_index,
                node.name,
                nt,
                nr,
                ns
              )
              imgui.TextUnformatted(str)
            end

            ---@type falg.Mat4
            local m = skin.inversed_bind_matrices.ptr[i - 1]
            local t, r, s = m:decompose()
            imgui.TableNextColumn()
            imgui.TextUnformatted(string.format("%s", t))
            imgui.TableNextColumn()
            imgui.TextUnformatted(string.format("%s", r))
            imgui.TableNextColumn()
            imgui.TextUnformatted(string.format("%s", s))

            imgui.TableNextColumn()
            imgui.TextUnformatted(
              string.format(
                "[%0.2f,%0.2f,%0.2f,%0.2f][%0.2f,%0.2f,%0.2f,%0.2f][%0.2f,%0.2f,%0.2f,%0.2f][%0.2f,%0.2f,%0.2f,%0.2f]",
                m._11,
                m._12,
                m._13,
                m._14,
                m._21,
                m._22,
                m._23,
                m._24,
                m._31,
                m._32,
                m._33,
                m._34,
                m._41,
                m._42,
                m._43,
                m._44
              )
            )
          end
        end
      )
    end
  end
  imgui.EndChild()

  imgui.PopStyleVar()
end

return Skin
