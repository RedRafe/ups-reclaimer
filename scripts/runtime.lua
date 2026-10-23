-- Batched virtual crafting. Belts, loaders and the power draw run in the engine; once per period Lua moves each
-- block's border flows for the whole period and switches its input loaders.
local constants = require('constants')
local rates = require('scripts.rates')
local solver = require('scripts.solver')

local PERIOD = 60 -- ticks between steps
local SECONDS = PERIOD / 60
local MAX_WAIT = 600 -- a stalled block backs off up to this many ticks
local IDLE = 1e-9 -- utilisation below this counts as stopped

--- @param block_id integer
--- @param tick uint
local function schedule(block_id, tick)
    local due = storage.schedule[tick]
    if not due then
        due = {}
        storage.schedule[tick] = due
    end
    due[#due + 1] = block_id
end

--- Whole items out of amount; the fraction carries over so the long-run rate is exact.
--- @param flow BorderFlow
--- @param amount number
--- @return integer
local function whole_items(flow, amount)
    local wanted = flow.carry + amount
    local count = math.floor(wanted)
    flow.carry = wanted - count
    return count
end

--- Fluid of this flow in the segments of its ports.
--- @param flow BorderFlow
--- @return number
local function segment_amount(flow)
    local amount = 0
    for _, port in pairs(flow.ports) do
        local fluid = port.get_fluid_segment_fluid(1)
        if fluid and fluid.name == flow.fluid then
            amount = amount + fluid.amount
        end
    end
    return amount
end

--- Items of this input in the chests of the belts that carry it, usually one.
--- @param flow BorderFlow
--- @return integer
local function item_count(flow)
    local count = 0
    for _, inventory in pairs(flow.inventories) do
        count = count + inventory.get_item_count(flow.item)
    end
    return count
end

--- Free room in the segments of the flow's ports; a segment holding another fluid has none.
--- @param flow BorderFlow
--- @return number
local function segment_room(flow)
    local room = 0
    for _, port in pairs(flow.ports) do
        local fluid = port.get_fluid_segment_fluid(1)
        if not fluid or fluid.name == flow.fluid then
            room = room + port.get_fluid_segment_capacity(1) - (fluid and fluid.amount or 0)
        end
    end
    return room
end

--- Removes this step's amount of an input: fluid from its segments, items from the chests of its belts.
--- @param block Block
--- @param flow BorderFlow
--- @param amount number
local function take(block, flow, amount)
    if flow.fluid then
        for _, port in pairs(flow.ports) do
            if amount <= 0 then
                break
            end
            local removed = port.remove_fluid_segment_fluid(1, amount)
            amount = amount - (removed and removed.amount or 0)
        end
        return
    end
    local count = whole_items(flow, amount)
    flow.stock = flow.stock - count
    for _, inventory in pairs(flow.inventories) do
        if count <= 0 then
            break
        end
        count = count - inventory.remove({ name = flow.item.name, quality = flow.item.quality, count = count })
    end
end

--- Adds this step's amount of an output: fluid to its segments, items to the shared output buffer.
--- @param block Block
--- @param flow BorderFlow
--- @param amount number
local function give(block, flow, amount)
    if flow.fluid then
        for _, port in pairs(flow.ports) do
            if amount <= 0 then
                break
            end
            amount = amount
                - port.add_fluid_segment_fluid(
                    1,
                    { name = flow.fluid, amount = amount, temperature = flow.temperature }
                )
        end
        return
    end
    local count = whole_items(flow, amount)
    if count > 0 then
        block.output_inventory.insert({ name = flow.item.name, quality = flow.item.quality, count = count })
    end
end

--- Per second the border can move for a flow, given what is available (stock or room). Fluids are continuous;
--- items need floor(carry + amount) <= available, so the carried fraction covers sub-item amounts and slow items
--- never stall.
--- @param flow BorderFlow
--- @param available number
--- @return number
local function allowance(flow, available)
    if flow.fluid then
        return available / SECONDS
    end
    return math.max(0, (available + 1 - flow.carry) / SECONDS - 1e-9)
end

--- Moves every border flow by what the rows ran this step.
--- @param block Block
--- @param utilisation number[] by row
local function move_flows(block, utilisation)
    for key, entry in pairs(block.flow_index) do
        local input, output = block.inputs[key], block.outputs[key]
        if input or output then
            local net = 0
            for i = 1, #entry.rows do
                net = net + entry.rates[i] * utilisation[entry.rows[i]]
            end
            if input and net < 0 then
                take(block, input, -net * SECONDS)
            end
            if output and net > 0 then
                give(block, output, net * SECONDS)
            end
        end
    end
end

--- Bills a step's active power, plus idle, through the interface's power_usage.
--- @param block Block
--- @param joules number
--- @return number scale share of the step the power allowed: a brownout slows every machine alike
local function draw_power(block, joules)
    local interface = block.power_interface
    if not interface or joules <= 0 then
        return 1
    end
    -- The engine bills this step's power evenly over the next period: a flat line on the graph, not a burst
    -- refill. A full buffer covers a full-load step; a brownout drains it and scales the step down.
    -- ponytail: billing lags one step behind the work; invisible on any graph wider than a second.
    interface.power_usage = joules / PERIOD + block.idle_watts / 60
    local energy = interface.energy
    return energy >= joules and 1 or energy / joules
end

--- Emits a step's pollution at the block's center.
--- ponytail: one point per block, not per machine; spread over the box's chunks if big blocks look wrong.
--- @param block Block
--- @param amount number
local function pollute(block, amount)
    if amount > 0 then
        local box = block.box
        local center = { x = (box.left_top.x + box.right_bottom.x) / 2, y = (box.left_top.y + box.right_bottom.y) / 2 }
        game.surfaces[block.surface].pollute(center, amount)
    end
end

--- Steady state: every flow moves at its cached rate, no solve and no per-row work.
--- @param block Block
--- @param seconds number of full-speed flow to move
local function move_steady(block, seconds)
    for _, flow in pairs(block.inputs) do
        if flow.rate > 0 then
            take(block, flow, flow.rate * seconds)
        end
    end
    for _, flow in pairs(block.outputs) do
        if flow.rate > 0 then
            give(block, flow, flow.rate * seconds)
        end
    end
end

--- Short of an input or of output room: each recipe runs as far as its own inputs, outputs and the power allow, so
--- a starved input or a backed-up output only slows the recipes that touch it.
--- @param block Block
--- @return boolean busy false when no recipe could run
local function step_constrained(block)
    local supply, sink, utilisation = {}, {}, {}
    for key, flow in pairs(block.inputs) do
        supply[key] = allowance(flow, flow.stock)
    end
    for key, flow in pairs(block.outputs) do
        sink[key] = allowance(flow, flow.room)
    end
    for i, row in pairs(block.rows) do
        utilisation[i] = row.utilisation
    end
    solver.solve(utilisation, block.flow_index, supply, sink)

    local busy = false
    for i, row in pairs(block.rows) do
        if row.is_recipe and utilisation[i] > IDLE then
            busy = true
            break
        end
    end
    if not busy then
        return false
    end
    local scale = draw_power(block, rates.active_watts(block.rows, utilisation) / 60 * PERIOD)
    if scale <= 0 then
        return false
    end
    if scale < 1 then
        for i in pairs(utilisation) do
            utilisation[i] = utilisation[i] * scale
        end
    end
    move_flows(block, utilisation)
    pollute(block, rates.active_watts(block.rows, utilisation, 'emissions') * SECONDS)
    return true
end

--- One step. The border is read every time, it is how a short input or a full output shows up; the rows are only
--- touched when a flow is short, which a block running at its steady state never is.
--- @param block Block
--- @return boolean busy false when no recipe could run
local function step(block)
    local constrained = false
    for _, flow in pairs(block.inputs) do
        flow.stock = flow.fluid and segment_amount(flow) or item_count(flow)
        if allowance(flow, flow.stock) < flow.rate then
            constrained = true
        end
    end
    for _, flow in pairs(block.outputs) do
        flow.room = flow.fluid and segment_room(flow) or flow.buffer - block.output_inventory.get_item_count(flow.item)
        if allowance(flow, flow.room) < flow.rate then
            constrained = true
        end
    end

    local busy
    if constrained then
        busy = step_constrained(block)
    else
        local scale = block.is_productive and draw_power(block, block.step_joules) or 0
        busy = scale > 0
        if busy then
            move_steady(block, scale * SECONDS)
            pollute(block, (block.step_pollution or 0) * scale)
        end
    end
    return busy
end

--- Timer wheel: an idle tick costs one table lookup. Stalled blocks back off so they are polled rarely.
--- @param event EventData.on_tick
local function on_tick(event)
    local due = storage.schedule[event.tick]
    if not due then
        return
    end
    storage.schedule[event.tick] = nil
    for _, block_id in pairs(due) do
        local block = storage.blocks[block_id]
        if block then
            local busy = step(block)
            block.wait = busy and PERIOD or math.min(block.wait * 2, MAX_WAIT)
            if not busy and block.power_interface then
                block.power_interface.power_usage = block.idle_watts / 60 -- stalled: back to idle draw
            end
            schedule(block_id, event.tick + block.wait)
        end
    end
end

local CHECK = { type = 'virtual', name = 'signal-check' }

--- @param source LuaEntity
--- @param source_connector defines.wire_connector_id
--- @param target LuaEntity
--- @param target_connector defines.wire_connector_id
local function connect(source, source_connector, target, target_connector)
    source
        .get_wire_connector(source_connector, true)
        .connect_to(target.get_wire_connector(target_connector, true), false, defines.wire_origin.player)
end

--- The engine switches every input loader, every tick and at no script cost: it runs while each of its items is
--- below its target stock in its chest. A single-item loader reads the chest itself; a mixed one reads a decider
--- that ANDs one condition per item, so the item that piles up first backs the belt up, like a real mixed belt into
--- inserters. The conditions are set by set_targets.
--- @param feed Feed
local function wire_feed(feed)
    local connector = defines.wire_connector_id
    feed.loader.get_or_create_control_behavior().circuit_enable_disable = true
    if not feed.decider then
        connect(feed.chest, connector.circuit_red, feed.loader, connector.circuit_red)
        return
    end
    connect(feed.chest, connector.circuit_red, feed.decider, connector.combinator_input_red)
    connect(feed.decider, connector.combinator_output_red, feed.loader, connector.circuit_red)
    feed.loader.get_control_behavior().circuit_condition = { first_signal = CHECK, comparator = '>', constant = 0 }
end

--- Stock and room targets: the buffer setting's seconds of flow, +2 items of jitter so a slow item doesn't stop its
--- belt; written into the input loaders' conditions.
--- @param block Block
local function set_targets(block)
    local seconds = settings.global[constants.buffer_setting].value --[[@as number]]
    for _, flows in pairs({ block.inputs, block.outputs }) do
        for _, flow in pairs(flows) do
            if flow.item then
                flow.buffer = math.ceil(seconds * flow.rate) + 2
            end
        end
    end
    for _, feed in pairs(block.feeds) do
        local conditions = {}
        for i, key in pairs(feed.keys) do
            local flow = block.inputs[key]
            conditions[i] = {
                first_signal = { type = 'item', name = flow.item.name, quality = flow.item.quality },
                comparator = '<',
                constant = flow.buffer,
                compare_type = feed.decider and 'and' or nil, -- decider conditions only
            }
        end
        if feed.decider then
            feed.decider.get_or_create_control_behavior().parameters = {
                conditions = conditions,
                outputs = { { signal = CHECK, constant = 1, copy_count_from_input = false } },
            }
        else
            feed.loader.get_control_behavior().circuit_condition = conditions[1]
        end
    end
end

--- @param event EventData.on_runtime_mod_setting_changed
local function on_runtime_mod_setting_changed(event)
    if event.setting == constants.buffer_setting then
        for _, block in pairs(storage.blocks) do
            set_targets(block)
        end
    end
end

local runtime = {}

--- Sets the runtime state of a newly frozen block and schedules its first step; blocks are spread over the
--- period's ticks so their steps don't land on the same tick.
--- @param block Block
function runtime.start(block)
    for _, flows in pairs({ block.inputs, block.outputs }) do
        for _, flow in pairs(flows) do
            flow.carry = flow.item and 0 or nil
        end
    end
    for _, feed in pairs(block.feeds) do
        wire_feed(feed)
    end
    set_targets(block)
    -- The engine refills the interface at no more than steady-state power and takes power_usage every tick; each
    -- step sets power_usage to what it ran on: brownout -> buffer drains -> partial step; stalled -> idle draw only.
    if block.power_interface then
        block.power_interface.electric_buffer_size = block.watts / 60 * PERIOD
    end
    -- Steady-state step, cached: its active power, its pollution and whether any recipe runs at all.
    block.step_joules = (block.watts - block.idle_watts) / 60 * PERIOD
    block.is_productive = false
    local steady = {}
    for i, row in pairs(block.rows) do
        steady[i] = row.utilisation
        if row.is_recipe and row.utilisation > IDLE then
            block.is_productive = true
        end
    end
    block.step_pollution = rates.active_watts(block.rows, steady, 'emissions') * SECONDS
    block.wait = PERIOD
    schedule(block.id, game.tick + 1 + block.id % PERIOD)
end

local function init()
    storage.schedule = storage.schedule or {} -- tick -> ids of the blocks that step then
end

runtime.on_init = init
runtime.on_configuration_changed = init
runtime.events = {
    [defines.events.on_tick] = on_tick,
    [defines.events.on_runtime_mod_setting_changed] = on_runtime_mod_setting_changed,
}

return runtime
