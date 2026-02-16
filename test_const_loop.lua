
-- Test numeric for loop variable constness
print("Testing numeric for loop variable constness")
local func, err = loadstring([[
  for i = 1, 10 do
    i = 5
  end
]])

if not func then
  print("PASS: Numeric loop variable is const (compile error): " .. tostring(err))
else
  local status, err = pcall(func)
  if status then
    print("FAIL: Numeric loop variable is mutable")
    os.exit(1)
  else
    print("PASS: Numeric loop variable is const (runtime error): " .. tostring(err))
  end
end

-- Test generic for loop control variable constness
print("Testing generic for loop control variable constness")
local func, err = loadstring([[
  for k, v in pairs({a=1}) do
    k = "b"
  end
]])

if not func then
  print("PASS: Generic loop key variable is const (compile error): " .. tostring(err))
else
  local status, err = pcall(func)
  if status then
    print("FAIL: Generic loop key variable is mutable")
    os.exit(1)
  else
    print("PASS: Generic loop key variable is const (runtime error): " .. tostring(err))
  end
end

-- Test generic for loop value variable mutability
print("Testing generic for loop value variable mutability")
local func, err = loadstring([[
  for k, v in pairs({a=1}) do
    v = 2
  end
]])

if not func then
  print("FAIL: Generic loop value variable failed to compile: " .. tostring(err))
  os.exit(1)
else
  local status, err = pcall(func)
  if status then
    print("PASS: Generic loop value variable is mutable")
  else
    print("FAIL: Generic loop value variable raised error: " .. tostring(err))
    os.exit(1)
  end
end
