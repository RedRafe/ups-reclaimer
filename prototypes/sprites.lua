-- Turns animated entity graphics into static sprites.
local copy = require('util').table.deepcopy

local SPRITE_KEYS = {
    'filename',
    'priority',
    'flags',
    'size',
    'width',
    'height',
    'x',
    'y',
    'position',
    'shift',
    'scale',
    'draw_as_shadow',
    'draw_as_glow',
    'tint',
    'apply_runtime_tint',
    'blend_mode',
}

local sprites = {}

--- Direction names in the order of direction indices 0..3.
sprites.directions = { 'north', 'east', 'south', 'west' }

local function size(sprite)
    local width = sprite.width or (type(sprite.size) == 'table' and sprite.size[1]) or sprite.size
    local height = sprite.height or (type(sprite.size) == 'table' and sprite.size[2]) or sprite.size
    return width, height
end

--- Appends a sprite, or each of its layers, to layers. nil is skipped.
function sprites.flatten(layers, sprite)
    if not sprite then
        return
    end
    if sprite.layers then
        for _, layer in pairs(sprite.layers) do
            layers[#layers + 1] = layer
        end
    else
        layers[#layers + 1] = sprite
    end
end

--- Layers several sprites (nil allowed) into one, in argument order.
function sprites.merge(...)
    local layers = {}
    for i = 1, select('#', ...) do
        sprites.flatten(layers, (select(i, ...)))
    end
    return #layers > 0 and { layers = layers } or nil
end

--- First frame of the index-th direction of a (rotated) animation, as a static Sprite. nil if the layout is unsupported.
function sprites.first_frame(animation, index)
    if not animation then
        return
    end
    if animation.layers then
        local layers = {}
        for _, layer in pairs(animation.layers) do
            if not layer.draw_as_light then
                sprites.flatten(layers, sprites.first_frame(layer, index))
            end
        end
        return #layers > 0 and { layers = layers } or nil
    end
    local sprite = {}
    for _, key in pairs(SPRITE_KEYS) do
        sprite[key] = animation[key]
    end
    local frame = (index - 1) * (animation.frame_count or 1)
    if frame == 0 then
        if not sprite.filename then
            local stripe = animation.stripes and animation.stripes[1]
            if stripe then
                sprite.filename, sprite.x, sprite.y = stripe.filename, stripe.x, stripe.y
            elseif animation.filenames then
                sprite.filename = animation.filenames[1]
            else
                return
            end
        end
        return sprite
    end
    if not animation.filename then
        return -- multi-file rotated animations are not supported
    end
    local width, height = size(animation)
    local origin_x = animation.x or (animation.position and animation.position[1]) or 0
    local origin_y = animation.y or (animation.position and animation.position[2]) or 0
    local line_length = (animation.line_length and animation.line_length > 0) and animation.line_length
        or animation.frame_count
        or 1
    sprite.position = nil
    sprite.x = origin_x + (frame % line_length) * width
    sprite.y = origin_y + math.floor(frame / line_length) * height
    return sprite
end

--- Direction 0..3 of an Animation4Way.
function sprites.animation_direction(animation, direction)
    return animation and (animation[sprites.directions[direction + 1]] or animation.north or animation)
end

--- Direction 0..3 of a Sprite4Way, as a Sprite.
function sprites.sprite_direction(sprite, direction)
    if not sprite then
        return
    end
    if sprite.north then
        return copy(sprite[sprites.directions[direction + 1]] or sprite.north)
    end
    local sheets = sprite.sheets or (sprite.sheet and { sprite.sheet })
    if not sheets then
        return copy(sprite)
    end
    local layers = {}
    for _, sheet in pairs(sheets) do
        local layer = {}
        for _, key in pairs(SPRITE_KEYS) do
            layer[key] = sheet[key]
        end
        local width = size(sheet)
        layer.position = nil
        layer.x = (sheet.x or 0) + (direction % (sheet.frames or 4)) * width
        layer.y = sheet.y or 0
        layers[#layers + 1] = layer
    end
    return { layers = layers }
end

--- An item or recipe icon (icon/icons fields) as a Sprite tiles wide. Icon shifts and default scales assume a 32
--- unit canvas (expected_icon_size / 2).
function sprites.icon(prototype, tiles)
    local icons = prototype.icons or (prototype.icon and { { icon = prototype.icon, icon_size = prototype.icon_size } })
    if not icons then
        return
    end
    local layers = {}
    for _, icon in pairs(icons) do
        local icon_size = icon.icon_size or 64
        local shift = icon.shift or { 0, 0 }
        layers[#layers + 1] = {
            filename = icon.icon,
            size = icon_size,
            scale = tiles * (icon.scale or 32 / icon_size),
            shift = { (shift[1] or shift.x or 0) * tiles / 32, (shift[2] or shift.y or 0) * tiles / 32 },
            tint = icon.tint,
            flags = { 'icon' },
        }
    end
    return { layers = layers }
end

--- Copy of a single-layer sprite scaled to tiles wide.
function sprites.sized(sprite, tiles)
    sprite = copy(sprite)
    sprite.scale = 32 * tiles / size(sprite)
    return sprite
end

--- Copy with every layer moved by (dx, dy) tiles.
function sprites.shifted(sprite, dx, dy)
    if not sprite then
        return
    end
    sprite = copy(sprite)
    for _, layer in pairs(sprite.layers or { sprite }) do
        local shift = layer.shift or { 0, 0 }
        layer.shift = { (shift[1] or shift.x or 0) + dx, (shift[2] or shift.y or 0) + dy }
    end
    return sprite
end

return sprites
