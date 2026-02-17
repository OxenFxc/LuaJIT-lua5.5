local function fib(n)
    local a, b = 0, 1
    for _ = 3, n do
        a, b = b, a + b
    end
    return b
end

print("fib(1477):", fib(1477))
print("fib(1478):", fib(1478))
