local function test()
  local t = setmetatable({}, {
    __close = function(self, err)
      print("Closed!", err)
    end
  })
  local x <close> = t
  print("Inside scope")
end

print("Calling test")
pcall(test)
print("After test")

local jit = require("jit")
if jit then
    print("JIT is available")
    print(jit.status())
end
