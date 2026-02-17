
print("Def fib_iter")
local function fib_iter(n)
  local a, b = 0, 1
  for i = 1, n do
    a, b = b, b -- a + b
    -- if i % 10 == 0 then print(i) io.stdout:flush() end
  end
  return 1 -- a
end

print("Def fib_fast")
local function fib_fast(n)
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
print(res) -- print("Fib(100) iterative:", res, type(res))
io.stdout:flush()

print("Starting fib_fast(1000)")
io.stdout:flush()
-- res = fib_fast(1000)
res = fib_fast(1000)
print("Fib(1000) fast doubling:", res, type(res))
io.stdout:flush()
