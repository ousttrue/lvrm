---@cast assert table

describe("a test", function()
  -- tests go here

  describe("a nested block", function()
    describe("can have many describes", function()
      -- tests
    end)
  end)

  -- more tests pertaining to the top level
end)
