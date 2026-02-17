
local function fib_iter(n)
  local a, b = 0, 1
  for i = 1, n do
    a, b = b, a + b
  end
  return a
end

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

print("Start")
io.stdout:flush()
print(fib_iter(100))
print("Done")
