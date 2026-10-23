-- Shared by the data and the control stage, so prototypes and scripts can't drift apart.
local constants = {}

constants.tool = 'upsr-tool'
constants.shortcut = 'upsr-shortcut'
constants.icon = '__base__/graphics/icons/assembling-machine-1.png'
constants.mock_surface = 'upsr-mock'
constants.buffer_setting = 'upsr-buffer-seconds'

-- Prototype names: look-alike and border pipe are the prefix plus the original entity name.
constants.look_alike_prefix = 'upsr-'
constants.port_prefix = 'upsr-port-'
constants.arm_prefix = 'upsr-arm-' -- disabled inserter showing only the arm, over an inserter's look-alike
constants.recipe_icon_prefix = 'upsr-recipe-icon-' -- alt-mode icons as entities: no render objects
constants.module_icon_prefix = 'upsr-module-icon-'
-- ponytail: icon sizes are eyeballed, tune in game. Recipe icon width per tile of the machine's shorter side, and
-- module icon width, in tiles.
constants.recipe_icon_scale, constants.module_icon_scale = 0.31, 0.52
--- Recipe icon variations: variation n is drawn for a machine n tiles across.
constants.icon_sizes = 10
constants.linked_belt = 'upsr-linked-belt'
constants.linked_underground = 'upsr-linked-underground'
constants.mock_belt = 'upsr-belt' -- mock surface: merges a split output belt's two lanes
constants.loader = 'upsr-loader'
constants.decider = 'upsr-decider'
constants.input_buffer = 'upsr-input-buffer'
constants.output_buffer = 'upsr-output-buffer'
constants.power_interface = 'upsr-power'

--- Loader filter slots, the base loader's filter_count: one border belt carries at most this many item/quality kinds.
constants.loader_filters = 5
--- Buffer chest slots. Output: one shared chest per block, huge stacks, so item/quality kinds per block. Input: one
--- chest per belt, normal stacks.
constants.input_buffer_slots = 48
constants.output_buffer_slots = 10

constants.machine_types = {
    ['assembling-machine'] = true,
    ['furnace'] = true,
}

return constants
