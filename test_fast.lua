
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

print("Start Fast")
io.stdout:flush()
print(fib_fast(1000))
print("Done Fast")
