
global print, require, tostring
local jit = require("jit")
local jv = require("jit.v")

jit.opt.start("hotloop=5")
jit.flush()
jv.on("-") -- print trace info to stdout

global G = 0

local function run()
  local sum = 0
  for i = 1, 1000 do
    G = G + 1
    sum = sum + G
  end
  return sum
end

run()
