
local function test_global_const()
  local code = [[
    global <const> C = 100
    C = 200
  ]]
  local f, err = load(code)
  if f then
    print("FAIL: Compilation succeeded, but should have failed for assignment to const global")
  else
    if string.find(tostring(err), "assign to const variable") then
      print("PASS: Assignment to global const failed as expected")
    else
      print("FAIL: Compilation failed with unexpected error: " .. tostring(err))
    end
  end
end

local function test_global_basic()
  local code = [[
    global G = 100
    G = 200
    return G
  ]]
  local f, err = load(code)
  if f then
    if f() == 200 then
      print("PASS: Basic global assignment works")
    else
      print("FAIL: Basic global assignment failed logic")
    end
  else
    print("FAIL: Basic global compilation failed: " .. tostring(err))
  end
end

test_global_const()
test_global_basic()
