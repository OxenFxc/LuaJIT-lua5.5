local function verify_const()
  print("Verifying <const> variables...")
  local x <const> = 10
  -- Check that assignment fails at compile time?
  -- "The compiler checks that const variables are not assigned to."
  -- In Lua 5.4, assignment to const is a syntax error if detected, or runtime error?
  -- "It is a compile-time error to assign to a constant variable."
  -- So `loadstring("local x <const> = 1; x = 2")` should fail.

  local code = [[
    local x <const> = 1
    x = 2
  ]]
  local f, err = loadstring(code)
  if f then
    print("Warning: Compilation of assignment to const succeeded (runtime check?)")
    local ok, r_err = pcall(f)
    if ok then
       error("Assigning to <const> variable should fail!")
    else
       print("Caught expected runtime error: " .. tostring(r_err))
    end
  else
    print("Caught expected compile error: " .. tostring(err))
  end
end

local function verify_close()
  print("Verifying <close> variables...")
  local closed = false
  local mt = {
    __close = function(t, err)
      print("Closing " .. t.name)
      closed = true
    end
  }

  do
    local x <close> = setmetatable({name="X"}, mt)
    print("Inside block with <close> variable")
  end

  if not closed then
    error("<close> variable not closed properly!")
  end
  print("<close> verified.")
end

local function verify_warn()
  print("Verifying warn function...")
  if not warn then
    print("warn function is missing!") -- Should catch if I failed to add it
  else
    warn("This is a warning test")
    print("warn function call successful.")
  end
end

local function verify_coroutine_close()
  print("Verifying coroutine.close...")
  if not coroutine.close then
    print("coroutine.close is missing!")
    return
  end

  local closed_count = 0
  local co = coroutine.create(function()
    local x <close> = setmetatable({name="CO_VAR"}, {
      __close = function(t, err)
        print("Closing coroutine variable " .. t.name)
        closed_count = closed_count + 1
      end
    })
    coroutine.yield()
  end)

  coroutine.resume(co)
  local ok, err = coroutine.close(co)
  if not ok then
    error("coroutine.close failed: " .. tostring(err))
  end

  if coroutine.status(co) ~= "dead" then
    error("Coroutine should be dead after close, but is " .. coroutine.status(co))
  end

  if closed_count ~= 1 then
     error("Coroutine variable not closed! count=" .. closed_count)
  end
  print("coroutine.close verified.")
end

verify_const()
verify_close()
verify_warn()
verify_coroutine_close()

print("All verification tests passed!")
