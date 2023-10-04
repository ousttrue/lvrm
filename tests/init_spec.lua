---@cast assert table

-- init_spec.lua
describe("Test", function()
  describe("numerical", function()
    it("'0' is truthy", function()
      assert.is_truthy(0)
    end)

    -- failed test
    it("'1' equal '0'", function()
      assert.is_equal(1, 0)
    end)
  end)

  describe("non-numerical", function()
    it("nil is falsy", function()
      assert.is_falsy(nil)
    end)

    it("table value is same", function()
      assert.is_same({ value = "same" }, { value = "same" })
    end)

    it("object is equal", function()
      local a = { obj = "same" }
      local b = a
      assert.is_equal(a, b)
    end)
  end)
end)
