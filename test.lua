--[[
test.lua
Copyright (c) 2017 andynines
MIT License
]]

local simulation = require("bugevo")

local MAX_ITERATIONS = 30000 --Simulation will end at or before this many iterations
local SAMPLE_INTERVAL = 500 --A bug's attributes are printed at this iteration period

local initialize = simulation.initialize
local iterate = simulation.iterate

local function test()
    initialize()
    print("Simulation will cease after ".. MAX_ITERATIONS.. " iterations\n")
    for _ = 1, MAX_ITERATIONS do
        local data = iterate()
        if not data then
            --Simulation returning nil means population has died
            print("The bugs went extinct")
            break
        elseif data.iteration % SAMPLE_INTERVAL == 0 then
            --Routinely provide data on a sample bug
            io.write(data.bugs[math.random(1, #data.bugs)]:info().. "\n")
        end
    end
    print("Maximum iterations reached")
end

test()
