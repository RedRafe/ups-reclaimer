-- simple-entity-with-owner twins showing a still frame of each replaceable entity, at no UPS cost.
-- The variation numbering here must match look_alike.variation in scripts/look-alike.lua.
-- Returns the list of entity types that get a twin.
local constants = require('constants')
local sprites = require('prototypes.sprites')
local copy = require('util').table.deepcopy

local WALKABLE = {
    layers = {},
} -- belts, undergrounds and splitters don't block the player

local look_alikes = {}

--- Queues the twin of prototype, unless one of its count variations has no static graphics.
local function add_look_alike(prototype, variations, count, render_layer, collision_mask, lower_variations)
    for i = 1, count do
        if not variations[i] then
            return log('ups-reclaimer: no static graphics for ' .. prototype.name)
        end
    end
    if lower_variations then
        for i = 1, count do
            if not lower_variations[i] then
                lower_variations = nil
                break
            end
        end
    end
    -- Snaps to the grid like the original. Rotatable so the boxes of a non-square entity (splitter, pump,
    -- combinator, recycler) turn with its direction; the script locks rotation by hand (LuaEntity.rotatable).
    local flags = { 'placeable-neutral', 'not-blueprintable', 'not-deconstructable', 'not-upgradable' }
    for _, flag in pairs(prototype.flags or {}) do
        if flag == 'placeable-off-grid' then
            flags[#flags + 1] = flag
        end
    end
    -- The chart only fills an entity's collision box when it has a map colour; without one the twin is a dot.
    -- Most originals have none at the data stage and get the engine's per-type default, so look that up here.
    local chart = data.raw['utility-constants'].default.chart
    look_alikes[#look_alikes + 1] = {
        type = 'simple-entity-with-owner',
        map_color = prototype.map_color
            or (chart.default_color_by_type or {})[prototype.type]
            or (chart.default_friendly_color_by_type or {})[prototype.type]
            or chart.default_friendly_color,
        friendly_map_color = prototype.friendly_map_color
            or prototype.map_color
            or (chart.default_friendly_color_by_type or {})[prototype.type]
            or chart.default_friendly_color,
        enemy_map_color = prototype.enemy_map_color
            or prototype.map_color
            or (chart.default_enemy_color_by_type or {})[prototype.type]
            or chart.default_enemy_color,
        name = constants.look_alike_prefix .. prototype.name,
        localised_name = { 'upsr-name.frozen', prototype.localised_name or { 'entity-name.' .. prototype.name } },
        icon = prototype.icon,
        icons = prototype.icons,
        icon_size = prototype.icon_size,
        flags = flags,
        hidden = true,
        hidden_in_factoriopedia = true,
        collision_box = prototype.collision_box,
        selection_box = prototype.selection_box,
        tile_width = prototype.tile_width,
        tile_height = prototype.tile_height,
        build_grid_size = prototype.build_grid_size,
        collision_mask = collision_mask,
        render_layer = render_layer,
        random_variation_on_create = false,
        pictures = variations,
        lower_pictures = lower_variations,
        lower_render_layer = lower_variations and 'transport-belt' or nil,
    }
end

-- Belt pieces per direction (order of sprites.directions): {animation set field, default index}, for straight,
-- left and right turn.
local BELT_PIECES = {
    { { 'north_index', 3 }, { 'west_to_north_index', 7 }, { 'east_to_north_index', 5 } },
    { { 'east_index', 1 }, { 'north_to_east_index', 6 }, { 'south_to_east_index', 9 } },
    { { 'south_index', 4 }, { 'east_to_south_index', 10 }, { 'west_to_south_index', 12 } },
    { { 'west_index', 2 }, { 'south_to_west_index', 11 }, { 'north_to_west_index', 8 } },
}
-- Underground belt pieces per drawn direction, for entrance and exit. An exit is drawn turned around (see below).
local UNDERGROUND_PIECES = {
    { { 'ending_north_index', 18 }, { 'starting_north_index', 17 } },
    { { 'ending_east_index', 20 }, { 'starting_east_index', 19 } },
    { { 'ending_south_index', 14 }, { 'starting_south_index', 13 } },
    { { 'ending_west_index', 16 }, { 'starting_west_index', 15 } },
}
-- Pipe pictures by connection mask (north = 1, east = 2, south = 4, west = 8).
local PIPE_PICTURES = {
    [0] = 'straight_vertical_single',
    'ending_up',
    'ending_right',
    'corner_up_right',
    'ending_down',
    'straight_vertical',
    'corner_down_right',
    't_right',
    'ending_left',
    'corner_up_left',
    'straight_horizontal',
    't_up',
    'corner_down_left',
    't_left',
    't_down',
    'cross',
}

local function belt_piece(animation_set, piece)
    return animation_set and sprites.first_frame(animation_set.animation_set, animation_set[piece[1]] or piece[2])
end

local function crafting_machine(prototype, direction)
    local graphics = prototype.graphics_set
    if not graphics then
        return
    end
    local layers = {}
    local animation = sprites.animation_direction(graphics.animation or graphics.idle_animation, direction)
    sprites.flatten(layers, sprites.first_frame(animation, 1))
    for _, visualisation in pairs(graphics.working_visualisations or {}) do
        if visualisation.always_draw then
            local directed = visualisation[sprites.directions[direction + 1] .. '_animation']
            sprites.flatten(layers, sprites.first_frame(directed or visualisation.animation, 1))
        end
    end
    return #layers > 0 and {
        layers = layers,
    } or nil
end

local function combinator(prototype, direction)
    return sprites.sprite_direction(prototype.sprites, direction)
end

-- Entities whose look depends only on direction: variation = direction + 1.
local PICTURE_BY_DIRECTION = {
    ['assembling-machine'] = crafting_machine,
    furnace = crafting_machine,
    inserter = function(prototype, direction) -- the script draws the arm, turned toward the pickup
        return sprites.sprite_direction(prototype.platform_picture, direction)
    end,
    splitter = function(prototype, direction)
        -- structure_patch (east and west only) carries its own shift onto the north tile
        local patch = direction % 2 == 1
            and sprites.first_frame(sprites.animation_direction(prototype.structure_patch, direction), 1)
        return sprites.merge(
            patch or nil,
            sprites.first_frame(sprites.animation_direction(prototype.structure, direction), 1)
        )
    end,
    ['pipe-to-ground'] = function(prototype, direction)
        return sprites.sprite_direction(prototype.pictures, direction)
    end,
    pump = function(prototype, direction)
        return sprites.first_frame(sprites.animation_direction(prototype.animations, direction), 1)
    end,
    ['storage-tank'] = function(prototype, direction)
        return prototype.pictures and sprites.sprite_direction(prototype.pictures.picture, direction)
    end,
    beacon = function(prototype)
        local graphics = prototype.graphics_set
        if not graphics then
            return sprites.merge(
                sprites.first_frame(prototype.base_picture, 1),
                sprites.first_frame(prototype.animation, 1)
            )
        end
        local layers = {}
        for _, element in pairs(graphics.animation_list or {}) do
            sprites.flatten(layers, sprites.first_frame(element.animation, 1))
        end
        return #layers > 0 and {
            layers = layers,
        } or nil
    end,
    ['arithmetic-combinator'] = combinator,
    ['decider-combinator'] = combinator,
    ['selector-combinator'] = combinator,
    ['constant-combinator'] = combinator,
}

for entity_type, picture in pairs(PICTURE_BY_DIRECTION) do
    for _, prototype in pairs(data.raw[entity_type] or {}) do
        local variations, lower_variations = {}, nil
        for direction = 0, 3 do
            variations[direction + 1] = picture(prototype, direction)
        end
        if entity_type == 'splitter' then -- two straight belts under the structure
            lower_variations = {}
            for direction = 0, 3 do
                local belt = belt_piece(prototype.belt_animation_set, BELT_PIECES[direction + 1][1])
                local dx, dy = direction % 2 == 0 and 0.5 or 0, direction % 2 == 1 and 0.5 or 0
                lower_variations[direction + 1] =
                    sprites.merge(sprites.shifted(belt, -dx, -dy), sprites.shifted(belt, dx, dy))
            end
        end
        add_look_alike(
            prototype,
            variations,
            4,
            'object',
            entity_type == 'splitter' and WALKABLE or nil,
            lower_variations
        )
    end
end

-- Inserter arms: a copy of the inserter with only the arm drawn, disabled by the script (no updates). Static sprites
-- can't be rotated, so the engine draws the arm, at any direction and length. Pickup and drop share one spot, so the
-- hand rests at the pickup.
local empty = require('util').empty_sprite()
for _, prototype in pairs(data.raw.inserter) do
    local arm = copy(prototype)
    arm.name = constants.arm_prefix .. prototype.name
    arm.localised_name = { 'upsr-name.frozen', prototype.localised_name or { 'entity-name.' .. prototype.name } }
    arm.localised_description, arm.minable, arm.next_upgrade, arm.fast_replaceable_group = nil, nil, nil, nil
    arm.placeable_by, arm.corpse, arm.dying_explosion, arm.damaged_trigger_effect = nil, nil, nil, nil
    arm.flags = { 'placeable-off-grid', 'not-on-map', 'not-blueprintable', 'not-deconstructable', 'not-upgradable' }
    arm.hidden = true
    arm.selectable_in_game = false
    arm.collision_mask = { layers = {} }
    arm.energy_source = { type = 'void' }
    arm.platform_picture = empty
    arm.circuit_connector, arm.circuit_wire_max_distance = nil, 0
    arm.draw_held_item, arm.draw_inserter_arrow, arm.use_easter_egg = false, false, false
    arm.allow_custom_vectors = true
    arm.insert_position = arm.pickup_position
    look_alikes[#look_alikes + 1] = arm
end

-- Underground belts: variation = direction * 2 + (exit and 1 or 0) + 1. The engine draws an exit's sheets at the
-- opposite of its flow direction, the side it comes out of the ground.
for _, prototype in pairs(data.raw['underground-belt']) do
    local variations, lower_variations, structure = {}, {}, prototype.structure or {}
    for direction = 0, 3 do
        for is_exit = 0, 1 do
            local variation = direction * 2 + is_exit + 1
            local drawn = (direction + is_exit * 2) % 4
            local sprite = is_exit == 0 and structure.direction_in or structure.direction_out
            variations[variation] = sprites.sprite_direction(sprite, drawn)
            lower_variations[variation] =
                belt_piece(prototype.belt_animation_set, UNDERGROUND_PIECES[drawn + 1][is_exit + 1])
        end
    end
    add_look_alike(prototype, variations, 8, 'object', WALKABLE, lower_variations)
end

-- Belts: variation = direction * 3 + shape (straight, left, right) + 1
for _, prototype in pairs(data.raw['transport-belt']) do
    if prototype.belt_animation_set then
        local variations = {}
        for direction = 1, 4 do
            for shape = 1, 3 do
                variations[(direction - 1) * 3 + shape] =
                    belt_piece(prototype.belt_animation_set, BELT_PIECES[direction][shape])
            end
        end
        add_look_alike(prototype, variations, 12, 'transport-belt', WALKABLE)
    end
end

-- Pipes: variation = connection mask + 1
for _, prototype in pairs(data.raw.pipe) do
    if prototype.pictures then
        local variations = {}
        for mask = 0, 15 do
            local picture = prototype.pictures[PIPE_PICTURES[mask]]
            variations[mask + 1] = picture and copy(picture)
        end
        add_look_alike(prototype, variations, 16, 'object')
    end
end

-- Alt-mode icons as simple entities: always shown (they can't follow alt mode), but no render objects. Backgrounds
-- go a render layer below every icon, so a neighbour's background never shades an icon.
local function icon_entity(name, pictures, backgrounds)
    look_alikes[#look_alikes + 1] = {
        type = 'simple-entity-with-owner',
        name = name,
        icon = constants.icon,
        flags = { 'placeable-off-grid', 'not-on-map', 'not-blueprintable', 'not-deconstructable', 'not-upgradable' },
        hidden = true,
        selectable_in_game = false,
        collision_mask = { layers = {} },
        render_layer = 'entity-info-icon-above',
        random_variation_on_create = false,
        pictures = pictures,
        lower_pictures = backgrounds,
        lower_render_layer = 'entity-info-icon',
    }
end

--- The item or fluid named name: what a recipe without its own icon shows.
local function product(name)
    for _, by_name in pairs(data.raw) do
        local prototype = by_name[name]
        if prototype and (prototype.stack_size or prototype.type == 'fluid') then
            return prototype
        end
    end
end

-- The dark square alt mode draws behind icons, for contrast against the machine. Baked into the mod, 53 px like the
-- core file (64 px per tile): the core entity-info background didn't show up drawn as an entity layer. Its opaque
-- core is 32 px, the icon's size, and it fades out past the icon over the rest.
local background = { filename = '__ups-reclaimer__/graphics/icon-background.png', size = 53, flags = { 'icon' } }
local BACKGROUND_SPREAD = 53 / 32 * 1.4
for _, recipe in pairs(data.raw.recipe) do
    local results = recipe.results or {}
    local main = recipe.main_product or (#results == 1 and results[1].name)
    local source = (recipe.icons or recipe.icon) and recipe or main and product(main)
    if source and sprites.icon(source, 1) then
        local pictures, backgrounds = {}, {}
        for tiles = 1, constants.icon_sizes do
            local width = tiles * constants.recipe_icon_scale
            pictures[tiles] = sprites.icon(source, width)
            backgrounds[tiles] = sprites.sized(background, width * BACKGROUND_SPREAD)
        end
        icon_entity(constants.recipe_icon_prefix .. recipe.name, pictures, backgrounds)
    end
end
for _, module in pairs(data.raw.module) do
    local picture = sprites.icon(module, constants.module_icon_scale)
    if picture then
        icon_entity(
            constants.module_icon_prefix .. module.name,
            { picture },
            { sprites.sized(background, constants.module_icon_scale * BACKGROUND_SPREAD) }
        )
    end
end

data:extend(look_alikes)

local replaced_types = { 'transport-belt', 'underground-belt', 'pipe' }
for entity_type in pairs(PICTURE_BY_DIRECTION) do
    replaced_types[#replaced_types + 1] = entity_type
end
return replaced_types
