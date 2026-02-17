
local function test_prefixed()
  local <const> x = 10
  print("Prefixed works: " .. x)
end

local function test_suffixed()
  local y <const> = 20
  print("Suffixed works: " .. y)
end

local function test_both()
  -- If both are allowed?
  -- local <const> z <close> = ...
  -- But maybe it's just optional position.
end

test_prefixed()
test_suffixed()
