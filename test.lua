--[[
test.lua
Copyright (c) 2017 andynines
MIT License
]]--

local simulation = require("bugevo")

local initialize = simulation.initialize
local iterate = simulation.iterate

local MAX_ITERATIONS = 30000 --End the program after this many iterations

initialize()
print("Simulation will cease after ".. MAX_ITERATIONS.. " iterations\n")
for to_max = 1, MAX_ITERATIONS do
    if not iterate() then
        print("The bugs went extinct")
        os.exit()
    end
end
print("Maximum iterations reached")
