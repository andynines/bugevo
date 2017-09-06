--bugevo.lua

--[[
MIT License

Copyright (c) 2017 andynines

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
]]--

local FIELD_X = 250
local FIELD_Y = 250
local CODES = {EMPTY=1, --Number codes indicating a certain object on a field space
               BUG=2,
               BACTERIA=3}

local INITIAL_BACTERIA = 200 --Bacteria already on the field at iteration 0
local MAX_BACTERIA = 500 --How many bacteria may exist on the field at one time
local BACTERIA_REPLENISH_WAIT = 2 --How many iterations between a new bacteria spawn
local BACTERIA_REPLENISH_QUANTITY = 1 --How many bacteria spawn upon replenishment

local INITIAL_BUGS = 100 --Bugs already on the field at iteration 0
local MAX_AGE = 1000 --Maximum iterations a bug can undergo before it dies

local INITIAL_ENERGY = 400 --Amount of energy that every bug is initialized with
local MAX_ENERGY = 1500 --Maximum amount of energy a bug can hold
local MOVE_ENERGY_CONSUMPTION = 1 --How much energy it takes a bug to undergo one iteration
local EAT_ENERGY_GAIN = 300 --How much energy a bug gains from consuming one bacteria

local REPRODUCTIVE_MIN_AGE = 800 --Minimum iterations a bug must have undergone before reproducing
local REPRODUCTIVE_MIN_ENERGY = 1000 --Minimum energy level a bug must hold to reproduce
local OFFSPRING = 2 --How many offspring are created when a bug reproduces
local MUTATION_RATE = 1 --Change rate of movement probabilities of a bug's offspring
local DIRECTION_MAX_PROBABILITY = 50 --Largest probability a bug may have to move in a certain direction

local function xy(x, y)
    --Create coordinate pair objects
    return {x=x, y=y}
end

local RIGID_BORDERS = false --If false, bugs can cross edges and will appear on the opposite side
local MOVEMENT_DISTANCE = 1 --How many spaces a bug can move in one iteration
local MOVE_DELTAS = {xy(0, MOVEMENT_DISTANCE), --Coordinate pair addends for every direction of movement
                     xy(0, -MOVEMENT_DISTANCE),
                     xy(MOVEMENT_DISTANCE, 0),
                     xy(-MOVEMENT_DISTANCE, 0),
                     xy(MOVEMENT_DISTANCE, MOVEMENT_DISTANCE),
                     xy(MOVEMENT_DISTANCE, -MOVEMENT_DISTANCE),
                     xy(-MOVEMENT_DISTANCE, MOVEMENT_DISTANCE),
                     xy(-MOVEMENT_DISTANCE, -MOVEMENT_DISTANCE)}

local SAMPLE_INTERVAL = 200 --Print information about a random bug at this interval

local insert = table.insert
local remove = table.remove
local random = math.random
local print = print

math.randomseed(os.time())

local field
local bugs
local bacteria_count
local replenish_timer
local iteration
local sample

local function within_borders(position)
    --Verifies whether a position is within the field
    return xy(position.x > 0 and position.x <= FIELD_X, position.y > 0 and position.y <= FIELD_Y)
end

local function find_empty()
    --Find and return an empty space on the field
    local field = field
    local attempts = 0
    local max_attempts = FIELD_X * FIELD_Y
    repeat
        local check_x, check_y = random(1, FIELD_X), random(1, FIELD_Y)
        if field[check_x][check_y] == CODES.EMPTY then
            return xy(check_x, check_y)
        end
        attempts = attempts + 1
    --Edge case: there are no empty spaces left
    until attempts == max_attempts
    return nil
end

local function adjacents_of(position)
    --Return a table of deltas to move to available adjacent locations of a position
    local adjacents = {}
    for delta = 1, #MOVE_DELTAS do
        local current_delta = MOVE_DELTAS[delta]
        local check_position = xy(position.x + current_delta.x, position.y + current_delta.y)
        local border_check = within_borders(check_position)
        if (border_check.x and border_check.y) and field[check_position.x][check_position.y] == CODES.EMPTY then
            insert(adjacents, current_delta)
        end
    end
    return adjacents
end

local function spawn_bacteria(quantity)
    --Spawns some amount of bacteria in empty spaces on the field
    for bacteria = 1, quantity do
        if not (bacteria_count < MAX_BACTERIA) then
            break
        end
        local new_position = find_empty()
        if new_position then
            field[new_position.x][new_position.y] = CODES.BACTERIA
            bacteria_count = bacteria_count + 1
        else
            return nil
        end
    end
end

local function mutate(genes)
    --Slightly alter a bug's movement genes
    for direction, probability in pairs(genes) do
        local new_gene = probability + MUTATION_RATE * random(-1, 1)
        if new_gene < 0 then
            new_gene = 0
        elseif new_gene > DIRECTION_MAX_PROBABILITY then
            new_gene = DIRECTION_MAX_PROBABILITY
        end
        genes[direction] = new_gene
    end
    return genes
end

--Bug object class
local Bug = {}
Bug.__index = Bug

function Bug:new(generation, position, genes)
    local self = {}
    self.generation = generation or 1
    self.age = 0
    self.energy = INITIAL_ENERGY
    if position then
        self.position = position
    else
        local new_position = find_empty()
        if new_position then
            self.position = new_position
        else
            return nil
        end
    end
    field[self.position.x][self.position.y] = CODES.BUG
    if genes then
        self.genes = genes
    else
        self.genes = {}
        for direction = 1, #MOVE_DELTAS do
            insert(self.genes, random(0, DIRECTION_MAX_PROBABILITY))
        end
    end
    return setmetatable(self, Bug)
end

function Bug:info()
    --Print the bug's attributes
    sample = sample + 1
    print("bug sample #".. sample..
          "\ngeneration ".. self.generation..
          "\nage ".. self.age..
          "\nenergy ".. self.energy..
          "\nlocation (".. self.position.x.. ", ".. self.position.y.. ")")
    for probability_index, probability in pairs(self.genes) do
        local current_delta = MOVE_DELTAS[probability_index]
        print("gene (".. current_delta.x.. ", ".. current_delta.y.. ") ".. probability.. "/".. DIRECTION_MAX_PROBABILITY)
    end
    print("end info\n")
end

function Bug:wander()
    --Bug chooses a random direction of travel according to its genes
    local probabilities = {}
    for direction, probability in pairs(self.genes) do
        for chance = 1, probability do
            insert(probabilities, direction)
        end
    end
    --Bug finds nowhere to move
    if not (#probabilities > 0) then
        return nil
    end
    local movement_delta = MOVE_DELTAS[probabilities[random(1, #probabilities)]]
    local new_position = xy(self.position.x + movement_delta.x, self.position.y + movement_delta.y)
    --Move to new location if possible
    local border_check = within_borders(new_position)
    if (not border_check.x) or (not border_check.y) then
        if RIGID_BORDERS then
            return nil
        else
            --Screen wrap the bug if allowed
            local field_dimensions = xy(FIELD_X, FIELD_Y)
            for axis_index, axis in pairs({"x", "y"}) do
                if not border_check[axis] then
                    new_position[axis] = new_position[axis] - movement_delta[axis] * field_dimensions[axis]
                end
            end
        end
    end
    local position_check = field[new_position.x][new_position.y]
    if not (position_check == CODES.EMPTY or position_check == CODES.BACTERIA) then
        return nil
    end
    field[self.position.x][self.position.y] = CODES.EMPTY
    self.position = new_position
    --Bacteria consumption
    if field[self.position.x][self.position.y] == CODES.BACTERIA then
        self.energy = self.energy + EAT_ENERGY_GAIN
        if self.energy > MAX_ENERGY then
            self.energy = MAX_ENERGY
        end
        bacteria_count = bacteria_count - 1
    end
    field[self.position.x][self.position.y] = CODES.BUG
    return true
end

function Bug:reproduce()
    --Spawn slightly mutated children adjacent to a bug
    local adjacents = adjacents_of(self.position)
    if #adjacents >= OFFSPRING then
        local offspring = 0
        repeat
            spawn_delta = remove(adjacents, random(1, #adjacents))
            insert(bugs, Bug:new(self.generation + 1,
                                 xy(self.position.x + spawn_delta.x, self.position.y + spawn_delta.y),
                                 mutate(self.genes)))
            offspring = offspring + 1
        until offspring == OFFSPRING
        return true
    else
        return nil
    end
end

local function initialize()
    --Initialize spatial database: contains an element for every space of the field
    field = {}
    for x = 1, FIELD_X do
        field[x] = {}
        for y = 1, FIELD_Y do
            field[x][y] = CODES.EMPTY
        end
    end
    --Initialize bug database: contains all currently alive bugs
    bugs = {}
    for bug_count = 1, INITIAL_BUGS do
        local new_bug = Bug:new()
        if new_bug then
            insert(bugs, new_bug)
        else
            break
        end
    end
    --Create initial supply of bacteria
    bacteria_count = 0
    spawn_bacteria(INITIAL_BACTERIA)
    --Initialize time-based variables
    replenish_timer = 0
    iteration = 0
    sample = 0
end

local function iterate()
    --Iterate through the bugs list and move every bug, then remove dead ones
    local dead_indexes = {}
    for bug_index = 1, #bugs do
        bugs[bug_index]:wander()
        --Bug matures
        bugs[bug_index].age = bugs[bug_index].age + 1
        bugs[bug_index].energy = bugs[bug_index].energy - MOVE_ENERGY_CONSUMPTION
        --Kill old and starving bugs
        local bug = bugs[bug_index]
        if bug.age > MAX_AGE or bug.energy <= 0 then
            insert(dead_indexes, bug_index)
        --Allow healthy, sufficiently aged bugs to reproduce if they have the space
        elseif bug.age >= REPRODUCTIVE_MIN_AGE and bug.energy >= REPRODUCTIVE_MIN_ENERGY then
            if bug:reproduce() then
                --Bugs die after reproducing
                insert(dead_indexes, bug_index)
            end
        end
    end
    --Remove all dead bugs
    for removals = 1, #dead_indexes do
        local current_index = dead_indexes[1]
        local dead_bug = bugs[current_index]
        field[dead_bug.position.x][dead_bug.position.y] = CODES.EMPTY
        remove(bugs, current_index)
    end
    --End simulation if population dies
    if #bugs == 0 then
        return nil
    end
    --Replenish bacteria
    replenish_timer = replenish_timer + 1
    if replenish_timer == BACTERIA_REPLENISH_WAIT then
        spawn_bacteria(BACTERIA_REPLENISH_QUANTITY)
        replenish_timer = 0
    end
    iteration = iteration + 1
    --Sample the population
    if iteration % SAMPLE_INTERVAL == 0 then
        bugs[math.random(1, #bugs)]:info()
    end
    return {field=field, iteration=iteration, population=#bugs}
end

--Information necessary for visual representation
return {FIELD_X=FIELD_X,
        FIELD_Y=FIELD_Y,
        CODES=CODES,
        initialize=initialize,
        iterate=iterate}
