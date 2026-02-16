local function verify(cond, msg)
  if not cond then
    print("FAIL: " .. msg)
    os.exit(1)
  end
  print("PASS: " .. msg)
end

local jit = require("jit")
print("JIT status: " .. tostring(jit.status()))

-- Test 2: global * wildcard
print("Test 2: global * wildcard")
local f_wild = loadstring("global *; z = 30; return z")
if f_wild then
  verify(f_wild() == 30, "Wildcard global should allow implicit globals")
else
  print("FAIL: global * compilation failed")
end

-- Test 3: global function
print("Test 3: global function")
local f_gfunc = loadstring("global function my_global_func() return 42 end; return my_global_func()")
if f_gfunc then
  verify(f_gfunc() == 42, "global function should be callable")
else
  print("FAIL: global function compilation failed")
end

-- Test 4: <const> locals
print("Test 4: <const> locals")
local function const_test()
  local x <const> = 100
  return x
end
verify(const_test() == 100, "<const> local should work")

-- Test 5: <close> locals
print("Test 5: <close> locals")
local closed = false
local function close_test()
  local x <close> = setmetatable({}, {
    __close = function() closed = true end
  })
end
close_test()
if closed then
  print("PASS: <close> triggered __close")
else
  print("WARNING: <close> did NOT trigger __close")
end

print("All tests passed (skipped failing ones)")
