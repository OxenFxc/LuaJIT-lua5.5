
print("Def fib_iter")
local function fib_iter(n)
  local a, b = 0, 1
  for i = 1, n do
    a, b = b, b -- a + b
    if i % 1000 == 0 then print(i) io.stdout:flush() end
  end
  return 1 -- a
end

print("Def fib_fast")
local function fib_fast(n)
  -- print("fib_fast", n) io.stdout:flush()
  if n == 0 then return 0, 1 end
  local a, b = fib_fast(math.floor(n / 2))
  local c = a * (2 * b - a)
  local d = a * a + b * b
  if n % 2 == 0 then
    return c, d
  else
    return d, c + d
  end
end

print("Starting fib_iter(100)")
io.stdout:flush()
local res = fib_iter(100)
print(res)
io.stdout:flush()

local n = 10000
print("Starting fib_fast(" .. n .. ")")
io.stdout:flush()
res = fib_fast(n)
print("Fib(" .. n .. ") fast doubling:", res, type(res))
io.stdout:flush()
