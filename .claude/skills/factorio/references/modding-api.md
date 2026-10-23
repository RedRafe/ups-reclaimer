# Modding / Scripting Runtime API

Factorio mods are plain Lua. A mod's behavior is split across three
sequential stages, each with its own Lua state and its own subset of the
API. Get the stage wrong (e.g. touch `game` where it isn't available) and
the mod errors or, worse, desyncs a multiplayer game.

## The three stages

| Stage | Files loaded | Purpose | What's available |
|---|---|---|---|
| **Settings** | `settings.lua`, `settings-updates.lua`, `settings-final-fixes.lua` (three "rounds", run once per round across all mods) | Define mod-setting prototypes (startup/runtime options shown in the UI) | `data` table (for setting prototypes) and a `mods` table mapping mod name → version |
| **Prototype (data)** | `data.lua`, `data-updates.lua`, `data-final-fixes.lua` (same three-round structure) | Define/modify prototypes: entities, recipes, items, technologies, etc. | `data` table, plus a `settings` table populated with the startup mod settings resolved in the previous stage |
| **Control (runtime)** | `control.lua` and whatever it `require`s | Actual gameplay logic: react to events, spawn entities, run game logic | The full runtime API — `game`, `script`, `rendering`, `storage`, etc. |

Each of the settings and prototype stages runs in a shared Lua state that
is **discarded** once the stage completes — nothing defined there (local
variables, functions) carries over. Once the prototype stage ends,
prototypes are frozen for the rest of that game/session. The control
stage is different: each mod gets its own **persistent** Lua state that
lives for the lifetime of the save.

*(Source: lua-api.factorio.com index + `auxiliary/data-lifecycle.html`)*

## Global state & determinism

**Factorio 2.0 renamed the mod persistent-data table from `global` to
`storage`.** Per the official docs: *"Before 2.0, the `storage` table was
called `global`."* If you see a mod or tutorial snippet using `global`,
it is pre-2.0 code and should be ported to `storage`.

`storage` is a Lua table, unique per mod, that is automatically serialized
into the save file and restored on load. It can hold nil, strings,
numbers, booleans, tables (including ones with registered metatables),
and references to Factorio `LuaObject`s (e.g. entities, players) — but
**not functions**; trying to save a function in `storage` errors.

Any data a mod needs to survive from one tick/event to the next, or from
save to load, **must** live in `storage`. Local/upvalue Lua variables set
during control-stage execution do not persist across a save/load cycle,
and since multiplayer clients periodically resync via save/load-like
mechanisms, relying on non-`storage` state is a common source of
desyncs. As the wiki tutorial puts it: *"If you want to use something
between ticks then store it in storage. This will prevent 99% of
possible desyncs."*

Three special lifecycle handlers manage `storage` and initialization:

| Handler | Fires when | `storage` access | `game` access |
|---|---|---|---|
| `on_init()` | New save, or a mod is newly added to an existing save | Full read/write | Full access |
| `on_load()` | Every time a save with this mod already in it is loaded (including joining multiplayer) | **Read-only** — writing to it is an error | **Not available** |
| `on_configuration_changed()` | Game version, mod versions, mod list, startup settings, or prototypes changed since last save | Full read/write | Full access |

Because `game` is unavailable in `on_load()`, its only legitimate uses are:
re-establishing metatables on tables already in `storage`, conditionally
(re-)registering event handlers based on data already in `storage`, and
creating local references to data already in `storage`. Anything beyond
that during `on_load()` "will lead to desyncs, breaking both multiplayer
and replays."

*(Source: `auxiliary/data-lifecycle.html`, `auxiliary/storage.html`, wiki `Tutorial:Scripting`)*

## Core objects

### `game` (LuaGameScript)

Only available in the control stage (and not inside `on_load()`). Key members:

| Member | Kind | Notes |
|---|---|---|
| `game.tick` | property (read-only) | Current map tick |
| `game.ticks_played` | property (read-only) | Ticks since game creation; keeps counting when paused |
| `game.players` | property (read-only) | All players, indexable by number or name |
| `game.surfaces` | property (read-only) | All surfaces, indexable by number or name |
| `game.forces` | property (read-only) | All forces, indexable by number or name |
| `game.connected_players` | property (read-only) | Only currently-online players |
| `game.speed` | property (read/write) | Game speed multiplier (1.0 = normal 60 UPS) |
| `game.tick_paused` | property (read/write) | Whether the simulation is paused |
| `game.print(message, print_settings?)` | method | Broadcast a chat message to all players |
| `game.get_player(player)` | method | Look up one player by index or name |
| `game.get_surface(surface)` | method | Look up one surface by index or name |
| `game.create_surface(name, settings?)` | method | Create a new surface |
| `game.create_force(force)` | method | Create a new force |

*(Source: `classes/LuaGameScript.html`)*

### `script` — event registration & lifecycle

`script` is the object (a `LuaBootstrap`) used to register the lifecycle
handlers above and all runtime events:

```lua
script.on_init(function() ... end)
script.on_load(function() ... end)
script.on_configuration_changed(function(data) ... end)
script.on_event(defines.events.on_tick, function(event) ... end)
```

Only **one handler per event** can be registered this way — registering
a second one overwrites the first, so mods that need multiple reactions
to the same event must dispatch internally.

*(Source: `events.html`, wiki `Tutorial:Scripting`)*

### `LuaSurface`

The main object for querying and mutating a map surface (Nauvis, or any
other planet/platform surface). Frequently-used members:

| Member | Purpose |
|---|---|
| `create_entity{name, position, direction?, force?, quality?, ...}` | Create an entity on the surface (also accepts entity-specific fields like `recipe` for assemblers). Returns the entity or `nil` on failure. |
| `find_entity(name, position)` | Find a single entity of a given name at/near a position. Returns `nil` if not found. |
| `find_entities_filtered{type?, name?, force?, area?, radius?, ...}` | Search for entities matching one or more filters; more efficient than scanning manually. |
| `get_tile(x, y)` | Get the tile at a coordinate. |
| `set_tiles(tiles, correct_tiles?, remove_colliding_entities?, ...)` | Bulk-place tiles. |
| `request_to_generate_chunks(position, radius?)` | Ask the map generator to generate chunks around a point. |
| `is_chunk_generated(chunk_position)` | Check whether a chunk already exists. |
| `get_chunks()` | Iterate all chunks on the surface. |
| `force_generate_chunk_requests()` | Block until pending chunk-generation requests finish. |

*(Source: `classes/LuaSurface.html`)*

### `LuaEntity`

The handle for a placed entity (machine, resource, character, etc.).
Common members:

| Member | Purpose |
|---|---|
| `valid` | Whether the underlying game object still exists. **Must be checked** before use — see gotchas below. |
| `name` | Prototype name, e.g. `"inserter"`, `"transport-belt"`. |
| `type` | Prototype type, e.g. `"furnace"`, `"transport-belt-connectable"`. |
| `position` | World coordinates. |
| `surface` | The `LuaSurface` the entity lives on. |
| `force` | Owning force. |
| `direction` | Facing, a `defines.direction` value. **16-way in 2.0** (range 0–15): N=0, E=4, S=8, W=12, with intermediates in between (e.g. NE=2). Pre-2.0 was 8-way (0–7), so old code setting `direction = 2` for East is wrong under 2.0. |
| `health` | Current health (read/write); `nil` for entities without health. |
| `destroy(params?)` | Remove the entity (options for cliff correction, effects, undo). |
| `get_inventory(index)` | Get one of the entity's inventories, or `nil`. |

*(Source: `classes/LuaEntity.html`; `direction` values from `defines.html` → `defines.direction`)*

## Events

Register handlers with `script.on_event`, passing an event ID from
`defines.events` and a callback:

```lua
script.on_event(defines.events.on_tick, function(event)
  -- event.tick is available on every event
end)
```

Every event's parameter table includes `name` (the `defines.events` id)
and `tick` (the game tick it fired on), plus event-specific fields.
Commonly used events:

| Event | Fires when |
|---|---|
| `on_tick` | Every game tick |
| `on_built_entity` | A player constructs an entity |
| `on_entity_died` | Any entity is destroyed |
| `on_player_created` | A player character spawns |
| `on_chunk_generated` | Map terrain finishes generating for a chunk |
| `on_research_finished` | A technology completes |

Some events support **filters** so a mod only receives the subset it
cares about (e.g. filtering `on_built_entity` by entity type, or
`on_entity_damaged` by damage type) — this is more efficient than
filtering inside the handler. For running code on a fixed interval
instead of every tick, use `script.on_nth_tick(n, handler)`.

*(Source: `events.html`)*

## Libraries available to mods

Factorio runs a modified Lua **5.2.1** (per the wiki's Modding overview page) with determinism-motivated restrictions:

- `loadfile`, `dofile`, `coroutine`, `io`, and `os` are **not available**.
- `print()` writes to stdout only (use `log()` to write to the Factorio log; `log()` accepts LocalisedStrings).
- `require()` is rooted at the mod's own directory, but can reach into `__core__`'s `lualib` or another mod's files via `require("__mod-name__.file")`.
- `math.random()` is deterministic and seeded from the map seed; `math.randomseed()` has no effect — use `LuaRandomGenerator` for independent random streams.
- `pairs()`/`next()` iterate in insertion order (and the first 1024 integer keys iterate 1–1024) for determinism.
- `serpent` is available globally for debug-printing tables (comments off by default, for determinism).
- Backported Lua 5.4 `string.pack`/`packsize`/`unpack` for binary-format strings.
- `table_size()` is provided for fast table-size queries on non-contiguous tables.

*(Source: `auxiliary/libraries.html`)*

## Installing & distributing mods

- **Installation:** a mod downloaded as a ZIP file is installed by copying
  the ZIP **as-is (not unzipped)** into the `mods` directory in the user data
  directory.
- **Required dependency:** a mod that another mod needs in order to
  function; the in-game mod portal downloads required dependencies
  automatically when you download a mod.
- **Optional dependency:** a mod that another mod suggests but doesn't need
  to work; it can add functionality without being mandatory.
- **Incompatibility:** mods can declare each other incompatible, which
  prevents them from being loaded together.
- **Multiplayer auto-sync:** joining a multiplayer server that uses mods
  makes the game "offer to synchronize the mods with the server" — accepting
  downloads/enables the exact same mod set and versions the server is using.

*(Source: `wiki.factorio.com/Modding`)*

## Common gotchas

- **`storage`, not `global`.** Factorio 2.0 renamed the persistent mod-data table from `global` to `storage`; any 1.1-era snippet using `global` needs porting.
- **Check `.valid` before touching a stored `LuaObject`.** Entities, players, surfaces, etc. can become invalid (destroyed, migrated, etc.) between the time you stored a reference and the time you use it; accessing an invalid object errors.
- **Don't touch `game` inside `on_load()`.** It isn't available there — see the Global state & determinism section. Doing more than re-hooking metatables/handlers there can desync multiplayer and break replays.
- **Don't rely on plain Lua locals/upvalues to survive across ticks or saves.** Only `storage` is serialized; everything else resets on load.
- **Functions can't go in `storage`.** Storing a function in the persistent table causes a save error — store data and re-derive behavior instead.
- **One handler per event via `script.on_event`.** Re-registering the same event overwrites the previous handler rather than adding a second listener.
- **Prototypes are frozen after the data stage.** You cannot add/modify prototypes from `control.lua`; that must happen in `data.lua`/`data-updates.lua`/`data-final-fixes.lua`.

## Sources

- https://lua-api.factorio.com/latest/index.html
- https://lua-api.factorio.com/latest/auxiliary/data-lifecycle.html
- https://lua-api.factorio.com/latest/auxiliary/storage.html
- https://lua-api.factorio.com/latest/classes/LuaGameScript.html
- https://lua-api.factorio.com/latest/classes/LuaSurface.html
- https://lua-api.factorio.com/latest/classes/LuaEntity.html
- https://lua-api.factorio.com/latest/defines.html
- https://lua-api.factorio.com/latest/events.html
- https://lua-api.factorio.com/latest/auxiliary/libraries.html
- https://wiki.factorio.com/Tutorial:Scripting
- https://wiki.factorio.com/Modding
