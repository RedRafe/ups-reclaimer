-- The player's selection and the blueprint-style panel listing what will be replaced.
local constants = require('constants')
local freeze = require('scripts.freeze')
local look_alike = require('scripts.look-alike')
local rates = require('scripts.rates')

local PANEL = 'upsr_panel'
local HIGHLIGHT = { r = 0, g = 0.15, b = 0.3, a = 0.3 } -- premultiplied, 30% alpha
-- Panel order: machines first, then logistics; any other type goes last.
local TYPE_ORDER = {
    ['assembling-machine'] = 1,
    ['furnace'] = 2,
    ['beacon'] = 3,
    ['inserter'] = 4,
    ['transport-belt'] = 5,
    ['underground-belt'] = 6,
    ['splitter'] = 7,
    ['pipe'] = 8,
    ['pipe-to-ground'] = 9,
    ['pump'] = 10,
    ['storage-tank'] = 11,
}
local OTHER_TYPES = 12

--- @class Selection
--- @field surface uint surface index
--- @field entities table<uint, LuaEntity> by unit number
--- @field highlights table<uint, LuaRenderObject> by unit number
--- @field kept table<string, true> entity names the player keeps real
--- @field off table<string, true> border flows the player switched off, "inputs <key>" or "outputs <key>"

local function type_order(name)
    return TYPE_ORDER[prototypes.entity[name].type] or OTHER_TYPES
end

local SECTION_GAP = 8 -- pixels above each panel section

--- Preview of the border flows the freeze would make, one slot each with its rate per second; a click switches a
--- flow off, so it crosses at 0 and what makes or uses it inside slows down. While the freeze is blocked, the errors
--- show instead.
--- @param panel LuaGuiElement
--- @param selection Selection
local function add_flows(panel, selection)
    local plan = freeze.plan(selection)
    for _, message in pairs(plan.errors) do
        local label =
            panel.add({ type = 'label', caption = { 'upsr-message.cannot-freeze', message }, style = 'bold_red_label' })
        label.style.single_line = false
        label.style.top_margin = SECTION_GAP
        label.style.maximal_width = 400 -- the slot table's width
    end
    if #plan.errors > 0 then
        return
    end
    for _, side in pairs({ 'inputs', 'outputs' }) do
        local keys = {}
        for key in pairs(plan[side]) do
            keys[#keys + 1] = key
        end
        table.sort(keys)
        if #keys > 0 then
            panel.add({ type = 'label', caption = { 'upsr-gui.' .. side }, style = 'caption_label' }).style.top_margin =
                SECTION_GAP
            local slots = panel
                .add({ type = 'frame', style = 'slot_button_deep_frame' })
                .add({ type = 'table', column_count = 10, style = 'filter_slot_table' })
            for _, key in pairs(keys) do
                local flow_id = side .. ' ' .. key
                local off, rate = selection.off[flow_id], plan[side][key].rate
                local kind, name, quality = rates.parse(key)
                slots.add({
                    type = 'sprite-button',
                    sprite = kind .. '/' .. name,
                    quality = quality ~= '' and quality or nil, -- badge in the bottom left
                    number = rate,
                    style = (off or rate == 0) and 'red_slot_button' or 'slot_button', -- 0 is left out anyway
                    tags = { upsr_flow = flow_id },
                    tooltip = {
                        '',
                        rates.icon(key),
                        string.format(' %.2f/s\n', rate),
                        { off and 'upsr-gui.flow-off' or rate == 0 and 'upsr-gui.flow-idle' or 'upsr-gui.flow-on' },
                    },
                })
            end
        end
    end
end

--- Blueprint-style panel: one slot per replaceable entity name with its count; a click toggles "keep real".
--- @param player LuaPlayer
local function update_panel(player)
    local screen = player.gui.screen
    local old_panel, location = screen[PANEL], nil
    if old_panel then
        location = old_panel.location
        old_panel.destroy()
    end
    local selection = storage.selections[player.index]
    if not selection or not next(selection.entities) then
        return
    end

    local counts, names = {}, {}
    for _, entity in pairs(selection.entities) do
        if entity.valid and look_alike.name(entity) then
            if not counts[entity.name] then
                names[#names + 1] = entity.name
            end
            counts[entity.name] = (counts[entity.name] or 0) + 1
        end
    end
    table.sort(names, function(first, second)
        local first_order, second_order = type_order(first), type_order(second)
        if first_order ~= second_order then
            return first_order < second_order
        end
        return first < second
    end)

    local panel = screen.add({ type = 'frame', name = PANEL, direction = 'vertical', caption = { 'upsr-gui.title' } })
    if location then
        panel.location = location
    else
        panel.force_auto_center()
    end
    -- Contents sit in an inner frame, like vanilla windows.
    local inner = panel.add({ type = 'frame', style = 'inside_shallow_frame_with_padding', direction = 'vertical' })
    inner.add({ type = 'label', caption = { 'upsr-gui.hint' } })
    local slots = inner
        .add({ type = 'frame', style = 'slot_button_deep_frame' })
        .add({ type = 'table', column_count = 10, style = 'filter_slot_table' })
    for _, name in pairs(names) do
        local kept = selection.kept[name]
        slots.add({
            type = 'sprite-button',
            sprite = 'entity/' .. name,
            number = counts[name],
            style = kept and 'red_slot_button' or 'slot_button',
            tags = { upsr_keep = name },
            tooltip = { '', prototypes.entity[name].localised_name, '\n', { kept and 'upsr-gui.kept' or 'upsr-gui.replaced' } },
        })
    end
    add_flows(inner, selection)
    local buttons = inner.add({ type = 'flow' })
    buttons.style.top_margin = SECTION_GAP
    buttons.add({ type = 'button', name = 'upsr_clear', caption = { 'upsr-gui.clear' } })
    buttons.add({ type = 'empty-widget' }).style.horizontally_stretchable = true
    buttons.add({ type = 'button', name = 'upsr_freeze', caption = { 'upsr-gui.freeze' }, style = 'confirm_button' })
end

--- @param player_index uint
local function clear(player_index)
    local selection = storage.selections[player_index]
    if not selection then
        return
    end
    for _, highlight in pairs(selection.highlights) do
        if highlight.valid then
            highlight.destroy()
        end
    end
    storage.selections[player_index] = nil
end

--- Adds the entities to the player's selection; selecting on another surface starts over.
--- @param event EventData.on_player_selected_area
local function on_player_selected_area(event)
    if event.item ~= constants.tool then
        return
    end
    local player = game.get_player(event.player_index)
    if not player then
        return
    end
    local selection = storage.selections[player.index]
    if selection and selection.surface ~= event.surface.index then
        clear(player.index)
        selection = nil
    end
    if not selection then
        selection = { surface = event.surface.index, entities = {}, highlights = {}, kept = {}, off = {} }
        storage.selections[player.index] = selection
    end
    for _, entity in pairs(event.entities) do
        local unit_number = entity.unit_number
        if unit_number and not selection.entities[unit_number] then
            local box = entity.selection_box
            selection.entities[unit_number] = entity
            selection.highlights[unit_number] = rendering.draw_rectangle({
                color = HIGHLIGHT,
                filled = true,
                left_top = box.left_top,
                right_bottom = box.right_bottom,
                surface = event.surface,
                players = { player },
            })
        end
    end
    update_panel(player)
end

--- Drops the entities from the player's selection.
--- @param event EventData.on_player_alt_selected_area
local function on_player_alt_selected_area(event)
    if event.item ~= constants.tool then
        return
    end
    local player = game.get_player(event.player_index)
    local selection = storage.selections[event.player_index]
    if not player or not selection then
        return
    end
    for _, entity in pairs(event.entities) do
        local unit_number = entity.unit_number
        if unit_number and selection.entities[unit_number] then
            local highlight = selection.highlights[unit_number]
            if highlight.valid then
                highlight.destroy()
            end
            selection.entities[unit_number] = nil
            selection.highlights[unit_number] = nil
        end
    end
    update_panel(player)
end

--- @param event EventData.on_gui_click
local function on_gui_click(event)
    local element = event.element
    if element.get_mod() ~= script.mod_name then
        return
    end
    local player = game.get_player(event.player_index)
    if not player then
        return
    end
    local selection = storage.selections[player.index]
    local toggled_name, toggled_flow = element.tags.upsr_keep, element.tags.upsr_flow
    if toggled_name then
        if selection then
            selection.kept[toggled_name] = not selection.kept[toggled_name] or nil
        end
    elseif toggled_flow then
        if selection then
            selection.off[toggled_flow] = not selection.off[toggled_flow] or nil
        end
    elseif element.name == 'upsr_freeze' then
        if selection and freeze.freeze(player, selection) then
            clear(player.index)
        end
    elseif element.name == 'upsr_clear' then
        clear(player.index)
    else
        return
    end
    update_panel(player)
end

local function init()
    storage.selections = storage.selections or {} -- player index -> Selection
    for _, selection in pairs(storage.selections) do
        selection.off = selection.off or {} -- selections made before flows could be switched off
    end
end

local selection = {}

selection.on_init = init
selection.on_configuration_changed = init
selection.events = {
    [defines.events.on_player_selected_area] = on_player_selected_area,
    [defines.events.on_player_alt_selected_area] = on_player_alt_selected_area,
    [defines.events.on_gui_click] = on_gui_click,
}

return selection
