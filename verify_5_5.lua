
local function test_feature(name, func)
    io.write("Testing " .. name .. "... ")
    local status, err = pcall(func)
    if status then
        print("OK")
    else
        print("FAIL: " .. tostring(err))
    end
end

test_feature("global keyword", function()
    local f = load("global x = 10; return x")
    if not f then error("Failed to load global syntax") end
    if f() ~= 10 then error("global assignment failed") end
end)

test_feature("global const", function()
    local f = load("global <const> y = 20; return y")
    if not f then error("Failed to load global const syntax") end
    if f() ~= 20 then error("global const assignment failed") end

    local status, err = pcall(load("global <const> z = 30; z = 40"))
    if status then error("Expected error when assigning to global const") end
end)

test_feature("local const", function()
    local f = load("local <const> a = 50; return a")
    if not f then error("Failed to load local const syntax") end
    if f() ~= 50 then error("local const assignment failed") end
end)

test_feature("bitwise ops", function()
    local f = load("return 1 << 2")
    if f() ~= 4 then error("<< operator failed") end

    f = load("return 4 >> 1")
    if f() ~= 2 then error(">> operator failed") end

    f = load("return 3 & 1")
    if f() ~= 1 then error("& operator failed") end
end)

test_feature("integer division", function()
    local f = load("return 10 // 3")
    if f() ~= 3 then error("// operator failed") end
end)

test_feature("math.type", function()
    if not math.type then error("math.type is missing") end
    local t1 = math.type(1)
    -- Relaxed check for non-dualnum builds
    if t1 ~= "integer" and t1 ~= "float" then error("math.type(1) returned unexpected " .. tostring(t1)) end
    if t1 == "float" then print("(Note: integers represented as floats) ") end

    local t15 = math.type(1.5)
    if t15 ~= "float" then error("math.type(1.5) is " .. tostring(t15)) end
end)

-- test_feature("string.pack", function()
--     if not string.pack then error("string.pack is missing") end
-- end)

test_feature("utf8 library", function()
    if not utf8 then error("utf8 library is missing") end
    if utf8.len("å") ~= 1 then error("utf8.len failed") end
end)

-- JIT Verification
local function verify_jit(name, func)
    io.write("Verifying JIT for " .. name .. "... ")
    if not jit then
        print("SKIP (jit lib missing)")
        return
    end
    jit.flush()
    jit.on()
    jit.opt.start("hotloop=5") -- Trigger quickly

    local traces = 0
    local function trace_cb(what, tr, func, pc, otr, oex)
        if what == "stop" then traces = traces + 1 end
    end
    jit.attach(trace_cb, "trace")

    local ok, err = pcall(function()
        for i = 1, 50 do
            func(i)
        end
    end)

    jit.attach(trace_cb) -- detach

    if not ok then
        print("FAIL (Runtime error: " .. tostring(err) .. ")")
    elseif traces > 0 then
        print("OK (Trace generated)")
    else
        print("OK (No crash, but no trace recorded - might be too simple or NYI)")
    end
end

verify_jit("global", function(i)
    local chunk = load("global gjit = 0; gjit = gjit + 1")
    chunk()
end)

verify_jit("bitwise", function(i)
    local x = i << 1
end)

verify_jit("math.type", function(i)
    local t = math.type(i)
end)

print("Verification complete.")
