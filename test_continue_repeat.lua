print("Starting repeat")
local i = 0
repeat
  i = i + 1
  if i % 2 == 0 then
    continue
  end
  print(i)
until i >= 10
print("Done repeat")
