# Map Making (Factorio 2.0 / Space Age)

Covers the in-game map editor, the scenario system it feeds into, map
generator settings, and the built-in Tutorial campaign — the tools for
building and shipping custom maps/scenarios (as opposed to mod prototype or
runtime scripting APIs, covered elsewhere).

## Map editor

### Opening it

Three ways to open the map editor, per the wiki:

- Select "Map editor" from the main menu
- Console command `/editor`
- Press **CTRL + SHIFT + F11** in-game

Use `/editor` again to exit. **"Enabling the editor disables achievements."**

### Tool tabs

The Tools tab exposes these modes:

| Mode | What it does |
|---|---|
| None | Default mode: "instant blueprinting, deconstruction and upgrading" plus infinite crafting regardless of research status |
| Decoratives | Place/delete decorative objects with brush or cursor tools |
| Entities | Bulk place entities with brush/spray; includes a "build-as force" option to assign ownership |
| Forces | Create/delete forces; place red flags to set spawn locations |
| Resources | Create/delete resource patches; an intensity slider controls richness |
| Surfaces | Create/delete surfaces, change map generation settings, import save files as new surfaces |
| Tiles | Place any tile type; paint bucket tool replaces tile types; a variations tab randomizes graphics |
| Cloning | Copy map areas (with decoratives/tiles) or individual entities |
| Areas and positions | Create named world positions/areas accessible in scripts |
| Time | Pause/unpause, control tick speed, manage day/night cycle |
| Cliffs | Place cliffs in lines or individually; **R** and **SHIFT+R** rotate |
| Asteroid chunks | Place/delete chunks (space platform surfaces only) |

### Universal controls

- **Q** — clear cursor/deselect
- **Left mouse button** — place entities/tiles/decoratives
- **Right mouse button** — remove placed items
- **Numpad +/-** — increase/decrease brush or spray size

### Research shortcut

"In the technology GUI T technologies can be instantly researched by shift
clicking the research button after selecting the desired technology."

### Editor -> scenario pipeline

Maps can be saved as scenarios via the escape menu. The scenario can then be
played from Play -> Custom Scenario, or via a "save and play" option.
Scripting support is available by editing the `control.lua` file inside the
resulting scenario folder.

## Scenario system

A scenario is a "save-based mod" that allows custom content without a
separate mod install — used for "server side scripting, or to provide a
separate objective than the vanilla freeplay."

### Storage locations

- **User-created scenarios**: installed in a `scenarios` folder inside the
  player's user data directory; playable from the scenarios menu.
- **Mod-distributed scenarios**: packaged by adding a `scenarios` folder
  inside a mod's structure, with individual scenarios placed inside it.

### Required / optional files

- **Required**: `control.lua` — provides the runtime scripting.
- **Optional**: `description.json` — marks the scenario as multiplayer
  compatible and sets menu ordering.

`description.json` fields:

| Field | Notes |
|---|---|
| `multiplayer-compatible` | Boolean. Default: `false`. |
| `is-main-game` | Boolean. Default: `false`. |
| `order` | Order-type field, used for sorting in menus. |

### Localization

Scenario name/description use locale files with keys `scenario-name` and
`description` (used without category brackets).

### Hard restriction — no prototypes

Scenarios "cannot add any prototypes to the game." They lack "access to the
settings stage and data stage parts of the Data Lifecycle," relying "entirely
on runtime scripting via the control.lua file." In practice: a scenario can
script behavior and use existing prototypes, but cannot introduce new
items/entities/recipes the way a full mod (with `data.lua`) can.

### Distribution notes

- A server can distribute a scenario without clients having it installed
  separately.
- "Scenarios count as mods for the purpose of isolating achievements" — i.e.
  playing a scenario disables achievements the same way a mod does.
- "Scenarios must be packaged into a mod to be distributed on the mod
  portal" — there's no standalone scenario upload; it has to ride inside a
  mod's `scenarios` folder.

## Map generator settings

### Presets

| Preset | Key settings (per wiki) |
|---|---|
| Default | "Normal settings. The recommended way to play Factorio." All sliders centered, unlimited map dimensions, peaceful mode disabled. |
| Rich resources | Resource patches at 200% richness instead of 100%. |
| Marathon | Technologies more expensive; tech price multiplier set to 4. |
| Death world | 200% enemy base frequency and 200% enemy base size on Nauvis, 75% starting area size, faster evolution. |
| Death world marathon | Combines Marathon + Death world settings; wiki calls it suitable only "if you are a Factorio veteran." |
| Rail world | Large, widely-spread resource patches to encourage trains: resources at 33% frequency and 300% size; evolution time factor reduced to 20. |
| Ribbon world | **Map height limited to only 128 tiles.** Resources at 300% frequency, 50% size, 200% richness. |
| Lakes | Uses 1.1-era terrain generation; 50% tree coverage. |
| Island | Generates a large island in an endless ocean via the island terrain type; 50% tree coverage. |

### Setting groups

**Resources** — per-resource sliders:
- Frequency: patch count ("200% frequency means roughly double the patches")
- Size: patch dimensions ("200% means the surface area of the patch is doubled")
- Richness: ore yield per tile ("200% richness" roughly doubles ore content)

**Terrain**:
- Map type (island vs. normal endless terrain)
- Water: scale and coverage
- Trees: scale and coverage
- Cliffs: frequency and continuity
- Moisture & terrain type: bias and scale (controls grass/desert and red
  desert/sand distribution)
- Planet-specific sliders exist too: Vulcanus volcanism, Gleba water/plants

**Enemy**:
- Frequency & size of enemy bases
- Starting area size (radius kept free of enemy bases)
- Expansion settings: max distance, group sizes, cooldown intervals
- Evolution factors: time, destruction (spawner-kill), and pollution
  multipliers

**Advanced**:
- Map width / height limits
- Technology cost multiplier
- Pollution settings: absorption modifier, attack cost modifier, tree damage
  thresholds, diffusion ratio

### Seed

"The starting value for the random number generator" — same seed + same
settings reproduces the same world; different seeds with identical settings
produce different worlds.

### Map exchange string

A shareable, encoded string containing all generation settings; it can be
retrieved from save files via the load-screen interface (and imported back
to apply those settings to a new map). The wiki notes a separate "map
exchange string format" page exists for the technical encoding — not fetched
here, so the exact byte/format layout is **unverified** in this file.

### Map size / chunk generation

- Maximum map size: "2,000 x 2,000 kilometers; internally, this is a square
  2,000,000 tiles on a side," for a total area of 4 trillion square tiles.
- Chunks generate only as needed; an "invisible area of about 3 chunks wide
  is generated as a preloading mechanism" ahead of explored terrain.
- `Map_generation` is not a distinct wiki page — it serves the same
  `Map_generator` article, so no separate content was captured from it.

## Campaign (Tutorial)

The built-in campaign is called "Tutorial" and has 5 levels, in order:

1. **Crash** — mine resources and craft a burner mining drill and stone furnace.
2. **Mining outpost** — build furnaces and mining drills, defend against small
   biters, and accumulate 150 iron plates, 50 copper plates, and 75 coal.
3. **Power plant** — complete a steam engine setup (offshore pump, pipes,
   electric poles), then build 3 radars to scan 50 sectors.
4. **Science and automation** — build a lab, research stone walls and
   automobilism, construct a car, and defend against nearby biter nests.
5. **Abandoned rail base** — repair a destroyed factory, set up automated
   rail transport to ore mines, load a car with supplies including piercing
   rounds and solar panels, with further discoveries to explore.

"Completing the tutorial is not necessary to play freeplay" — it's an
optional story mode and doesn't unlock anything. The wiki page does not
describe any internal file/folder structure for the campaign, so none is
assumed here.

## Sources

- https://wiki.factorio.com/Map_editor (opening methods, achievements-disabled
  note, tool tab list and descriptions, universal controls, shift-click
  research shortcut, save-as-scenario / Custom Scenario / save-and-play
  pipeline)
- https://wiki.factorio.com/Scenario_system (scenario definition, storage
  locations, required/optional files, description.json fields and defaults,
  locale keys, no-prototypes restriction, server/client distribution,
  achievement isolation, mod-portal packaging requirement)
- https://wiki.factorio.com/Map_generator (preset list and effects, Resources/
  Terrain/Enemy/Advanced setting groups, Seed, map exchange string, maximum
  map size, chunk preloading)
- https://wiki.factorio.com/Map_generation (confirmed to serve the same
  content as Map_generator — no distinct page/content found)
- https://wiki.factorio.com/Tutorial (5-level list with per-level goals,
  completion-not-required note, absence of file/folder structure detail)
