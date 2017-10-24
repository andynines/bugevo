--[[
bugevo.lua
Copyright (c) 2017 andynines
MIT License
]]

local FIELD_X = 100
local FIELD_Y = 100
local CODES = {EMPTY=1, --Number codes indicating a certain object on a field space
               BUG=2,
               BACTERIA=3}

local INITIAL_BACTERIA = 75 --Bacteria already on the field at iteration 0
local MAX_BACTERIA = 250 --How many bacteria may exist on the field at one time
local BACTERIA_REPLENISH_WAIT = 3 --How many iterations between a new bacteria spawn
local BACTERIA_REPLENISH_QUANTITY = 1 --How many bacteria spawn upon replenishment

local INITIAL_BUGS = 10 --Bugs already on the field at iteration 0
local MAX_AGE = 1000 --Maximum iterations a bug can undergo before it dies

local INITIAL_ENERGY = 200 --Amount of energy that every bug is initialized with
local MAX_ENERGY = 1600 --Maximum amount of energy a bug can hold
local MOVE_ENERGY_CONSUMPTION = 1 --How much energy it takes a bug to undergo one iteration
local EAT_ENERGY_GAIN = 100 --How much energy a bug gains from consuming one bacteria

local REPRODUCTIVE_MIN_AGE = 400 --Minimum iterations a bug must have undergone before reproducing
local REPRODUCTIVE_MIN_ENERGY = 600 --Minimum energy level a bug must hold to reproduce
local OFFSPRING = 2 --How many offspring are created when a bug reproduces
local GENES_MUTATED = 1 --How many directions of movement are affected by mutation
local MUTATION_MAGNITUDE = 1 --Amount by which a direction probability is changed
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

math.randomseed(os.time())

local field
local bugs
local bacteria_count
local replenish_timer
local iteration

local function does_contain(list, desired_item)
    --Verifies if a value exists inside a table
    for _, current_item in ipairs(list) do
        if current_item == desired_item then
            return true
        end
    end
    return false
end

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
        local check_x, check_y = math.random(1, FIELD_X), math.random(1, FIELD_Y)
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
    for delta_index = 1, #MOVE_DELTAS do
        local current_delta = MOVE_DELTAS[delta_index]
        local check_position = xy(position.x + current_delta.x, position.y + current_delta.y)
        local border_check = within_borders(check_position)
        if (border_check.x and border_check.y) and field[check_position.x][check_position.y] == CODES.EMPTY then
            table.insert(adjacents, current_delta)
        end
    end
    return adjacents
end

local function spawn_bacteria(quantity)
    --Spawns some amount of bacteria in empty spaces on the field
    for _ = 1, quantity do
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
    local available_indexes = {}
    for add_index = 1, #genes do
        table.insert(available_indexes, add_index)
    end
    for _ = 1, math.min(GENES_MUTATED, #genes) do
        --Each directional gene can only mutate once
        local choice_index = math.random(1, #available_indexes)
        local gene_index = available_indexes[choice_index]
        local new_gene = math.floor(genes[gene_index] + MUTATION_MAGNITUDE * (-1) ^ math.random(1, 2))
        --Keep the probability within the range of 0 and the maximum
        new_gene = math.min(math.max(0, new_gene), DIRECTION_MAX_PROBABILITY)
        genes[gene_index] = new_gene
        table.remove(available_indexes, choice_index)
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
        for _ = 1, #MOVE_DELTAS do
            table.insert(self.genes, math.random(0, DIRECTION_MAX_PROBABILITY))
        end
    end
    return setmetatable(self, Bug)
end

function Bug:info()
    --Return a string of the bug's attributes
    local info = "generation ".. self.generation.. "\n"..
				 "age ".. self.age.. "\n"..
				 "energy ".. self.energy.. "\n"..
				 "location (".. self.position.x.. ", ".. self.position.y.. ")\n"
    for probability_index, probability in pairs(self.genes) do
        local current_delta = MOVE_DELTAS[probability_index]
        info = info.. "gene (".. current_delta.x.. ", ".. current_delta.y.. ") ".. probability.. "/".. DIRECTION_MAX_PROBABILITY.. "\n"
    end
    return info
end

function Bug:wander()
    --Bug chooses a random direction of travel according to its genes
    local probabilities = {}
    for direction, probability in pairs(self.genes) do
        for _ = 1, probability do
            table.insert(probabilities, direction)
        end
    end
    --Bug finds nowhere to move
    if not (#probabilities > 0) then
        return nil
    end
    local movement_delta = MOVE_DELTAS[probabilities[math.random(1, #probabilities)]]
    local new_position = xy(self.position.x + movement_delta.x, self.position.y + movement_delta.y)
    --Move to new location if possible
    local border_check = within_borders(new_position)
    if (not border_check.x) or (not border_check.y) then
        if RIGID_BORDERS then
            return nil
        else
            --Screen wrap the bug if allowed
            local field_dimensions = xy(FIELD_X, FIELD_Y)
            for _, axis in pairs({"x", "y"}) do
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
    --The bug ages
    self.age = self.age + 1
    self.energy = self.energy - MOVE_ENERGY_CONSUMPTION
    return true
end

function Bug:reproduce()
    --Spawn slightly mutated children adjacent to a bug
    local adjacents = adjacents_of(self.position)
    if #adjacents >= OFFSPRING then
        local offspring = 0
        repeat
            spawn_delta = table.remove(adjacents, math.random(1, #adjacents))
            table.insert(bugs, Bug:new(self.generation + 1,
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
    for _ = 1, INITIAL_BUGS do
        local new_bug = Bug:new()
        if new_bug then
            table.insert(bugs, new_bug)
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
end

local function iterate()
    --Iterate through the bugs list and move every bug, then remove dead ones
    local dead_indexes = {}
    for bug_index = 1, #bugs do
        bugs[bug_index]:wander()
        --Kill old and starving bugs
        local bug = bugs[bug_index]
        if bug.age > MAX_AGE or bug.energy <= 0 then
            table.insert(dead_indexes, bug_index)
        --Allow healthy, sufficiently aged bugs to reproduce if they have the space
        elseif bug.age >= REPRODUCTIVE_MIN_AGE and bug.energy >= REPRODUCTIVE_MIN_ENERGY then
            if bug:reproduce() then
                --Bugs die after reproducing
                table.insert(dead_indexes, bug_index)
            end
        end
    end
    --Create new population excluding dead bugs
    local new_bugs = {}
    for bug_index = 1, #bugs do
		if not does_contain(dead_indexes, bug_index) then
			table.insert(new_bugs, bugs[bug_index])
		else
			local dead_bug = bugs[bug_index]
			field[dead_bug.position.x][dead_bug.position.y] = CODES.EMPTY
		end
	end
    bugs = new_bugs
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
    return {field=field,
			bugs=bugs,
			iteration=iteration,
			population=#bugs}
end

--Variables and functions necessary for simulation control
return {FIELD_X=FIELD_X,
        FIELD_Y=FIELD_Y,
        CODES=CODES,
        initialize=initialize,
        iterate=iterate}
