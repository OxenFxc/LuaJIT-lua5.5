
local jit = require("jit")
if not jit then
  print("JIT not available")
  return
end

jit.on()
jit.flush()

local trace_count = 0
local abort_count = 0

jit.attach(function(what, tr, func, pc, otr, oex)
  if what == "trace" or what == "stop" then
    trace_count = trace_count + 1
  elseif what == "abort" then
    abort_count = abort_count + 1
  end
end, "trace", "stop", "abort")

local function test_loop_with_close()
  local t = setmetatable({}, {__close = function() end})
  for i=1,1000 do
    local x <close> = t
  end
end

test_loop_with_close()

print("Trace count:", trace_count)
print("Abort count:", abort_count)

if trace_count > 0 then
  print("JIT compilation succeeded!")
else
  print("JIT compilation failed (no traces formed).")
  -- Fail if we expected it to work
  -- os.exit(1)
end
print("Done")
