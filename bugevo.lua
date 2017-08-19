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

local FIELD_X = 180 --Width of environment
local FIELD_Y = 180 --Height of environment
local CODES = {EMPTY=1, --Number codes indicating a certain object on a field space
               BUG=2,
               BACTERIA=3}

local INITIAL_BACTERIA = 100 --Bacteria already on the field at iteration 0
local BACTERIA_REPLENISH = 1 --How many bacteria appear per iteration

local INITIAL_BUGS = 20 --Bugs already on the field at iteration 0
local MAX_AGE = 1000 --Maximum iterations a bug can undergo before it dies

local INITIAL_ENERGY = 650 --Amount of energy that every bug is initialized with
local MAX_ENERGY = 1000 --Maximum amount of energy a bug can hold
local MOVE_ENERGY_CONSUMPTION = 1 --How much energy it takes a bug to undergo one iteration
local EAT_ENERGY_GAIN = 25 --How much energy a bug gains from consuming one bacteria

local REPRODUCTIVE_MIN_AGE = 300 --Minimum iterations a bug must have undergone before reproducing
local REPRODUCTIVE_MIN_ENERGY = 435 --Minimum energy level a bug must hold to reproduce
local OFFSPRING = 2 --How many offspring are created when a bug reproduces
local MUTATION_RATE = 1 --Change rate of movement probabilities of a bug's offspring
local DIRECTION_MAX_PROBABILITY = 9 --Largest probability a bug may have to move in a certain direction

local function xy(x, y)
    --Create coordinate pair objects
    return {x=x, y=y}
end

local RIGID_BORDERS = false --If false, bugs may cross edges and appear on the opposite side
local MOVE_DELTAS = {xy(0, 1), --Coordinate pair addends for every direction of movement
                     xy(0, -1),
                     xy(1, 0),
                     xy(-1, 0),
		     xy(1, 1),
		     xy(1, -1),
		     xy(-1, 1),
		     xy(-1, -1)}

local setmetatable = setmetatable
local insert = table.insert
local remove = table.remove
local random = math.random
local randomseed = math.randomseed

randomseed(os.time())

local field
local bugs

local function within_borders(position)
    --Verifies whether a position is within the field
    return xy(position.x > 0 and position.x <= FIELD_X, position.y > 0 and position.y <= FIELD_Y)
end

local function get_position()
    --Find and return an empty space on the field
    local field = field
    local attempts = 0
    --Built with edge case in mind that there are no empty spaces
    local max_attempts = FIELD_X * FIELD_Y
    local check_x, check_y
    repeat
        check_x, check_y = random(1, FIELD_X), random(1, FIELD_Y)
        if field[check_x][check_y] == CODES.EMPTY then
            return xy(check_x, check_y)
        end
        attempts = attempts + 1
    until attempts == max_attempts
    return nil
end

local function get_adjacents(position)
    --Return a table of available directions to move adjacent to a given position
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
        local new_position = get_position()
        if new_position then
            field[new_position.x][new_position.y] = CODES.BACTERIA
        else
            return nil
        end
    end
end

local function mutate(genes)
    --Slightly alter the bug's movement genes
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

function Bug:new(heredity, spawn_point)
    local self = {}
    setmetatable(self, Bug)
    self.age = 0
    self.energy = INITIAL_ENERGY
    if spawn_point then
        self.position = spawn_point
    else
        local new_position = get_position()
        if new_position then
            self.position = new_position
        else
            return nil
        end
    end
    field[self.position.x][self.position.y] = CODES.BUG
    if heredity then
        self.genes = mutate(heredity)
    else
	self.genes = {}
        for direction = 1, #MOVE_DELTAS do
            insert(self.genes, random(0, DIRECTION_MAX_PROBABILITY))
	end
    end
    return self
end

function Bug:wander()
    --Bug chooses a random direction of travel according to its genes
    local directions = 0
    local probabilities = {}
    for direction, probability in pairs(self.genes) do
        directions = directions + 1
        for chance = 1, probability do
            insert(probabilities, directions)
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
	    if not border_check.x then
		new_position.x = new_position.x - movement_delta.x * FIELD_X
	    end
	    if not border_check.y then
		new_position.y = new_position.y - movement_delta.y * FIELD_Y
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
    end
    field[self.position.x][self.position.y] = CODES.BUG
    return true
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
    --Initialize bug database: changes size to contain all currently alive bugs
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
    spawn_bacteria(INITIAL_BACTERIA)
end

local function iterate()
    --Iterate through the bugs list and move every bug, then remove dead ones
    local dead_indexes = {}
    for bug_index = 1, #bugs do
        bugs[bug_index]:wander()
        bugs[bug_index].age = bugs[bug_index].age + 1
        bugs[bug_index].energy = bugs[bug_index].energy - MOVE_ENERGY_CONSUMPTION
        --Kill old and starving bugs
        local bug = bugs[bug_index]
        if bug.age > MAX_AGE or bug.energy <= 0 then
            insert(dead_indexes, bug_index)
        --Allow healthy, sufficiently aged bugs to reproduce if they have the space
        elseif bug.age >= REPRODUCTIVE_MIN_AGE and bug.energy >= REPRODUCTIVE_MIN_ENERGY then
            local adjacents = get_adjacents(bug.position)
            if #adjacents >= OFFSPRING then
                local offspring = 0
                repeat
                    spawn_delta = remove(adjacents, random(1, #adjacents))
                    insert(bugs, Bug:new(bug.genes, xy(bug.position.x + spawn_delta.x, bug.position.y + spawn_delta.y)))
                    offspring = offspring + 1
                until offspring == OFFSPRING
                --Bugs die after reproducing
                insert(dead_indexes, bug_index)
            end
        end
    end
    --Remove all dead bugs
    for removals = 1, #dead_indexes do
        local dead_bug = dead_indexes[1]
        local corpse = bugs[dead_bug]
        field[corpse.position.x][corpse.position.y] = CODES.EMPTY
        remove(bugs, dead_bug)
    end
    --End simulation if population dies
    if #bugs == 0 then
        return nil
    end
    --Replenish bacteria
    spawn_bacteria(BACTERIA_REPLENISH)
    return field
end

--Information necessary for visual representation
return {FIELD_X=FIELD_X,
        FIELD_Y=FIELD_Y,
        CODES=CODES,
        initialize=initialize,
        iterate=iterate}
