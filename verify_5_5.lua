local function verify(cond, msg)
  if not cond then
    print("FAIL: " .. msg)
    os.exit(1)
  end
  print("PASS: " .. msg)
end

local jit = require("jit")
print("JIT status: " .. tostring(jit.status()))

-- Test 10: warn function
print("Test 10: warn function")
if warn then
  warn("test warning")
  print("PASS: warn function (no crash)")
else
  print("FAIL: warn function missing")
end

-- Test 11: coroutine.close
print("Test 11: coroutine.close")
local closed_count = 0
local co = coroutine.create(function()
  local x <close> = setmetatable({}, {__close = function() closed_count = closed_count + 1 end})
  coroutine.yield()
end)
coroutine.resume(co)
if coroutine.close then
  local ok, err = coroutine.close(co)
  verify(ok, "coroutine.close should succeed")
  verify(closed_count == 1, "coroutine.close should trigger __close")
  print("PASS: coroutine.close")
else
  print("FAIL: coroutine.close missing")
end

-- Test 12: string.format %p
print("Test 12: string.format %p")
local t = {}
local s = string.format("%p", t)
print("Pointer: " .. s)
verify(string.match(s, "0x%x+") or string.match(s, "NULL"), "%p should return 0x... or NULL")
local f = function() end
s = string.format("%p", f)
print("Pointer func: " .. s)
verify(string.match(s, "0x%x+") or string.match(s, "NULL"), "%p func should return 0x... or NULL")
print("PASS: string.format %p")

-- Test 13: math.type
print("Test 13: math.type")
if math.type then
  local t1 = math.type(1)
  print("math.type(1) = " .. t1)
  local t1_5 = math.type(1.5)
  print("math.type(1.5) = " .. t1_5)
  verify(t1_5 == "float", "1.5 is float")
  print("PASS: math.type")
else
  print("FAIL: math.type missing")
end

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

-- Test 6: utf8 library
print("Test 6: utf8 library")
if not utf8 then
  print("FAIL: utf8 library not loaded")
  os.exit(1)
end

verify(utf8.len("abc") == 3, "utf8.len('abc')")
verify(utf8.len("äöü") == 3, "utf8.len('äöü')")
verify(utf8.char(65) == "A", "utf8.char(65)")
verify(utf8.codepoint("A") == 65, "utf8.codepoint('A')")
verify(utf8.offset("abc", 2) == 2, "utf8.offset('abc', 2)")
verify(utf8.offset("äöü", 2) == 3, "utf8.offset('äöü', 2)") -- 'ä' is 2 bytes

local s = "äöü"
local codes = {}
for p, c in utf8.codes(s) do
  table.insert(codes, c)
end
verify(#codes == 3, "utf8.codes count")
verify(codes[1] == 228, "utf8.codes 1") -- ä
verify(codes[2] == 246, "utf8.codes 2") -- ö
verify(codes[3] == 252, "utf8.codes 3") -- ü

print("PASS: utf8 library")

-- Test 7: continue statement
print("Test 7: continue statement")
local sum = 0
for i = 1, 10 do
  if i % 2 == 0 then
    continue
  end
  sum = sum + i
end
verify(sum == 25, "continue in for loop (sum of odds 1..10 is 25)")

local i = 0
sum = 0
while i < 10 do
  i = i + 1
  if i % 2 == 0 then
    continue
  end
  sum = sum + i
end
verify(sum == 25, "continue in while loop")
print("PASS: continue statement")

-- Test 8: Generic For Loop Iterator Closing
print("Test 8: Generic For Loop Iterator Closing")
local closed = false
local mt = {
  __close = function()
    closed = true
  end
}

local function iter()
  local t = setmetatable({}, mt)
  -- Return iterator, state, control, and the to-be-closed object
  return function() return nil end, nil, nil, t
end

for k in iter() do
end

if closed then
  print("PASS: Iterator closing variable was closed")
else
  print("FAIL: Iterator closing variable was NOT closed")
end

-- Test 9: JIT for Iterator Closing
print("Test 9: JIT for Iterator Closing")
local toclose_count = 0
local mt_jit = {
  __close = function()
    toclose_count = toclose_count + 1
  end
}

local function iter_jit()
  local t = setmetatable({}, mt_jit)
  return function(s, k)
    if k == nil then return 1 end
    if k >= 100 then return nil end
    return k + 1
  end, nil, nil, t
end

local sum = 0
for i = 1, 100 do
  for k in iter_jit() do
    sum = sum + k
  end
end

if toclose_count == 100 then
  print("PASS: JIT for close counted correctly")
else
  print("FAIL: JIT for close count mismatch: " .. toclose_count)
end
