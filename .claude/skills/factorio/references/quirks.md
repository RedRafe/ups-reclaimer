# Quirks & Common Mistakes

A grab-bag of counterintuitive behaviors and easy-to-make mistakes,
distilled from `references/modding-api.md`, `data-raw.md`, `mechanics.md`,
`space-age.md`, `trains-and-logistics.md`, and `mod-packaging.md`. Each
entry follows the same shape:

**what surprises people → why → what to do instead.**

## Scripting quirks

- **A snippet using `global` isn't wrong, it's old.** Factorio 2.0 renamed
  the persistent per-mod data table from `global` to `storage` — "Before
  2.0, the `storage` table was called `global`." → Port `global.foo`
  references to `storage.foo` when adapting 1.1-era mod code.

- **Storing an entity reference doesn't keep it alive.** Holding onto a
  `LuaEntity` (or player, surface, etc.) in `storage` does not stop the
  underlying game object from being destroyed later; the Lua handle simply
  goes stale. → Always check `.valid` before reading or calling methods on
  a stored `LuaObject` — an invalid object errors on access.

- **`game` looks available in `on_load()`, but touching it there breaks
  multiplayer.** `on_load()` runs on every load (including clients joining
  a multiplayer game) with `storage` read-only and `game` absent; per the
  docs, doing more than re-hooking metatables/handlers "will lead to
  desyncs, breaking both multiplayer and replays." → In `on_load()`, only
  re-establish metatables and re-register handlers based on data already
  in `storage` — do all real initialization in `on_init()` /
  `on_configuration_changed()`.

- **Plain Lua locals quietly vanish across a save/load.** Only the
  `storage` table is serialized into the save; upvalues and local
  variables set during control-stage execution reset on load, and
  multiplayer clients resync via save/load-like mechanisms constantly. →
  Put anything that needs to survive a tick boundary or a save into
  `storage` — the wiki tutorial calls this the fix for "99% of possible
  desyncs."

- **A function stashed in `storage` fails at save time, not write time.**
  `storage` can hold nil/string/number/boolean/tables/`LuaObject`
  references, but not functions. → Store data (e.g. a function *name* or
  state flags) and re-derive behavior from it, instead of storing closures.

- **Registering a second handler for the same event silently replaces the
  first**, it doesn't add a second listener — `script.on_event` keeps only
  one handler per event ID. → If multiple pieces of logic need to react to
  the same event, dispatch to both from a single registered handler.

- **`math.randomseed()` looks like it should reseed, but does nothing.**
  `math.random()` is deterministic, seeded from the map seed, for
  reproducibility/multiplayer-sync reasons — calling `math.randomseed()`
  has no effect. → Use a separate `LuaRandomGenerator` instance when a mod
  needs an independent random stream that isn't tied to the map seed.

- **A locally-tweaked mod file breaks multiplayer even if the tweak "does
  nothing."** The game compares mod checksums between peers at connect
  time specifically "to ensure everyone has exactly the same mod in order
  to prevent desyncs caused by local changes made to mod files" — any byte
  difference counts, regardless of whether the change is meaningful. → Ship
  mod changes as a proper version bump distributed to every player, not as
  an untracked local edit.

## Prototype/data-stage quirks

- **Defining a prototype "late" can silently skip other mods' logic.**
  Because `data.lua` → `data-updates.lua` → `data-final-fixes.lua` each run
  as one round across *every* mod, something you add in
  `data-final-fixes.lua` didn't exist when other mods' `data-updates.lua`
  already ran — the docs' own example: adding a fluid in
  `data-final-fixes.lua` means "no barrelling recipe gets created," because
  barrelling recipes are generated during `data-updates.lua`. → Define new
  prototypes as early as possible (`data.lua`); reserve
  `data-updates.lua`/`data-final-fixes.lua` for edits to things that must
  already exist.

- **Editing another mod's prototype "usually works" until load order
  shifts.** Any mod can reach into `data.raw` and mutate a prototype
  another mod already defined, with no API call needed — but without a
  declared dependency, whether your edit runs *before or after* theirs
  depends only on the load-order rule ("dependency, then alphabetical").
  → Add the mod you're patching as a dependency in `info.json` so your
  `data-updates.lua`/`data-final-fixes.lua` is guaranteed to run after it.

- **You cannot invent a new prototype *type*, only new named entries inside
  existing types.** The wiki is explicit: "it is not possible to add a new
  type to Factorio, without asking the developers to do it" — types are an
  engine-level concept. → Work within the existing ~251 prototype types
  (recipe, item, entity subtypes, etc.); anything that needs a genuinely
  new type requires an engine change, not a mod.

- **Helper variables written during the data stage don't survive into
  gameplay.** The whole settings/prototype Lua state is discarded once
  each stage finishes — "no variables or functions defined in it will
  carry over" — and prototypes are then frozen for the rest of the
  session. → Don't expect a data-stage local to be readable later; runtime
  code that needs persistent state uses `storage` instead (see Scripting
  quirks above).

## Localisation & mod-packaging quirks

- **A `LocalisedString` parameter must be a string, even if it looks like a
  number or boolean.** Passing a raw number/boolean as a parameter — e.g.
  `{"x", 42}` — throws "Value must be a string" at both data and control
  stage; only string parameters (including other `LocalisedString` tables)
  are accepted. → Wrap non-string values with `tostring()` before passing
  them as `LocalisedString` parameters. (Tutorial:Localisation — see
  `mod-packaging.md`.)

## Mechanics quirks

- **The belt-throughput table header says "stacks/second," but the numbers
  are plain items/second.** The wiki footnotes that "the 'stacks' below
  refers to stacks created by a stack inserter, not inventory stacks" — so
  the commonly quoted 15/30/45/60 figures for
  transport/fast/express/turbo belts are items/s, not something you need
  to multiply by a stack size. → Use 15/30/45/60 directly as items/second
  when sizing belt throughput; don't rescale by inventory stack size.

- **Flat armor/resistance can never bring damage to zero, no matter how
  high it goes.** The resistance formula's flat component `R` only
  asymptotically approaches a floor above 0 damage — only a 100%
  *percentage* resistance grants true immunity to a damage type. → To make
  something actually immune to a damage type, look for 100% percentage
  resistance, not a large flat value.

- **Containing pollution locally doesn't slow the biters down.** The wiki
  is explicit that "evolution factor is not increased by spreading/absorbed
  pollution, but by pollution produced by all machinery at every tick" —
  scrubbing/absorbing pollution near your base does nothing for the global
  evolution factor. → To slow evolution, reduce pollution *production*
  (efficiency modules, electric over burner, etc.), not just its local
  spread.

- **Solar panels don't get "throttled down" to share load with other
  generators — they always run flat-out.** Per the *Electric system* page,
  demand is met by solar panels first "at maximum performance available,"
  then steam/turbine/fusion sources fill the remainder, and accumulators
  only discharge once those can't keep up. → When diagnosing a brownout,
  check total generation capacity and demand together — solar output isn't
  the variable that flexes down when accumulators are also present.

- **Circuit signal math can wrap around instead of erroring.** Signals are
  signed 32-bit integers (−2,147,483,648..2,147,483,647), so an arithmetic
  combinator computing e.g. `2147483647 + 10` produces `-2147483639`
  instead of a larger number or an overflow error. → Guard arithmetic
  combinator chains against overflow explicitly if the signal could
  realistically approach ~2.1 billion.

- **A combinator wired back into its own input doesn't update
  instantaneously, but it does compound every tick.** Feeding a
  combinator's output into its own input creates a loop that "shoot[s]
  upward" quickly (tick-rate speed) rather than all at once — useful
  deliberately as a counter, but an easy accidental runaway if wired
  without meaning to. → Only build a self-referencing combinator loop on
  purpose (e.g. as a clock/counter), and expect its value to climb once
  per tick, not instantly.

- **A chain signal can wave a train through even though the exit ahead is
  blocked.** The look-ahead only applies when *more signals remain* between
  the chain signal and the train's destination — if the destination is
  reachable from that chain signal without crossing any further signal, the
  chain signal doesn't reserve/check the far block at all, so a train can
  be sent toward a blocked dead-end/final stop. → Put a plain rail signal
  (not a chain signal) at the boundary when a hard stop is needed near a
  dead-end or final stop. (Rail_chain_signal — see
  `trains-and-logistics.md`.)

## Space Age quirks

- **Quality-ingredient crafting needs an *exact* tier match, not "at
  least."** To produce a higher-quality item via quality ingredients, every
  ingredient must be exactly the target quality — "you cannot combine
  uncommon iron plates with rare batteries." → Stockpile ingredients at a
  single matching quality tier per craft; mixing tiers (or using a
  higher-tier ingredient than needed) doesn't help.

- **A successful quality-module roll doesn't stop at one tier bump.** After
  a quality module's chance succeeds and upgrades the product one tier,
  the machine "repeats the roll at a flat 10% chance" to upgrade again,
  continuing until a roll fails — so Normal-to-Legendary in one craft is
  possible, just geometrically rare. → Don't assume a quality module only
  ever produces the next tier up; a small fraction of successes will jump
  multiple tiers in one craft.

- **Recycling isn't a free way to grind for quality — it destroys most of
  the material.** Recyclers return only 25% of input items, so the wiki's
  own guidance is to push quality upgrades right before the final target
  item (recycling loses too much material) *unless* a productivity
  research exists for that item, in which case the loop becomes free of net
  material cost. → Recycle-loop for quality only late in a chain, or when
  productivity research offsets the 75% material loss.

- **Legendary isn't "one step above Epic" the way the tier list makes it
  look.** Quality tiers have a numeric *strength* that drives all bonus
  scaling (Normal 0, Uncommon 1, Rare 2, Epic 3, Legendary 5) — Legendary
  is a 2-strength jump over Epic, not a uniform +1 like the earlier steps.
  → When calculating quality bonus scaling, use tier strength, not tier
  ordinal position.

- **Spoilage doesn't pause anywhere, including mid-transfer.** The spoilage
  timer keeps running "in machines, belts and even when being held by an
  inserter" — there's no way to freeze an item's clock short of raising its
  quality. → Design Gleba-style lines to keep spoilable items moving
  through their full path quickly; parking them in a buffer chest doesn't
  buy extra time.

- **`LuaPlanet` existing doesn't mean its surface exists yet.** A
  `LuaPlanet`'s `surface` field is read-only and a planet does **not**
  auto-generate its surface — the surface must be created explicitly via
  `create_surface()` (or linked with `associate_surface()`). → Don't assume
  `planet.surface` is populated just because `game.planets[name]` exists;
  check for `nil` and generate/associate the surface first.

- **You can't drop a train stop wherever elevated rail runs.** Both regular
  and chain rail signals work on elevated track, but train stops
  specifically cannot be placed there, and a rail support must be placed
  at least every 16 straight tiles or the elevated section has nothing
  holding it up. → Route elevated track through a station only by dropping
  back to ground level first; plan support spacing at ≤16 tiles on long
  elevated runs.

## Sources

- https://lua-api.factorio.com/latest/index.html
- https://lua-api.factorio.com/latest/auxiliary/data-lifecycle.html
- https://lua-api.factorio.com/latest/auxiliary/storage.html
- https://lua-api.factorio.com/latest/auxiliary/libraries.html
- https://lua-api.factorio.com/latest/classes/LuaEntity.html
- https://lua-api.factorio.com/latest/classes/LuaPlanet.html
- https://lua-api.factorio.com/latest/events.html
- https://lua-api.factorio.com/latest/prototypes.html
- https://wiki.factorio.com/Tutorial:Scripting
- https://wiki.factorio.com/Tutorial:Modding_tutorial/Gangsir
- https://wiki.factorio.com/Data.raw
- https://wiki.factorio.com/Multiplayer
- https://wiki.factorio.com/Belt_transport_system
- https://wiki.factorio.com/Damage
- https://wiki.factorio.com/Resistance
- https://wiki.factorio.com/Pollution
- https://wiki.factorio.com/Electric_system
- https://wiki.factorio.com/Circuit_network
- https://wiki.factorio.com/Quality
- https://wiki.factorio.com/Spoilage
- https://wiki.factorio.com/Elevated_rail
- https://wiki.factorio.com/Rail_chain_signal
- https://wiki.factorio.com/Tutorial:Localisation
