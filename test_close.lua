
local function test_close()
  local closed = false
  local t = setmetatable({}, {
    __close = function(self, err)
      assert(self)
      assert(err == nil)
      print("Closing!", err)
      closed = true
    end
  })

  do
    local x <close> = t
    print("Inside scope")
  end
  print("Outside scope")
  assert(closed == true, "Variable was not closed")
end

local function test_error()
  local closed = false
  local t = setmetatable({}, {
    __close = function(self, err)
      assert(self)
      assert(err)
      print("Closing on error!", err)
      closed = true
    end
  })

  pcall(function()
    local x <close> = t
    error("Oops")
  end)
  assert(closed == true, "Variable was not closed on error")
end

test_close()
test_error()
print("All tests passed!")
