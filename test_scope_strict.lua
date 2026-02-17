
local function test_strict()
  local code = [[
    X = 1       -- Ok, global by default
    do
      global Y  -- voids the implicit initial declaration
      Y = 1     -- Ok, Y declared as global
      X = 1     -- ERROR, X not declared
    end
    X = 2       -- Ok, global by default again
  ]]
  local f, err = load(code)
  if f then
    print("FAIL: Compilation succeeded, but should have failed for 'X = 1' inside do..end")
    local ok, res = pcall(f)
    if ok then
      print("FAIL: Execution succeeded")
    else
      print("PASS: Execution failed: " .. tostring(res))
    end
  else
    if string.find(err, "declared") or string.find(err, "X") then
      print("PASS: Compilation failed as expected: " .. err)
    else
      print("FAIL: Compilation failed but unexpected error: " .. err)
    end
  end
end

test_strict()
