-- Selection tool and its shortcut. Select picks entities, alt-select drops them, reverse-select unfreezes.
local constants = require('constants')
local replaced_types = require('prototypes.look-alikes')

data:extend({
    {
        type = 'selection-tool',
        name = constants.tool,
        icon = constants.icon,
        icon_size = 64,
        flags = { 'only-in-cursor', 'not-stackable', 'spawnable' },
        stack_size = 1,
        select = {
            border_color = { 0, 0.6, 1 },
            cursor_box_type = 'copy',
            mode = { 'same-force', 'any-entity' },
            entity_type_filters = replaced_types,
        },
        alt_select = {
            border_color = { 1, 0.3, 0.3 },
            cursor_box_type = 'not-allowed',
            mode = { 'same-force', 'any-entity' },
            entity_type_filters = replaced_types,
        },
        reverse_select = {
            border_color = { 1, 0.8, 0 },
            cursor_box_type = 'pair',
            mode = { 'same-force', 'any-entity' },
            entity_type_filters = { 'simple-entity-with-owner' },
        },
    },
    {
        type = 'shortcut',
        name = constants.shortcut,
        action = 'spawn-item',
        item_to_spawn = constants.tool,
        icon = constants.icon,
        icon_size = 64,
        small_icon = constants.icon,
        small_icon_size = 64,
    },
})
