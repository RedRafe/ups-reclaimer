-- Border plumbing: linked belts and ports on the factory surface, loaders and shared buffers on the mock surface,
-- and the energy interface that bills the frozen block's power.
local constants = require('constants')
local copy = require('util').table.deepcopy

-- ponytail: a port's segment must hold one second of flow, so border rates above ~PORT_VOLUME/s per segment get capped.
local PORT_VOLUME = 10000

--- Hidden copy of prototype under a new name; it can't be mined, upgraded or placed by hand. Without localised_name
--- it is named by its own entity-name key.
local function hidden_copy(prototype, name, localised_name)
    local hidden = copy(prototype)
    hidden.name = name
    hidden.localised_name, hidden.localised_description = localised_name, nil
    hidden.minable, hidden.next_upgrade, hidden.fast_replaceable_group, hidden.placeable_by = nil, nil, nil, nil
    hidden.hidden = true
    return hidden
end

local entities = {}

-- One linked belt and one loader for every border belt: base graphics and wire reach, at the fastest belt's speed so
-- they never cap a border belt.
local fastest = data.raw['transport-belt']['transport-belt']
for _, belt in pairs(data.raw['transport-belt']) do
    if belt.speed > fastest.speed and belt.belt_animation_set then
        fastest = belt
    end
end
local function fast_copy(prototype, name)
    local entity = hidden_copy(prototype, name)
    entity.speed = fastest.speed
    entity.belt_animation_set = fastest.belt_animation_set
    entities[#entities + 1] = entity
    return entity
end
local base_link = data.raw['linked-belt']['linked-belt']
fast_copy(base_link, constants.linked_belt)
local loader = fast_copy(data.raw.loader.loader, constants.loader)
-- Stacked belts (space_travel): the loaders stack as high as any belt can, so they never cap a stacked border belt.
if feature_flags['space_travel'] then
    loader.max_belt_stack_size = data.raw['utility-constants'].default.max_belt_stack_size or 4
end
fast_copy(fastest, constants.mock_belt)

-- Border underground belt end: the same linked belt drawn as the fastest underground belt.
local underground = data.raw['underground-belt'][fastest.related_underground_belt]
    or data.raw['underground-belt']['underground-belt']
local linked_underground = fast_copy(base_link, constants.linked_underground)
linked_underground.structure = {}
for _, key in pairs({
    'direction_in',
    'direction_out',
    'direction_in_side_loading',
    'direction_out_side_loading',
    'back_patch',
    'front_patch',
}) do
    linked_underground.structure[key] = underground.structure[key]
end

--- Border pipe: named after the pipe it replaces.
local function port_copy(pipe)
    local port = hidden_copy(pipe, constants.port_prefix .. pipe.name, {
        'upsr-name.port',
        pipe.localised_name or { 'entity-name.' .. pipe.name },
    })
    port.fluid_box.volume = PORT_VOLUME
    entities[#entities + 1] = port
    return port
end

-- Border pipe-to-ground: keeps its underground link to an outside end, its open end faces the frozen pipes.
for _, pipe in pairs(data.raw['pipe-to-ground']) do
    port_copy(pipe)
end

-- Border pipe tile: a real pipe in the outer fluid segment whose dead end is drawn straight, so it seems to run on
-- into the frozen pipes.
for _, pipe in pairs(data.raw.pipe) do
    if pipe.pictures then
        local pictures = port_copy(pipe).pictures
        pictures.ending_up, pictures.ending_down = copy(pictures.straight_vertical), copy(pictures.straight_vertical)
        pictures.ending_left, pictures.ending_right =
            copy(pictures.straight_horizontal), copy(pictures.straight_horizontal)
    end
end

-- Input buffer: input belts carrying the same items share one inventory via link_id. Tells its loader (or decider)
-- how much is stocked, so the steel chest's circuit connector is added; huge stacks so every item kind fits in one slot.
-- ponytail: stray items aren't deleted any more; they pile up until the slots run out.
local base_linked_chest = data.raw['linked-container']['linked-chest']
local input_buffer = hidden_copy(base_linked_chest, constants.input_buffer)
input_buffer.inventory_size = constants.input_buffer_slots
input_buffer.inventory_type = 'with_custom_stack_size'
input_buffer.inventory_properties = { stack_size_multiplier = 1e6 }
input_buffer.gui_mode = 'none'
input_buffer.circuit_connector = copy(data.raw.container['steel-chest'].circuit_connector)
input_buffer.circuit_wire_max_distance = 2
entities[#entities + 1] = input_buffer

-- Decider gating a mixed input belt's loader on the mock surface; needs no power.
local base_decider = data.raw['decider-combinator']['decider-combinator']
local decider = hidden_copy(base_decider, constants.decider)
decider.energy_source = {
    type = 'void',
}
entities[#entities + 1] = decider

-- Output buffer: all output chests of a block share one inventory via link_id. A copy of the base linked chest, so
-- loaders can take from it; huge stacks so every item kind fits in one slot. The script caps each item's stock.
local output_buffer = hidden_copy(base_linked_chest, constants.output_buffer)
output_buffer.inventory_size = constants.output_buffer_slots
output_buffer.inventory_type = 'with_custom_stack_size'
output_buffer.inventory_properties = { stack_size_multiplier = 1e6 }
output_buffer.gui_mode = 'none'
entities[#entities + 1] = output_buffer

data:extend(entities)
data:extend({
    {
        -- The script sets the flow limit and buffer to the block's full-load power.
        type = 'electric-energy-interface',
        name = constants.power_interface,
        hidden = true,
        icon = constants.icon,
        icon_size = 64,
        flags = { 'not-on-map', 'placeable-off-grid', 'not-blueprintable', 'not-deconstructable' },
        selectable_in_game = false,
        gui_mode = 'none',
        collision_box = { { -0.1, -0.1 }, { 0.1, 0.1 } },
        collision_mask = {
            layers = {},
        },
        energy_source = {
            type = 'electric',
            usage_priority = 'secondary-input',
            input_flow_limit = '100GW',
            output_flow_limit = '0W',
        },
        energy_usage = '0W',
    },
})
