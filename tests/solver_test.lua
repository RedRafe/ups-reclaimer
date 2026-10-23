-- Run with any Lua 5.2+ from the mod folder: lua tests/solver_test.lua
local solver = dofile('scripts/solver.lua')

local INFINITE = math.huge
local SUPPLY = {
    copper = INFINITE,
    iron = INFINITE,
    water = INFINITE,
}
local SINK = {
    circuit = INFINITE,
    water = INFINITE,
    gear = INFINITE,
    pipe = INFINITE,
}

local function assert_near(actual, expected)
    assert(math.abs(actual - expected) < 1e-6, actual .. ' ~= ' .. expected)
end

local function full_load(flows)
    local utilisation = {}
    for row in pairs(flows) do
        utilisation[row] = 1
    end
    return utilisation
end

-- Steady state at freeze: unlimited border, starting at full load.
local function steady(flows)
    local utilisation, limits = full_load(flows), {}
    solver.solve(utilisation, solver.index(flows), SUPPLY, SINK, limits)
    return utilisation, limits
end

-- Runtime throttle, starting at full load.
local function throttled(flows, supply, sink)
    local utilisation = full_load(flows)
    solver.solve(utilisation, solver.index(flows), supply, sink)
    return utilisation
end

-- 2 cable machines (6 cable/s) feed circuits that could eat 9/s: circuits settle at 2/3.
local utilisation, limits =
    steady({ {
        copper = -3,
        cable = 6,
    }, {
        cable = -9,
        iron = -3,
        circuit = 3,
    } })
assert_near(utilisation[1], 1)
assert_near(utilisation[2], 2 / 3)
assert(limits[2] == 'cable')

-- 4 cable machines (12/s) for 9/s of demand: cables back up to 3/4.
utilisation = steady({ {
    copper = -6,
    cable = 12,
}, {
    cable = -9,
    iron = -3,
    circuit = 3,
} })
assert_near(utilisation[1], 0.75)
assert_near(utilisation[2], 1)

-- Two-level shortage propagates: plate -> gear (half enough) -> circuit.
utilisation = steady({ {
    iron = -4,
    gear = 2,
}, {
    gear = -4,
    iron = -2,
    circuit = 4,
} })
assert_near(utilisation[2], 0.5)

-- A byproduct with no exit stalls its producer; a border fluid (in and out) is free.
utilisation =
    steady({ {
        iron = -1,
        circuit = 1,
        slag = 1,
    }, {
        water = -10,
        iron = -1,
        circuit = 1,
    } })
assert_near(utilisation[1], 0)
assert_near(utilisation[2], 1)

-- Quality keys are separate flows: rare circuits with no exit back up their producer.
utilisation, limits = steady({
    {
        iron = -2,
        ['circuit/rare'] = 1,
        ['circuit/normal'] = 1,
    },
    {
        ['circuit/normal'] = -1,
        circuit = 1,
    },
})
assert_near(utilisation[1], 0)
assert(limits[1] == 'circuit/rare')

-- Two lines sharing nothing: the gear output is blocked, the circuit line runs on.
utilisation = throttled({ {
    iron = -2,
    gear = 1,
}, {
    copper = -3,
    circuit = 1,
} }, SUPPLY, {
    gear = 0,
    circuit = INFINITE,
})
assert_near(utilisation[1], 0)
assert_near(utilisation[2], 1)

-- Shared short input (iron 3/s of 6/s): split evenly, but blocked gears leave the pipes all of it.
local shared_iron = { {
    iron = -4,
    gear = 2,
}, {
    iron = -2,
    pipe = 2,
} }
utilisation = throttled(shared_iron, {
    iron = 3,
}, SINK)
assert_near(utilisation[1], 0.5)
assert_near(utilisation[2], 0.5)
utilisation = throttled(shared_iron, {
    iron = 3,
}, {
    gear = 0,
    pipe = INFINITE,
})
assert_near(utilisation[1], 0)
assert_near(utilisation[2], 1)

-- Mirror: shared full output (gear sink 2/s), a starved line leaves the other line the room.
utilisation = throttled({ {
    iron = -1,
    gear = 2,
}, {
    copper = -1,
    gear = 2,
} }, {
    iron = 0,
    copper = INFINITE,
}, {
    gear = 2,
})
assert_near(utilisation[1], 0)
assert_near(utilisation[2], 1)

-- Chain behind a shared input: the iron -> cable -> circuit line keeps running when the gear output is blocked.
utilisation = throttled(
    { {
        iron = -4,
        gear = 2,
    }, {
        iron = -2,
        cable = 4,
    }, {
        cable = -4,
        circuit = 2,
    } },
    {
        iron = 2,
    },
    {
        gear = 0,
        circuit = INFINITE,
    }
)
assert_near(utilisation[1], 0)
assert_near(utilisation[2], 1)
assert_near(utilisation[3], 1)

-- Shared intermediate, one consumer held back elsewhere: the other gets the rest of the gears, and the gear maker
-- doesn't back up. Plain down-scaling halved A when it met the gears before the y shortage.
utilisation = steady({
    { iron = -2, gear = 2 },
    { gear = -2, circuit = 1 },
    { gear = -2, y = -2, pipe = 1 },
    { y = 0.2 },
})
assert_near(utilisation[1], 1)
assert_near(utilisation[2], 0.9)
assert_near(utilisation[3], 0.1)
assert_near(utilisation[4], 1)

print('solver ok')
