-- JIT Verification
local function verify_jit(name, func)
    io.write("Verifying JIT for " .. name .. "... ")
    local jit = require("jit")
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
    -- We can use bitwise ops directly if parser supports them
    local f = load("return 1 << 1")
    f()
end)

verify_jit("math.type", function(i)
    if math.type then
        local t = math.type(i)
    end
end)

print("Verification complete.")
