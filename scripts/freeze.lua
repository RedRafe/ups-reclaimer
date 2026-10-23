-- Freezing and unfreezing: measures the selection, settles its steady state, swaps it for look-alikes and a
-- scripted border, and restores it on reverse-select.
local constants = require('constants')
local border = require('scripts.border')
local look_alike = require('scripts.look-alike')
local rates = require('scripts.rates')
local runtime = require('scripts.runtime')
local solver = require('scripts.solver')

local BELT_TYPES = { ['transport-belt'] = true, ['underground-belt'] = true, ['splitter'] = true }
local PIPE_TYPES = { ['pipe'] = true, ['pipe-to-ground'] = true }
local FULL_SPEED = 0.999 -- a recipe below this steady-state utilisation gets a warning
local NOISE = 1e-6 -- border rates below this (items or fluid per second) are solver rounding: 0

--- @class Crossing a belt or pipe on the selection border
--- @field entity LuaEntity
--- @field kind "input"|"output" pipes get theirs from the block's balance
--- @field keys FlowKey[]
--- @field fluid string? pipes only

--- @class BlockRow one recipe at one quality, or the row of inserters, beacons and idle machines
--- @field utilisation number steady-state share of full load
--- @field watts number active electric power at full load
--- @field emissions number pollution per second at full load
--- @field is_recipe boolean

--- @class BorderFlow one flow key crossing the border in one direction
--- @field rate number per second in the steady state
--- @field item ItemIDAndQualityIDPair? items only
--- @field carry number? items: fraction of an item owed to the next step
--- @field buffer integer? items: stock or room the step and the input loaders aim for
--- @field inventories LuaInventory[]? item inputs: one shared inventory per set of belts carrying the same items
--- @field stock number? inputs: stock read by the last step
--- @field room number? outputs: room read by the last step
--- @field fluid string? fluids only
--- @field temperature number? fluid outputs: temperature made inside
--- @field ports LuaEntity[]? fluids: one port per fluid segment
--- @field segments table<uint, true>? fluids: segment ids already covered by a port

--- @class Feed the loader of one input belt
--- @field loader LuaEntity
--- @field chest LuaEntity its buffer chest
--- @field keys FlowKey[] what the belt carries
--- @field decider LuaEntity? mixed belts: gates the loader on all its items

--- @class Block a frozen subfactory
--- @field id integer
--- @field surface uint surface index
--- @field box BoundingBox reverse-selecting into it unfreezes the block
--- @field watts number steady-state electric power, idle_watts included
--- @field idle_watts number drains and beacons, paid even when stalled
--- @field rows BlockRow[]
--- @field flow_index FlowIndex rows by flow key, see scripts/solver.lua
--- @field inputs table<FlowKey, BorderFlow>
--- @field outputs table<FlowKey, BorderFlow>
--- @field feeds Feed[] input loaders, wired to their chest by runtime.start
--- @field input_link_ids table<string, uint> by a belt's sorted flow keys: shared by belts carrying the same items
--- @field output_link_id uint shared by all output buffer chests
--- @field output_inventory LuaInventory?
--- @field power_interface LuaEntity?
--- @field look_alikes LuaEntity[]
--- @field icons LuaEntity[]? recipe and module icon and inserter arm entities; nil in blocks frozen before they existed
--- @field border_entities LuaEntity[] linked belts and ports on the factory surface
--- @field mock_entities LuaEntity[] buffer chests, loaders and linked belts on the mock surface
--- @field snapshots Snapshot[] what unfreezing rebuilds
--- @field wait integer ticks until the next step
--- @field step_joules number active energy of a steady-state step
--- @field is_productive boolean some recipe runs at the steady state
--- @field step_pollution number? pollution of a steady-state step

--- @param player LuaPlayer
--- @param message LocalisedString
local function say(player, message)
    player.print({ 'upsr-message.chat', message })
end

--- @param entity LuaEntity
--- @return string map link
local function gps(entity)
    return string.format('[gps=%s,%s,%s]', entity.position.x, entity.position.y, entity.surface.name)
end

--- True if any fluidbox of the entity connects to an entity outside the selection.
--- @param entity LuaEntity
--- @param selected table<uint, true> by unit number
local function connects_outside(entity, selected)
    for i = 1, entity.fluids_count do
        for _, neighbour in pairs(entity.get_fluid_box_neighbours(i) or {}) do
            if not selected[neighbour.entity.unit_number] then
                return true
            end
        end
    end
    return false
end

--- Adds to keys the item products of the machines whose inserters drop onto the belt run, so an output belt gets
--- what is made for it even when it is still empty or sparse.
--- ponytail: inserter filters are ignored; read them if a filtered inserter ever puts a wrong item on a belt.
--- @param run table<uint, true> belt entities by unit number
--- @param keys FlowKey[]
local function add_inserted_products(entities, run, keys)
    local seen = {}
    for _, key in pairs(keys) do
        seen[key] = true
    end
    for _, entity in pairs(entities) do
        local target = entity.type == 'inserter' and entity.drop_target
        local machine = target and run[target.unit_number] and entity.pickup_target
        if machine and constants.machine_types[machine.type] then
            local recipe, quality = rates.recipe_of(machine)
            for _, product in pairs(recipe and recipe.products or {}) do
                if product.type == 'item' then
                    for _, share in pairs(rates.quality_split(machine, quality)) do
                        local key = rates.key('item', product.name, share.quality)
                        if not seen[key] then
                            seen[key] = true
                            keys[#keys + 1] = key
                        end
                    end
                end
            end
        end
    end
end

--- Step 1: belts and pipes crossing the selection border.
--- @return Crossing[] crossings
--- @return table<uint, true> is_crossing by unit number
local function find_crossings(entities, selected, errors)
    local crossings, is_crossing = {}, {}
    for _, entity in pairs(entities) do
        local is_machine = constants.machine_types[entity.type]
        if PIPE_TYPES[entity.type] or entity.fluids_count > 0 and not is_machine then
            if connects_outside(entity, selected) then
                local fluid = PIPE_TYPES[entity.type] and entity.get_fluid_segment_fluid(1)
                if not PIPE_TYPES[entity.type] then
                    errors[#errors + 1] = { 'upsr-message.border-not-plain-pipe', entity.name, gps(entity) }
                elseif not fluid then
                    errors[#errors + 1] = { 'upsr-message.empty-border-pipe', gps(entity) }
                else
                    crossings[#crossings + 1] =
                        { entity = entity, keys = { rates.key('fluid', fluid.name) }, fluid = fluid.name }
                    is_crossing[entity.unit_number] = true
                end
            end
        elseif is_machine and connects_outside(entity, selected) then
            errors[#errors + 1] = { 'upsr-message.machine-on-outside-pipe', entity.name, gps(entity) }
        elseif BELT_TYPES[entity.type] then
            local neighbours, outer_input, outer_output = entity.belt_neighbours, nil, nil
            for _, neighbour in pairs(neighbours.inputs) do
                if not selected[neighbour.unit_number] then
                    outer_input = neighbour
                end
            end
            for _, neighbour in pairs(neighbours.outputs) do
                if not selected[neighbour.unit_number] then
                    outer_output = neighbour
                end
            end
            -- An underground's pair isn't a belt neighbour. A pair outside makes that outer end the border tile: a
            -- linked belt can't pair with the inner end.
            local tile, pair = entity, entity.type == 'underground-belt' and entity.underground_belt_neighbour
            if pair and not selected[pair.unit_number] then
                tile = pair
                if entity.belt_to_ground_type == 'output' then
                    outer_input = pair
                else
                    outer_output = pair
                end
            end
            if outer_input or outer_output then
                local keys, run = rates.belt_items(tile)
                if outer_output and not outer_input then
                    add_inserted_products(entities, run, keys)
                end
                if entity.type == 'splitter' then
                    errors[#errors + 1] = { 'upsr-message.border-not-plain-belt', entity.name, gps(entity) }
                elseif outer_input and outer_output then
                    errors[#errors + 1] = { 'upsr-message.belt-crosses-border', gps(entity) }
                elseif #keys == 0 then
                    errors[#errors + 1] = { 'upsr-message.empty-border-belt', gps(entity) }
                elseif #keys > constants.loader_filters then
                    errors[#errors + 1] = { 'upsr-message.too-many-belt-kinds', constants.loader_filters, gps(entity) }
                else
                    crossings[#crossings + 1] =
                        { entity = tile, kind = outer_input and 'input' or 'output', keys = keys }
                    is_crossing[tile.unit_number] = true
                end
            end
        end
    end
    return crossings, is_crossing
end

--- @class MeasuredRow
--- @field flows table<FlowKey, number> full-load rates
--- @field watts number full-load active electric power
--- @field emissions number full-load pollution per second
--- @field recipe string?
--- @field quality string?

--- Step 2: full-load rates and power of what gets replaced, one row per recipe and quality ("" gathers inserters,
--- beacons and idle machines). Entities kept real stay out.
--- @param is_kept fun(entity: LuaEntity): boolean
--- @return table<string, MeasuredRow> rows
--- @return table<string, number> temperatures of fluids made inside
--- @return integer machines with a recipe
--- @return MapPosition? power_position where the power interface goes
--- @return number idle_watts drains and beacons, paid all the time
local function measure(entities, is_kept, warnings)
    local rows, temperatures, machines, power_position, idle_watts = {}, {}, 0, nil, 0
    for _, entity in pairs(entities) do
        if not is_kept(entity) and not look_alike.name(entity) then
            warnings[#warnings + 1] = { 'upsr-message.no-static-graphics', entity.name, gps(entity) }
        elseif not is_kept(entity) then
            local recipe, quality
            if constants.machine_types[entity.type] then
                recipe, quality = rates.recipe_of(entity)
            end
            local row_key = recipe and recipe.name .. '/' .. quality.name or ''
            local row = rows[row_key]
            if not row then
                row = {
                    flows = {},
                    watts = 0,
                    emissions = 0,
                    recipe = recipe and recipe.name,
                    quality = quality and quality.name,
                }
                rows[row_key] = row
            end
            if recipe then
                machines = machines + 1
                rates.add_machine(entity, recipe, quality, row.flows, temperatures)
            end
            local drain_watts, active_watts, emissions = rates.add_power(entity, row.flows, recipe)
            row.watts = row.watts + active_watts
            row.emissions = row.emissions + emissions
            idle_watts = idle_watts + drain_watts
            if drain_watts + active_watts > 0 and not power_position then
                power_position = entity.position
            end
        end
    end
    return rows, temperatures, machines, power_position, idle_watts
end

--- Any number of belts may cross; only distinct output item kinds are bounded, by the shared output chest. Each
--- input belt has its own chest.
local function check_output_kinds(crossings, off, errors)
    local kinds = {}
    for _, crossing in pairs(crossings) do
        if crossing.kind == 'output' and not crossing.fluid then
            for _, key in pairs(crossing.keys) do
                kinds[key] = not off['outputs ' .. key] or nil
            end
        end
    end
    if table_size(kinds) > constants.output_buffer_slots then
        errors[#errors + 1] = { 'upsr-message.too-many-output-kinds', constants.output_buffer_slots }
    end
end

--- Step 3: settle at the steady state the real block reaches, where internal shortages and surpluses slow recipes
--- down. Pipes have no direction, so a border fluid may go either way; its net balance picks the side afterwards.
--- A flow the player switched off crosses at 0: its producers back up, its consumers starve.
--- @param rows table<string, MeasuredRow>
--- @param off table<string, true> "inputs <key>" or "outputs <key>"
--- @return table<FlowKey, number> net steady-state rates
--- @return BlockRow[] block_rows
--- @return FlowIndex index
local function settle(crossings, rows, off, warnings)
    local supply, sink = {}, {}
    for _, crossing in pairs(crossings) do
        for _, key in pairs(crossing.keys) do
            -- A fluid's side is only known after settling: switching either side off closes it.
            local fluid_off = crossing.fluid and (off['inputs ' .. key] or off['outputs ' .. key])
            if crossing.fluid or crossing.kind == 'input' then
                supply[key] = not (fluid_off or off['inputs ' .. key]) and math.huge or nil
            end
            if crossing.fluid or crossing.kind == 'output' then
                sink[key] = not (fluid_off or off['outputs ' .. key]) and math.huge or nil
            end
        end
    end
    local ordered, flows, utilisation, limits = {}, {}, {}, {}
    for _, row in pairs(rows) do
        ordered[#ordered + 1] = row
        flows[#flows + 1] = row.flows
        utilisation[#utilisation + 1] = 1
    end
    local index = solver.index(flows)
    solver.solve(utilisation, index, supply, sink, limits)

    local net, block_rows = {}, {}
    for i, row in pairs(ordered) do
        for key, rate in pairs(row.flows) do
            net[key] = (net[key] or 0) + rate * utilisation[i]
        end
        block_rows[i] = {
            utilisation = utilisation[i],
            watts = row.watts,
            emissions = row.emissions,
            is_recipe = row.recipe ~= nil,
        }
        if row.recipe and utilisation[i] < FULL_SPEED then
            local percent = math.floor(utilisation[i] * 100)
            warnings[#warnings + 1] =
                { 'upsr-message.recipe-throttled', row.recipe, row.quality, percent, rates.icon(limits[i]) }
        end
    end
    for _, crossing in pairs(crossings) do
        if crossing.fluid then
            crossing.kind = (net[crossing.keys[1]] or 0) < 0 and 'input' or 'output'
        end
    end
    return net, block_rows, index
end

--- Step 4: one border flow per flow key and direction, at its steady-state rate.
local function add_border_flows(block, crossings, net, temperatures, off, warnings)
    for _, crossing in pairs(crossings) do
        local is_input = crossing.kind == 'input'
        local side = is_input and 'inputs' or 'outputs'
        local flows = block[side]
        for _, key in pairs(crossing.keys) do
            if not flows[key] then
                local rate = (is_input and -1 or 1) * (net[key] or 0)
                if rate < NOISE or off[side .. ' ' .. key] then
                    rate = 0
                end
                if crossing.fluid then
                    local fluid = crossing.fluid
                    flows[key] =
                        { rate = rate, fluid = fluid, temperature = temperatures[fluid], ports = {}, segments = {} }
                else
                    local _, name, quality = rates.parse(key)
                    flows[key] =
                        { rate = rate, item = { name = name, quality = quality }, inventories = is_input and {} or nil }
                end
                if rate == 0 and not off[side .. ' ' .. key] then
                    local message = crossing.fluid and 'upsr-message.unused-border-fluid'
                        or 'upsr-message.unused-border-item'
                    warnings[#warnings + 1] = { message, rates.icon(key) }
                end
            end
        end
    end
end

--- Step 5: replace the selection with look-alikes and the border with linked belts and ports.
local function swap(block, surface, entities, is_kept, crossings)
    -- Plan the look-alikes before destroying anything: belt shapes and pipe connections need the neighbours.
    local specs, replaced = {}, {}
    for _, entity in pairs(entities) do
        local name = not is_kept(entity) and look_alike.name(entity)
        if name then
            specs[#specs + 1] = {
                name = name,
                position = entity.position,
                direction = entity.direction, -- turns the boxes; the picture comes from the variation
                force = entity.force,
                variation = look_alike.variation(entity), -- set after create
            }
            block.snapshots[#block.snapshots + 1] = look_alike.snapshot(entity)
            replaced[#replaced + 1] = entity
        end
    end
    for _, crossing in pairs(crossings) do
        block.snapshots[#block.snapshots + 1] = look_alike.snapshot(crossing.entity)
    end

    for _, entity in pairs(replaced) do
        entity.destroy()
    end
    for i, spec in pairs(specs) do
        local copy = surface.create_entity(spec)
        if copy then
            copy.graphics_variation = spec.variation -- create_entity doesn't take it
            copy.destructible = false
            copy.rotatable = false
            block.look_alikes[#block.look_alikes + 1] = copy
            -- snapshots[i] is the entity specs[i] replaces
            for _, icon in pairs(look_alike.place_icons(copy, block.snapshots[i])) do
                block.icons[#block.icons + 1] = icon
            end
            block.icons[#block.icons + 1] = look_alike.place_arm(copy, block.snapshots[i])
        end
    end
    storage.mock_column = storage.mock_column + 2 -- a bare lab column between two blocks' concrete
    local first_column = storage.mock_column + 1
    for _, crossing in pairs(crossings) do
        if crossing.fluid then
            border.connect_pipe(block, crossing)
        else
            border.connect_belt(block, crossing)
        end
    end
    border.pave(first_column)
end

--- Electric interface drawing at most the block's steady-state power. The engine bills the idle part every tick
--- through power_usage; each step adds the active part it ran on.
local function add_power_interface(block, surface, position, force)
    if block.watts <= 0 or not position then
        return
    end
    local interface = surface.create_entity({ name = constants.power_interface, position = position, force = force })
    interface.destructible = false
    interface.power_usage = block.idle_watts / 60
    interface.input_flow_limit = block.watts / 60
    block.power_interface = interface
end

--- @param snapshots Snapshot[]
--- @return BoundingBox
local function bounding_box(snapshots)
    local left, top, right, bottom = math.huge, math.huge, -math.huge, -math.huge
    for _, snapshot in pairs(snapshots) do
        left, top = math.min(left, snapshot.position.x), math.min(top, snapshot.position.y)
        right, bottom = math.max(right, snapshot.position.x), math.max(bottom, snapshot.position.y)
    end
    return { left_top = { x = left - 1.5, y = top - 1.5 }, right_bottom = { x = right + 1.5, y = bottom + 1.5 } }
end

--- @param flows table<FlowKey, BorderFlow>
--- @return string rich text list of icons and rates
local function flow_list(flows)
    local parts = {}
    for key, flow in pairs(flows) do
        parts[#parts + 1] = rates.icon(key) .. ' ' .. string.format('%.2f/s', flow.rate)
    end
    return table.concat(parts, ', ')
end

local freeze = {}

--- @class Plan steps 1 to 4, read from the map without changing it: what the panel previews and freezing builds
--- @field errors LocalisedString[] anything here blocks the freeze, and the other fields are missing
--- @field warnings LocalisedString[]
--- @field inputs table<FlowKey, BorderFlow>
--- @field outputs table<FlowKey, BorderFlow>

--- @param selection Selection
--- @return Plan
function freeze.plan(selection)
    local surface = game.surfaces[selection.surface]
    local selected, entities = {}, {}
    for unit_number, entity in pairs(selection.entities) do
        if entity.valid then
            selected[unit_number] = true
            entities[#entities + 1] = entity
        end
    end
    local errors, warnings = {}, {}
    local crossings, is_crossing = find_crossings(entities, selected, errors)
    local function is_kept(entity)
        return is_crossing[entity.unit_number] or selection.kept[entity.name] or false
    end
    local rows, temperatures, machines, power_position, idle_watts = measure(entities, is_kept, warnings)
    if machines == 0 then
        errors[#errors + 1] = { 'upsr-message.no-machines' }
    end
    if #crossings == 0 then
        errors[#errors + 1] = { 'upsr-message.no-border' }
    end
    check_output_kinds(crossings, selection.off, errors)
    if #errors > 0 then
        return { errors = errors }
    end

    local net, block_rows, index = settle(crossings, rows, selection.off, warnings)
    local plan = {
        errors = errors,
        warnings = warnings,
        surface = surface,
        entities = entities,
        is_kept = is_kept,
        crossings = crossings,
        power_position = power_position,
        idle_watts = idle_watts,
        rows = block_rows,
        index = index,
        inputs = {},
        outputs = {},
    }
    add_border_flows(plan, crossings, net, temperatures, selection.off, warnings)
    return plan
end

--- Item outputs at 0 (switched off, or nothing left over) leave the block: no flow to move, no loader filter. A
--- belt left with none gets no loader.
--- @param plan Plan
local function drop_idle_outputs(plan)
    for key, flow in pairs(plan.outputs) do
        if flow.item and flow.rate == 0 then
            plan.outputs[key] = nil
        end
    end
    for _, crossing in pairs(plan.crossings) do
        if crossing.kind == 'output' and not crossing.fluid then
            local keys = {}
            for _, key in pairs(crossing.keys) do
                keys[#keys + 1] = plan.outputs[key] and key or nil
            end
            crossing.keys = keys
        end
    end
end

--- Replaces the selection with look-alikes and a scripted border. Problems are reported in chat.
--- @param player LuaPlayer
--- @param selection Selection
--- @return boolean frozen
function freeze.freeze(player, selection)
    local plan = freeze.plan(selection)
    if #plan.errors > 0 then
        for _, message in pairs(plan.errors) do
            say(player, { 'upsr-message.cannot-freeze', message })
        end
        return false
    end

    drop_idle_outputs(plan)
    local surface, warnings, idle_watts, block_rows = plan.surface, plan.warnings, plan.idle_watts, plan.rows
    local steady = {}
    for i, row in pairs(block_rows) do
        steady[i] = row.utilisation
    end
    local watts = idle_watts + rates.active_watts(block_rows, steady)
    storage.next_block_id = storage.next_block_id + 1
    storage.next_link_id = storage.next_link_id + 1
    --- @type Block
    local block = {
        id = storage.next_block_id,
        surface = surface.index,
        watts = watts,
        idle_watts = idle_watts,
        rows = block_rows,
        flow_index = plan.index,
        inputs = plan.inputs,
        outputs = plan.outputs,
        feeds = {},
        input_link_ids = {},
        output_link_id = storage.next_link_id,
        look_alikes = {},
        icons = {},
        border_entities = {},
        mock_entities = {},
        snapshots = {},
    }
    swap(block, surface, plan.entities, plan.is_kept, plan.crossings)
    add_power_interface(block, surface, plan.power_position, player.force)
    block.box = bounding_box(block.snapshots)
    storage.blocks[block.id] = block
    runtime.start(block)

    for _, message in pairs(warnings) do
        say(player, { 'upsr-message.warning', message })
    end
    say(player, {
        'upsr-message.frozen',
        #block.look_alikes,
        string.format('%.1f', watts / 1000),
        string.format('%.1f', idle_watts / 1000),
        flow_list(block.inputs),
        flow_list(block.outputs),
    })
    return true
end

--- @param block Block
local function unfreeze(block)
    for _, entities in pairs({ block.look_alikes, block.icons or {}, block.border_entities, block.mock_entities }) do
        for _, entity in pairs(entities) do
            if entity.valid then
                entity.destroy()
            end
        end
    end
    if block.power_interface and block.power_interface.valid then
        block.power_interface.destroy()
    end
    local surface = game.surfaces[block.surface]
    for _, snapshot in pairs(block.snapshots) do
        look_alike.restore(surface, snapshot)
    end
    storage.blocks[block.id] = nil -- its scheduled steps find nothing and lapse
end

--- @param box BoundingBox
--- @param area BoundingBox
local function overlaps(box, area)
    return box.left_top.x <= area.right_bottom.x
        and area.left_top.x <= box.right_bottom.x
        and box.left_top.y <= area.right_bottom.y
        and area.left_top.y <= box.right_bottom.y
end

--- @param event EventData.on_player_reverse_selected_area
local function on_player_reverse_selected_area(event)
    if event.item ~= constants.tool then
        return
    end
    local count = 0
    for _, block in pairs(storage.blocks) do
        if block.surface == event.surface.index and overlaps(block.box, event.area) then
            unfreeze(block)
            count = count + 1
        end
    end
    local player = game.get_player(event.player_index)
    if player and count > 0 then
        say(player, { 'upsr-message.unfrozen', count })
    end
end

local function init()
    storage.blocks = storage.blocks or {} -- id -> Block
    storage.next_block_id = storage.next_block_id or 0
    storage.next_link_id = storage.next_link_id or 0 -- linked container link_id counter
end

freeze.on_init = init
freeze.on_configuration_changed = init
freeze.events = {
    [defines.events.on_player_reverse_selected_area] = on_player_reverse_selected_area,
}

return freeze
