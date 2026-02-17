global print, x
x = 10
do
  local x = 20
  global x = x
  print(x)
end
print(x)
