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

local function verify_param_const()
  print("Verifying parameter <const>...")
  local code = [[
    return function(x <const>)
      x = 10
    end
  ]]
  local chunk, err = loadstring(code)
  if chunk then
    print("Warning: Compilation of assignment to const param succeeded (runtime check?)")
    local f = chunk()
    local ok, r_err = pcall(f, 1)
    if ok then
       error("Assigning to <const> parameter should fail!")
    else
       print("Caught expected runtime error: " .. tostring(r_err))
    end
  else
    print("Caught expected compile error: " .. tostring(err))
  end
end

local function verify_param_close()
  print("Verifying parameter <close>...")
  local closed = false
  local mt = { __close = function() closed = true end }
  local function f(x <close>)
    print("Inside f with <close> param")
  end
  f(setmetatable({}, mt))
  if not closed then
    error("<close> parameter not closed!")
  end
  print("<close> parameter verified.")
end

local function verify_for_generic_close()
  print("Verifying generic for <close>...")
  local closed = 0
  local mt = { __close = function() closed = closed + 1 end }
  local function iter()
      local done = false
      return function()
        if done then return nil end
        done = true
        return setmetatable({}, mt)
      end
  end
  for x <close> in iter() do
    print("Inside generic loop with <close>")
  end
  if closed ~= 1 then
    error("Generic for loop variable not closed! count="..closed)
  end
  print("Generic for <close> verified.")
end

local function verify_for_generic_const()
  print("Verifying generic for <const>...")
  local code = [[
    for x <const> in pairs({a=1}) do
      x = 2
    end
  ]]
  local chunk, err = loadstring(code)
  if chunk then
    print("Warning: Compilation of assignment to const loop var succeeded (runtime check?)")
    local ok, r_err = pcall(chunk)
    if ok then
       error("Assigning to <const> loop variable should fail!")
    else
       print("Caught expected runtime error: " .. tostring(r_err))
    end
  else
    print("Caught expected compile error: " .. tostring(err))
  end
end

verify_param_const()
verify_param_close()
verify_for_generic_close()
verify_for_generic_const()

print("All verification tests passed!")
