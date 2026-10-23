-- Turns the belts and pipes on the selection border into the frozen block's inputs and outputs.
-- Belts link to a hidden mock surface (linked belt, loader, shared buffer chest); pipes become ports that stay in
-- the outer fluid segment.
local constants = require('constants')

local border = {}

local function mock_surface(force)
    local surface = game.surfaces[constants.mock_surface]
    if not surface then
        surface = game.create_surface(constants.mock_surface)
        surface.generate_with_lab_tiles = true
    end
    force.set_surface_hidden(surface, true)
    return surface
end

--- Border linked belt; its direction is the direction items flow, for both types.
local function linked_belt(name, surface, position, direction, type, force)
    local belt = surface.create_entity({ name = name, position = position, force = force })
    belt.linked_belt_type = type -- not a create_entity option
    belt.direction = direction -- after the type: setting the type turns the belt around
    return belt
end

--- Centre of a mock surface tile.
--- @return MapPosition
local function tile(column, row)
    return { x = column + 0.5, y = row + 0.5 }
end

--- True for an output belt with two items that each fit one lane of it: they get a lane each.
--- @param block Block
--- @param crossing Crossing
local function splits_lanes(block, crossing)
    if crossing.kind ~= 'output' or #crossing.keys ~= 2 then
        return false
    end
    local lane = crossing.entity.prototype.belt_speed * 240 -- items per second: 60 ticks, 4 items per tile and lane
    return block.outputs[crossing.keys[1]].rate <= lane and block.outputs[crossing.keys[2]].rate <= lane
end

--- Border belt -> linked belt pair -> mock surface column: linked belt, loader, buffer chest, and for a mixed input
--- belt a decider beside them; runtime.start wires the input loaders. An output belt whose two items each fit a lane
--- gets one loader per item instead, side-loading from both sides onto a belt, so each item keeps its own lane.
--- @param block Block
--- @param crossing Crossing
function border.connect_belt(block, crossing)
    local belt, is_input = crossing.entity, crossing.kind == 'input'
    local surface, force, position, direction = belt.surface, belt.force, belt.position, belt.direction
    local outer_name = belt.type == 'underground-belt' and constants.linked_underground or constants.linked_belt
    local is_split = splits_lanes(block, crossing)
    belt.destroy()
    -- Items enter the outer link of an input and leave the outer link of an output.
    local outer_link = linked_belt(outer_name, surface, position, direction, is_input and 'input' or 'output', force)
    outer_link.destructible = false

    local mock = mock_surface(force)
    local is_mixed_input = is_input and #crossing.keys > 1
    local x = storage.mock_column + (is_split and 4 or 1)
    storage.mock_column = x + (is_split and 4 or is_mixed_input and 2 or 1) -- one spare column between belts
    mock.request_to_generate_chunks({ x, 0 }, 1)
    mock.force_generate_chunk_requests()
    -- Column x, top to bottom: chest (row -1), 1x2 loader (rows 0-1, belt end at row 1), linked belt (row 2).
    -- Input items flow north into the chest, output items south out of it.
    -- Split: row 1 is a belt fed from the west by a loader (columns x-2, x-1) and its chest (x-3), and from the east
    -- by a loader (x+1, x+2) and its chest (x+3).
    local flow_direction = is_input and defines.direction.north or defines.direction.south
    local ends = {
        { chest = tile(x, -1), loader = { x = x + 0.5, y = 1 }, direction = flow_direction, keys = crossing.keys },
    }
    if #crossing.keys == 0 then
        ends = {} -- every output of the belt is off: an empty whitelist would let the whole shared chest through
    elseif is_split then
        ends = {
            { chest = tile(x - 3, 1), loader = { x = x - 1, y = 1.5 }, direction = defines.direction.east, keys = { crossing.keys[1] } },
            { chest = tile(x + 3, 1), loader = { x = x + 2, y = 1.5 }, direction = defines.direction.west, keys = { crossing.keys[2] } },
        }
        block.mock_entities[#block.mock_entities + 1] =
            mock.create_entity({ name = constants.mock_belt, position = tile(x, 1), direction = flow_direction, force = force })
    end
    local inner_type = is_input and 'output' or 'input'
    local inner_link = linked_belt(constants.linked_belt, mock, tile(x, 2), flow_direction, inner_type, force)
    outer_link.connect_linked_belts(inner_link)
    if outer_link.linked_belt_neighbour ~= inner_link then
        log('ups-reclaimer: border linked belt at ' .. serpent.line(position) .. ' did not link to mock column ' .. x)
    end
    block.border_entities[#block.border_entities + 1] = outer_link
    block.mock_entities[#block.mock_entities + 1] = inner_link

    local flows = is_input and block.inputs or block.outputs
    local chest_name = is_input and constants.input_buffer or constants.output_buffer
    for _, spec in pairs(ends) do
        local chest = mock.create_entity({ name = chest_name, position = spec.chest, force = force })
        local loader = mock.create_entity({
            name = constants.loader,
            position = spec.loader,
            direction = spec.direction,
            force = force,
            type = crossing.kind, -- input: belt -> chest, output: chest -> belt
        })
        loader.update_connections()
        if not loader.loader_container then
            log('ups-reclaimer: mock loader at column ' .. x .. ' found no chest, check the column layout')
        end
        if is_input then
            -- Belts carrying the same items share one inventory, so a flow counts one inventory per item set, not
            -- one per belt.
            local sorted = { table.unpack(spec.keys) }
            table.sort(sorted)
            local group = table.concat(sorted, ',')
            local link_id = block.input_link_ids[group]
            local is_new = not link_id
            if is_new then
                storage.next_link_id = storage.next_link_id + 1
                link_id = storage.next_link_id
                block.input_link_ids[group] = link_id
            end
            chest.link_id = link_id -- before get_inventory: the inventory belongs to the link
            if is_new then
                for _, key in pairs(spec.keys) do
                    local inventories = flows[key].inventories
                    inventories[#inventories + 1] = chest.get_inventory(defines.inventory.linked_container_main)
                end
            end
        else
            -- All output chests of a block share one inventory (huge stacks: one slot per item); the loader picks
            -- its items.
            chest.link_id = block.output_link_id
            block.output_inventory = chest.get_inventory(defines.inventory.linked_container_main)
            loader.loader_filter_mode = 'whitelist'
            for i, key in pairs(spec.keys) do
                local item = flows[key].item
                loader.set_filter(i, { name = item.name, quality = item.quality, comparator = '=' })
            end
        end
        block.mock_entities[#block.mock_entities + 1] = chest
        block.mock_entities[#block.mock_entities + 1] = loader
        if is_input then
            local decider = is_mixed_input
                and mock.create_entity({
                    name = constants.decider,
                    position = { x = x + 1.5, y = 0 }, -- 1 x 2, column x + 1, rows -1 and 0
                    direction = defines.direction.north,
                    force = force,
                })
            block.feeds[#block.feeds + 1] =
                { loader = loader, chest = chest, keys = crossing.keys, decider = decider or nil }
            block.mock_entities[#block.mock_entities + 1] = decider or nil
        end
    end
end

--- Concrete under a block's mock columns, from first to its last belt's spare column, padded by 1 tile, so blocks
--- stand out on the mock surface. No-op for a block without belts.
--- ponytail: the concrete stays after unfreeze; mock columns are never reused.
--- @param first integer the block's first mock column
function border.pave(first)
    local tiles = {}
    for x = first - 1, storage.mock_column do
        for y = -2, 3 do -- rows -1 (chest) to 2 (linked belt)
            tiles[#tiles + 1] = { name = 'concrete', position = { x, y } }
        end
    end
    if storage.mock_column >= first then
        game.surfaces[constants.mock_surface].set_tiles(tiles)
    end
end

--- Border pipe -> port: a pipe that looks straight on its inner side and stays part of the outer fluid segment.
--- The step reads and moves fluid on that whole segment, so ports sharing one segment are counted once.
--- @param block Block
--- @param crossing Crossing
function border.connect_pipe(block, crossing)
    local pipe = crossing.entity
    local surface = pipe.surface
    local spec = {
        name = constants.port_prefix .. pipe.name,
        position = pipe.position,
        direction = pipe.direction,
        force = pipe.force,
        quality = pipe.quality,
    }
    pipe.destroy()
    local port = surface.create_entity(spec)
    port.destructible = false
    block.border_entities[#block.border_entities + 1] = port
    local flow = (crossing.kind == 'input' and block.inputs or block.outputs)[crossing.keys[1]]
    local segment = port.get_fluid_segment_id(1)
    if not flow.segments[segment] then
        flow.segments[segment] = true
        flow.ports[#flow.ports + 1] = port
    end
end

local function init()
    storage.mock_column = storage.mock_column or 0 -- mock surface columns used so far
end

border.on_init = init
border.on_configuration_changed = init

return border
