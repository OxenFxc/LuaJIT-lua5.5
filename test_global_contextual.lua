
local function test_global_as_local()
  local code = [[
    local global = 1
    return global
  ]]
  local f, err = load(code)
  if f then
    print("PASS: local global = 1 works")
  else
    print("FAIL: local global = 1 failed: " .. tostring(err))
  end
end

test_global_as_local()
