--[[
test.lua
Copyright (c) 2017 andynines
MIT License
]]

local simulation = require("bugevo")

local MAX_ITERATIONS = 10000 --Simulation will end at or before this many iterations
local SAMPLE_INTERVAL = 500 --A bug's attributes are printed at this iteration period

local initialize = simulation.initialize
local iterate = simulation.iterate

local function test()
    initialize()
    io.write("Simulation will terminate after ".. MAX_ITERATIONS.. " iterations\n\n")
    for _ = 1, MAX_ITERATIONS do
        local data = iterate()
        if not data then
            --Simulation returning nil means population has died
            return "The bugs went extinct"
        elseif data.iteration % SAMPLE_INTERVAL == 0 then
            --Routinely provide data on a random bug
            io.write(data.bugs[math.random(1, #data.bugs)]:info().. "\n")
        end
    end
    return "Maximum iterations reached"
end

io.write(test().. "\nSimulation terminated\n")
