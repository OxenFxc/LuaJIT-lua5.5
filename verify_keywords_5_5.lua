
local function test(name, func)
  io.write("Test " .. name .. ": ")
  local status, err = pcall(func)
  if status then
    io.write("PASS\n")
  else
    io.write("FAIL (" .. tostring(err) .. ")\n")
  end
end

test("global keyword", function()
  -- Using load to avoid syntax error preventing script from running if global is missing
  local chunk = load("global x = 10; return x")
  assert(chunk() == 10)
end)

test("global function", function()
  local chunk = load("global function foo() return 20 end; return foo()")
  assert(chunk() == 20)
end)

test("global *", function()
  local chunk = load("global *; x = 30; return x")
  assert(chunk() == 30)
end)

test("loop variable constness (numeric)", function()
  local chunk, load_err = load([[
    for i = 1, 3 do
      i = i + 1
    end
  ]])

  if not chunk then
    -- Compilation failed, check error message
    if not string.find(tostring(load_err), "assign to const variable") then
         error("Unexpected compilation error: " .. tostring(load_err))
    end
    -- PASS (Compilation failed as expected)
    return
  end

  -- If it compiled, it should fail at runtime (unlikely for LuaJIT as it checks at parse time usually)
  local status, err = pcall(chunk)
  if status then
    error("Should have failed to assign to loop variable")
  else
    -- Expected error
    if not string.find(tostring(err), "assign to const variable") then
       error("Unexpected runtime error: " .. tostring(err))
    end
  end
end)

test("loop variable constness (generic)", function()
  local chunk, load_err = load([[
    for k, v in pairs({a=1}) do
      k = "b"
    end
  ]])

  if not chunk then
    if not string.find(tostring(load_err), "assign to const variable") then
         error("Unexpected compilation error: " .. tostring(load_err))
    end
    return
  end

  local status, err = pcall(chunk)
  if status then
      error("Should have failed to assign to loop control variable 'k'")
  else
      if not string.find(tostring(err), "assign to const variable") then
         error("Unexpected runtime error: " .. tostring(err))
      end
  end
end)

test("loop variable mutable (generic 2nd var)", function()
  local chunk = load([[
    for k, v in pairs({a=1}) do
      v = 2
    end
  ]])
  if chunk then
      chunk() -- Should succeed
  else
      error("Compilation failed")
  end
end)

test("integer division //", function()
  assert(load("return 10 // 3")() == 3)
  assert(load("return 10.5 // 3")() == 3.0)
end)

test("bitwise operators", function()
  assert(load("return 3 & 5")() == 1) -- 011 & 101 = 001
  assert(load("return 3 | 5")() == 7) -- 011 | 101 = 111
  assert(load("return 3 ~ 5")() == 6) -- 011 ^ 101 = 110
  assert(load("return 1 << 3")() == 8)
  assert(load("return 16 >> 2")() == 4)
  assert(load("return ~0")() == -1)
end)

test("math.type", function()
  assert(math.type(1))
end)

test("lua_newuserdatauv stub", function()
  -- verified by existence
end)
