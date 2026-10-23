-- Steady state of a frozen block. Pure Lua, no game API (tested by tests/solver_test.lua).
-- Rows are recipes (array index), utilisation[row] their share of full load; keys are opaque flows (items with
-- quality, fluids). Settles rows the way the real block does: consumers of a key can't use more than is made inside
-- plus what the border supplies, producers back up when nothing inside or the border sink takes their surplus.
-- Independent lines touch disjoint keys, so throttling one never slows the other.
-- ponytail: fixed-point iteration, at most MAX_PASSES; tangled loops that don't settle by then fall back to
-- proportional scaling, which balances every key but may under-run. An LP is the upgrade if that shows up.
local EPSILON = 1e-9
local MAX_PASSES = 100

--- @alias FlowRates table<string, number> per second at full load by flow key, + made, - used

--- @class FlowIndexEntry
--- @field rows integer[] rows that make or use the key
--- @field rates number[] their rate of the key at full load, same order

--- @alias FlowIndex table<string, FlowIndexEntry>

local solver = {}

--- Built once at freeze; row indices instead of row tables keep it safe to store.
--- @param flows FlowRates[] by row
--- @return FlowIndex
function solver.index(flows)
    local index = {}
    for row, rates in pairs(flows) do
        for key, rate in pairs(rates) do
            local entry = index[key]
            if not entry then
                entry = { rows = {}, rates = {} }
                index[key] = entry
            end
            entry.rows[#entry.rows + 1] = row
            entry.rates[#entry.rates + 1] = rate
        end
    end
    return index
end

--- Scales utilisation down until every key balances. Only ever lowers rows, so a cut made early sticks even when
--- its cause goes away: solve's last resort, never the answer on its own.
local function balance(utilisation, index, supply, sink, limits)
    for _ = 1, MAX_PASSES do
        local changed = false
        for key, entry in pairs(index) do
            local rows, rates, made, used = entry.rows, entry.rates, 0, 0
            for i = 1, #rows do
                local rate = rates[i] * utilisation[rows[i]]
                if rate > 0 then
                    made = made + rate
                else
                    used = used - rate
                end
            end
            local available, room = made + (supply[key] or 0), used + (sink[key] or 0)
            local side, scale
            if used > available + EPSILON * (used + 1) then
                side, scale = -1, available / used -- consumers share what is made and supplied
            elseif made > room + EPSILON * (made + 1) then
                side, scale = 1, room / made -- producers back up
            end
            if side then
                changed = true
                for i = 1, #rows do
                    if rates[i] * side > 0 then
                        local row = rows[i]
                        utilisation[row] = utilisation[row] * scale
                        if limits then
                            limits[row] = key
                        end
                    end
                end
            end
        end
        if not changed then
            return
        end
    end
end

--- Water-filling: the level where sum(weight * min(cap, level)) reaches total. Rows share a key evenly by
--- utilisation, and a row held below the level by its other keys leaves the rest of its share to the others.
--- @return number level math.huge when every row gets its cap
local function fill(total, weights, caps)
    local wanted, weight, order = 0, 0, {}
    for i = 1, #caps do
        wanted, weight, order[i] = wanted + weights[i] * caps[i], weight + weights[i], i
    end
    if wanted <= total then
        return math.huge
    end
    table.sort(order, function(a, b)
        return caps[a] < caps[b]
    end)
    local filled = 0
    for _, i in ipairs(order) do
        if filled + weight * caps[i] > total then
            return (total - filled) / weight
        end
        filled, weight = filled + weights[i] * caps[i], weight - weights[i]
    end
    return math.huge
end

--- Steady state at freeze and runtime throttle. Each row runs at the lowest level its keys allow, capped by its
--- utilisation going in. A key splits what its producers offer (plus supply) among its consumers, and what its
--- consumers take (plus sink) among its producers, judging each row by its cap from its other keys: a consumer
--- slowed elsewhere frees its share of a short input, and a producer backs up only for consumers that really are
--- slowed. Levels are recomputed from scratch each pass, so a row recovers when what cut it goes away.
--- @param utilisation number[] by row: caps in (1 at freeze, the cached steady state at runtime), result out
--- @param index FlowIndex
--- @param supply table<string, number> per second the border can bring in (nil = 0, math.huge = unlimited)
--- @param sink table<string, number> per second the border can take out (nil = 0, math.huge = unlimited)
--- @param limits table<integer, string>? gets the key that holds each slowed row back
function solver.solve(utilisation, index, supply, sink, limits)
    local cap, levels = {}, {} -- levels[key][i]: what key allowed row entry.rows[i] last pass
    for row, value in pairs(utilisation) do
        cap[row] = value
    end
    for key, entry in pairs(index) do
        levels[key] = {}
        for i = 1, #entry.rows do
            levels[key][i] = math.huge
        end
    end
    -- Each row's lowest level, its key and the second lowest, so a key can read a row's cap from its other keys.
    local low, low_key, second
    local function scan()
        low, low_key, second = {}, {}, {}
        for key, entry in pairs(index) do
            for i, row in ipairs(entry.rows) do
                local level, lowest = levels[key][i], low[row] or math.huge
                if level < lowest then
                    low[row], low_key[row], second[row] = level, key, lowest
                elseif level < (second[row] or math.huge) then
                    second[row] = level
                end
            end
        end
    end
    local function other(row, key)
        return math.min(cap[row], low_key[row] == key and second[row] or low[row] or math.huge)
    end
    for _ = 1, MAX_PASSES do
        scan()
        local next_levels, changed = {}, false
        for key, entry in pairs(index) do
            local rows, rates = entry.rows, entry.rates
            local offer, take = supply[key] or 0, sink[key] or 0
            local made_weights, made_caps, used_weights, used_caps = {}, {}, {}, {}
            for i = 1, #rows do
                local rate, row_cap = rates[i], other(rows[i], key)
                if rate > 0 then
                    offer = offer + rate * row_cap
                    made_weights[#made_weights + 1], made_caps[#made_caps + 1] = rate, row_cap
                else
                    take = take - rate * row_cap
                    used_weights[#used_weights + 1], used_caps[#used_caps + 1] = -rate, row_cap
                end
            end
            local made_level, used_level = fill(take, made_weights, made_caps), fill(offer, used_weights, used_caps)
            local new, old = {}, levels[key]
            for i = 1, #rows do
                new[i] = rates[i] > 0 and made_level or used_level
                if math.abs(new[i] - old[i]) > EPSILON then -- huge - huge is nan: unchanged
                    changed = true
                end
            end
            next_levels[key] = new
        end
        levels = next_levels
        if not changed then
            break
        end
    end
    scan()
    for row, value in pairs(cap) do
        if (low[row] or math.huge) < value then
            utilisation[row] = low[row]
            if limits then
                limits[row] = low_key[row]
            end
        end
    end
    balance(utilisation, index, supply, sink, limits) -- no-op once settled
end

return solver
