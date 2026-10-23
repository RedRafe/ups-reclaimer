-- Flow keys and full-load rates of the selected entities: the RateCalculator math plus the quality spread.
-- Rates are per second, positive = made, negative = used.
local constants = require('constants')

--- @alias FlowKey string "item/<name>/<quality>" or "fluid/<name>"

local rates = {}

--- @param type "item"|"fluid"
--- @param name string
--- @param quality string? items only, default "normal"
--- @return FlowKey
function rates.key(type, name, quality)
    if type == 'fluid' then
        return 'fluid/' .. name
    end
    return 'item/' .. name .. '/' .. (quality or 'normal')
end

--- @param key FlowKey
--- @return string type
--- @return string name
--- @return string quality "" for fluids
function rates.parse(key)
    return key:match('^(%a+)/([^/]+)/?(.*)$')
end

--- Rich text icon of a flow key.
--- @param key FlowKey
--- @return string
function rates.icon(key)
    local type, name, quality = rates.parse(key)
    if type == 'fluid' then
        return '[fluid=' .. name .. ']'
    end
    return '[item=' .. name .. ',quality=' .. quality .. ']'
end

local function add(flows, key, rate)
    flows[key] = (flows[key] or 0) + rate
end

local BELT_RUN = 100 -- belt entities read upstream of a border belt

--- Flow keys of every item (with quality) on a belt and up to BELT_RUN belt entities upstream of it, side-loads and
--- undergrounds included: upstream is outside for an input belt and inside for an output belt, so a sparse mixed
--- belt shows all its kinds even when the border tile holds one. Read once, at freeze.
--- @param belt LuaEntity
--- @return FlowKey[]
--- @return table<uint, true> run the belt entities read, by unit number
function rates.belt_items(belt)
    local seen, keys, queue, queued = {}, {}, { belt }, { [belt.unit_number] = true }
    local i = 1
    while queue[i] and i <= BELT_RUN do
        local entity = queue[i]
        for line = 1, entity.get_max_transport_line_index() do
            for _, stack in pairs(entity.get_transport_line(line).get_contents()) do
                local key = rates.key('item', stack.name, stack.quality)
                if not seen[key] then
                    seen[key] = true
                    keys[#keys + 1] = key
                end
            end
        end
        local upstream = entity.belt_neighbours.inputs
        local entrance = entity.type == 'underground-belt'
            and entity.belt_to_ground_type == 'output'
            and entity.underground_belt_neighbour
        if entrance then
            upstream = { entrance, table.unpack(upstream) } -- the entrance isn't a belt neighbour
        end
        for _, neighbour in pairs(upstream) do
            if not queued[neighbour.unit_number] then
                queued[neighbour.unit_number] = true
                queue[#queue + 1] = neighbour
            end
        end
        i = i + 1
    end
    return keys, queued
end

--- Recipe and recipe quality of a machine; furnaces fall back to the last recipe they ran.
--- @param machine LuaEntity
--- @return LuaRecipe?
--- @return LuaQualityPrototype
function rates.recipe_of(machine)
    local recipe, quality = machine.get_recipe()
    local previous = not recipe and machine.type == 'furnace' and machine.previous_recipe
    if previous then
        local name = type(previous.name) == 'string' and previous.name or previous.name.name
        recipe, quality = machine.force.recipes[name], previous.quality
    end
    if type(quality) == 'string' then
        quality = prototypes.quality[quality]
    end
    return recipe, quality or prototypes.quality.normal
end

--- @class QualityShare
--- @field quality string
--- @field fraction number of the products that come out at this quality

--- Expected quality spread of a machine's products, 2.1 rules: the first step up has a chance of quality effect
--- times next_probability, each further step the reached tier's chain_probability, never past the force's last
--- unlocked tier.
--- ponytail: negative quality (quality_limits) is ignored.
--- @param machine LuaEntity
--- @param quality LuaQualityPrototype of the recipe
--- @return QualityShare[]
function rates.quality_split(machine, quality)
    local effects = machine.effects
    local step_up = math.max(0, effects and effects.quality or 0) * quality.next_probability
    local split, tier, reached = {}, quality, 1
    while true do
        local next_tier = tier.next
        if not (next_tier and step_up > 0 and machine.force.is_quality_unlocked(next_tier)) then
            split[#split + 1] = { quality = tier.name, fraction = reached }
            return split
        end
        split[#split + 1] = { quality = tier.name, fraction = reached * (1 - step_up) }
        reached, tier, step_up = reached * step_up, next_tier, next_tier.chain_probability
    end
end

--- Adds a machine's full-load rates to flows. Product fluid temperatures go into temperatures.
--- @param machine LuaEntity
--- @param recipe LuaRecipe
--- @param quality LuaQualityPrototype
--- @param flows table<FlowKey, number>
--- @param temperatures table<string, number> by fluid name
function rates.add_machine(machine, recipe, quality, flows, temperatures)
    local crafts = machine.crafting_speed / recipe.energy
    local productivity = 1
        + math.min(machine.productivity_bonus + recipe.productivity_bonus, recipe.prototype.maximum_productivity)
    for _, ingredient in pairs(recipe.ingredients) do
        add(flows, rates.key(ingredient.type, ingredient.name, quality.name), -ingredient.amount * crafts)
    end
    local split = rates.quality_split(machine, quality)
    for _, product in pairs(recipe.products) do
        if product.type ~= 'research-progress' then
            -- ponytail: assumes shared_probability {min, max} is a roll window (default {0, 1}); fix if 2.1 means otherwise.
            local window = product.shared_probability
            local chance = (product.independent_probability or 1) * (window and (window.max - window.min) or 1)
            local amount = (product.amount or (product.amount_min + product.amount_max) / 2) * chance
                + (product.extra_count_fraction or 0)
            local ignored = math.min(product.ignored_by_productivity or 0, amount)
            local rate = ((amount - ignored) * productivity + ignored) * crafts
            if product.type == 'fluid' then
                add(flows, rates.key('fluid', product.name), rate)
                temperatures[product.name] = product.temperature
            else
                for _, share in pairs(split) do
                    add(flows, rates.key('item', product.name, share.quality), rate * share.fraction)
                end
            end
        end
    end
end

--- Electric power, split like the engine does: the drain is paid even when idle, the active part only while working.
--- A machine's active part carries the consumption effect of its modules and beacons, floored at -80%; a machine
--- without a recipe only drains. Beacons draw their full power all the time. A burner's full-load fuel goes into
--- flows as a used item instead.
--- Full-load emissions of the surface's pollutant: active energy times the energy source's emissions per joule, the
--- pollution effect (floored at -80%), the recipe's multiplier and, for burners, the fuel's.
--- ponytail: inserters and pumps are billed at max power while working, their real average is lower.
--- @param entity LuaEntity
--- @param flows table<FlowKey, number>
--- @param recipe LuaRecipe?
--- @return number drain_watts
--- @return number active_watts both 0 for burners and entities without power (pipes, belts...)
--- @return number emissions pollution per second at full load
function rates.add_power(entity, flows, recipe)
    local prototype = entity.prototype
    local watts = prototype.get_max_energy_usage(entity.quality) * 60
    if constants.machine_types[entity.type] then
        watts = recipe and watts * math.max(0.2, 1 + entity.consumption_bonus) or 0
    end
    local pollutant = entity.surface.pollutant_type
    local function emissions(source, multiplier)
        local per_joule = pollutant and source.emissions_per_joule[pollutant.name] or 0
        if per_joule == 0 then
            return 0 -- also skips pollution_bonus on entities without one
        end
        return watts * per_joule * math.max(0.2, 1 + entity.pollution_bonus)
            * (recipe and recipe.prototype.emissions_multiplier or 1) * multiplier
    end
    local electric = prototype.electric_energy_source_prototype
    if electric then
        local drain = (electric.drain or 0) * 60
        if entity.type == 'beacon' then
            return drain + watts, 0, 0
        end
        return drain, watts, emissions(electric, 1)
    end
    local fuel = entity.burner and entity.burner.currently_burning -- {name = LuaItemPrototype, quality = LuaQualityPrototype}
    if fuel then
        local fuel_rate = watts / prototype.burner_prototype.effectivity / fuel.name.fuel_value
        add(flows, rates.key('item', fuel.name.name, fuel.quality.name), -fuel_rate)
        return 0, 0, emissions(prototype.burner_prototype, fuel.name.fuel_emissions_multiplier)
    end
    return 0, 0, 0
end

--- Active electric power (or emissions) of a block's rows: recipe rows scale with their own utilisation, the
--- helpers row (inserters, pumps) with the recipes' average, a simple stand-in for how busy the helpers are.
--- @param rows BlockRow[]
--- @param utilisation number[] by row
--- @param field "watts"|"emissions"? default "watts"
--- @return number
function rates.active_watts(rows, utilisation, field)
    field = field or 'watts'
    local recipe_total, recipe_count = 0, 0
    for i, row in pairs(rows) do
        if row.is_recipe then
            recipe_total = recipe_total + utilisation[i]
            recipe_count = recipe_count + 1
        end
    end
    local activity = recipe_count > 0 and recipe_total / recipe_count or 0
    local watts = 0
    for i, row in pairs(rows) do
        watts = watts + (row[field] or 0) * utilisation[i] * (row.is_recipe and 1 or activity) -- or 0: blocks frozen before emissions
    end
    return watts
end

return rates
