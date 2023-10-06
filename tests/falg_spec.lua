---@cast assert table

package.path = string.format("%s;./libs/?.lua;./libs/?/init.lua", package.path)

local falg = require "falg"

describe("falg", function()
  it("float", function()
    local invalid = falg.Float3(math.huge, -math.huge, 0/0)

    assert.truthy(0 < invalid.X)
    assert.truthy(0 > invalid.Y)
  end)

  it("float3", function()
    local l = falg.Float3(1, 2, 3)
    local r = falg.Float3(1, 2, 3)
    assert.same(l, r)
    assert.same(2, l.Y)
    assert.same(l.Z, r.Z)
    assert.same(falg.Float3(2, 4, 6), l + r)
    assert.same(falg.Float3(2, 4, 6), l:scale(2))
  end)

  it("aabb", function()
    local bb = falg.AABB.new()
    bb:extend(falg.Float3(0, 0, 0))
    assert.truthy(bb:enabled())
  end)

  describe("mat4", function()
    it("mat4", function()
      local l = falg.Mat4(1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16)
      local r = falg.Mat4(1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16)
      assert.same(l, r)
      assert.same(5, l._21)
      assert.same(l._21, r._21)

      assert.same(falg.Mat4(1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1), falg.Mat4.new_identity())
    end)

    it("scale", function()
      local m = falg.Mat4.new_scale(1, 2, 3)
      local expected = falg.Mat4(1, 0, 0, 0, 0, 2, 0, 0, 0, 0, 3, 0, 0, 0, 0, 1)
      assert.same(expected, m)
    end)
  end)
end)
