local u = string.format("%U", 0x20AC) -- Euro sign
if u == "\xE2\x82\xAC" then
  print("%U: WORKED")
else
  print("%U: FAILED")
end

local p = string.format("%p", nil)
if p == "(nil)" then
  print("%p: WORKED")
else
  print("%p: FAILED (got '" .. tostring(p) .. "')")
end
