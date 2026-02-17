
local function loop(n)
  local a, b = 0, 1
  for i = 1, n do
    a, b = b, b
    if i % 10 == 0 then print(i) io.stdout:flush() end
  end
end
loop(100)
print("Done")
