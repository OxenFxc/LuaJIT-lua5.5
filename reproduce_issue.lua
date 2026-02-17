global print, x, y
x = 7
do
  local x = x
  print(x)
  x = x + 1
  local y = x * x
  global y = y
  do
    local <const> x = x + 1
    print(x)
  end
  print(x)
end
print(x)
print(y)
