--[[
main.lua
Copyright (c) 2017 andynines
MIT License
]]

local simulation = require("bugevo")

local FIELD_X = simulation.FIELD_X
local FIELD_Y = simulation.FIELD_Y
local CODES = simulation.CODES
local initialize = simulation.initialize
local iterate = simulation.iterate

local function rgb(r, g, b)
    return {r=r, g=g, b=b}
end

local WINDOW_TITLE = "BugEvo"
local RUN_PROMPT = "Press [SPACE] to begin a new simulation"
local WORD_WRAP = 500

local TEXT_COLOR = rgb(255, 255, 153)
local BACKGROUND_COLOR = rgb(0, 0, 0)
local BUG_COLOR = rgb(153, 255, 0)
local BACTERIA_COLOR = rgb(76, 0, 153)

--Keyboard control
local RUN_CONTROL = " "
local QUIT_CONTROL = "q"

local STATES = {INITIAL=1,
                ACTIVE=2}

--Stretch simulation space to fit display window
local X_STRETCH = love.graphics.getWidth() / FIELD_X
local Y_STRETCH = love.graphics.getHeight() / FIELD_Y

--Initialize display window
love.graphics.setCaption(WINDOW_TITLE)
love.graphics.setBackgroundColor(BACKGROUND_COLOR.r, BACKGROUND_COLOR.g, BACKGROUND_COLOR.b)

local state

local function initial()
    --Wait for user input and initialize a new simulation
    love.graphics.setColor(TEXT_COLOR.r, TEXT_COLOR.g, TEXT_COLOR.b)
    love.graphics.printf(RUN_PROMPT, 0, 0, WORD_WRAP)
    if love.keyboard.isDown(RUN_CONTROL) then
        initialize()
        state = STATES.ACTIVE
    end
end

local function active()
    --Iterate over the current simulation
    local data = iterate()
    if not data then
        --Simulation returns nil when ended; return to start screen
        state = STATES.INITIAL
    else
        local field = data.field
        local iteration = data.iteration
        local population = data.population
        for x = 1, #field do
            for y = 1, #field[x] do
                if field[x][y] ~= CODES.EMPTY then
                    if field[x][y] == CODES.BUG then
                        love.graphics.setColor(BUG_COLOR.r, BUG_COLOR.g, BUG_COLOR.b)
                    elseif field[x][y] == CODES.BACTERIA then
                        love.graphics.setColor(BACTERIA_COLOR.r, BACTERIA_COLOR.g, BACTERIA_COLOR.b)
                    end
                    --[[Adjustments are made here to transition between "simulation" and "LOVE2D" space.
                        1. LOVE2D coordinates begin counting from 0; the simulation counts from 1
                        2. LOVE2D draws in the foruth quadrant of the cartesian plane; the simulation uses the first]]
                    love.graphics.rectangle("fill", X_STRETCH * x - X_STRETCH, (FIELD_Y - y) * Y_STRETCH, X_STRETCH, Y_STRETCH)
                end
            end
        end
        love.graphics.setColor(TEXT_COLOR.r, TEXT_COLOR.g, TEXT_COLOR.b)
        love.graphics.printf("iter ".. iteration.. "\npop ".. population, 0, 0, WORD_WRAP)
    end
end

local STATE_FUNCTIONS = {initial, active}

state = STATES.INITIAL

function love.draw()
    --Check for quit command, else do according to the state of the program
    if love.keyboard.isDown(QUIT_CONTROL) then
        love.event.quit()
    end
    STATE_FUNCTIONS[state]()
end
