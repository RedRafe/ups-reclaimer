-- Look-alikes on the factory surface: which variation to show, the alt-mode icons, and the snapshot that brings the
-- real entity back on unfreeze.
local constants = require('constants')
local rates = require('scripts.rates')

local BELT_SHAPE = { straight = 0, left = 1, right = 2 }
local MODULE_GAP = 0.58 -- centre to centre, in tiles
local MODULE_RAISE = 0.8 -- module row height below the centre, as a fraction of the bottom-edge placement
local ICON_LIFT = 0.10 -- recipe and module icons moved up by this fraction of the machine's height

--- @class Snapshot what unfreezing rebuilds
--- @field name string
--- @field position MapPosition
--- @field direction defines.direction
--- @field quality string
--- @field force string
--- @field type string? underground belts: "input" or "output"
--- @field recipe string?
--- @field recipe_quality string?
--- @field modules ItemWithQualityCounts?
--- @field hand Vector? inserters: pickup position relative to the inserter

local look_alike = {}

--- Look-alike prototype name of an entity, nil if it has no static graphics.
--- @param entity LuaEntity
--- @return string?
function look_alike.name(entity)
    local name = constants.look_alike_prefix .. entity.name
    if prototypes.entity[name] then
        return name
    end
end

--- Picture variation matching the entity's direction and shape; the numbering is set in prototypes/look-alikes.lua.
--- @param entity LuaEntity
--- @return integer
function look_alike.variation(entity)
    local direction = math.floor(entity.direction / 4) -- 0..3 = north, east, south, west
    if entity.type == 'transport-belt' then
        return direction * 3 + BELT_SHAPE[entity.belt_shape] + 1
    end
    if entity.type == 'underground-belt' then
        return direction * 2 + (entity.belt_to_ground_type == 'output' and 1 or 0) + 1
    end
    if entity.type == 'pipe' then
        local mask = 0
        for _, connection in pairs(entity.get_fluid_box_pipe_connections(1) or {}) do
            if connection.target then
                local dx = connection.target_position.x - entity.position.x
                local dy = connection.target_position.y - entity.position.y
                mask = mask + (dy < -0.5 and 1 or dx > 0.5 and 2 or dy > 0.5 and 4 or 8)
            end
        end
        return mask + 1
    end
    return direction + 1
end

--- @param entity LuaEntity
--- @return Snapshot
function look_alike.snapshot(entity)
    local snapshot = {
        name = entity.name,
        position = entity.position,
        direction = entity.direction,
        quality = entity.quality.name,
        force = entity.force.name,
    }
    if constants.machine_types[entity.type] then
        local recipe, quality = rates.recipe_of(entity)
        snapshot.recipe, snapshot.recipe_quality = recipe and recipe.name, quality.name
    end
    if entity.type == 'underground-belt' then
        snapshot.type = entity.belt_to_ground_type
    end
    if entity.type == 'inserter' then
        local pickup = entity.pickup_position
        snapshot.hand = { x = pickup.x - entity.position.x, y = pickup.y - entity.position.y }
    end
    local modules = entity.get_module_inventory()
    if modules and not modules.is_empty() then
        snapshot.modules = modules.get_contents()
    end
    return snapshot
end

--- Rebuilds the real entity of a snapshot.
--- @param surface LuaSurface
--- @param snapshot Snapshot
function look_alike.restore(surface, snapshot)
    local entity = surface.create_entity({
        name = snapshot.name,
        position = snapshot.position,
        direction = snapshot.direction,
        quality = snapshot.quality,
        force = snapshot.force,
        type = snapshot.type,
    })
    if not entity then
        return
    end
    if snapshot.recipe and entity.type == 'assembling-machine' then
        entity.set_recipe(snapshot.recipe, snapshot.recipe_quality)
    end
    if snapshot.modules then
        local modules = entity.get_module_inventory()
        for _, stack in pairs(snapshot.modules) do
            modules.insert(stack)
        end
    end
end

--- Inserter arm reaching for the pickup like an idle inserter: a disabled arm entity (see prototypes/look-alikes.lua).
--- @param copy LuaEntity the look-alike
--- @param snapshot Snapshot of the entity it replaces
--- @return LuaEntity?
function look_alike.place_arm(copy, snapshot)
    local name, hand = constants.arm_prefix .. snapshot.name, snapshot.hand
    if not hand or not prototypes.entity[name] then
        return
    end
    local position = copy.position
    local pickup = { x = position.x + hand.x, y = position.y + hand.y }
    local arm = copy.surface.create_entity({
        name = name,
        position = position,
        direction = snapshot.direction,
        force = copy.force,
    })
    if not arm then
        return
    end
    -- ponytail: a custom pickup set here may not move a hand already resting at the default one; snapshot the hand
    -- position and rebuild if custom-vector mods look wrong.
    arm.pickup_position, arm.drop_position = pickup, pickup
    arm.disabled_by_script = true
    return arm
end

--- Recipe in the middle, one icon per module along the bottom, like alt mode, as icon entities (see
--- prototypes/look-alikes.lua).
--- @param copy LuaEntity the look-alike
--- @param snapshot Snapshot of the entity it replaces
--- @return LuaEntity[]
function look_alike.place_icons(copy, snapshot)
    local box, position = copy.selection_box, copy.position
    local width, height = box.right_bottom.x - box.left_top.x, box.right_bottom.y - box.left_top.y
    local icons = {}
    local function place(name, dx, dy)
        if prototypes.entity[name] then
            local icon = copy.surface.create_entity({
                name = name,
                position = { position.x + dx, position.y + dy - height * ICON_LIFT },
                force = copy.force,
            })
            icons[#icons + 1] = icon
            return icon
        end
    end
    if snapshot.recipe then
        local icon = place(constants.recipe_icon_prefix .. snapshot.recipe, 0, 0)
        if icon then
            local tiles = math.floor(math.min(width, height) + 0.5)
            icon.graphics_variation = math.max(1, math.min(constants.icon_sizes, tiles))
        end
    end
    if snapshot.modules then
        local modules = {}
        for _, stack in pairs(snapshot.modules) do
            for _ = 1, stack.count do
                modules[#modules + 1] = stack.name
            end
        end
        local dy = (height / 2 - constants.module_icon_scale / 2 - 0.1) * MODULE_RAISE
        for i, name in pairs(modules) do
            place(constants.module_icon_prefix .. name, (i - (#modules + 1) / 2) * MODULE_GAP, dy)
        end
    end
    return icons
end

return look_alike
