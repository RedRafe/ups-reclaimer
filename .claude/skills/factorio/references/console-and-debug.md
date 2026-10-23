# Console & Debug Mode

Two distinct tools for inspecting/testing a *running* game: debug mode
(visual/perf overlays) and the console (commands + Lua). Both are aimed at
developers, modders, and map-makers who need to see or manipulate live game
state rather than just read prototypes/API docs.

## Debug mode

Debug mode "is used mainly by developers and modders to analyze the running
state of the game."

- **F5** — default key to toggle debug mode on/off ("Allows to toggle the
  debug overlays").
- **F4** — opens the configuration menu for debug options. The menu has
  **2 folders**, one per debug-mode ("always", "debug"), so an option can be
  configured differently depending on which folder it lives in. A search box
  (**Ctrl+F**) is available to find options by name.

### Useful `show-*` toggles

| Toggle | What it shows |
|---|---|
| `show-fps` | Frames-per-second and updates-per-second |
| `show-time-usage` | Internal statistics on how long some calculations take, in milliseconds |
| `show-detailed-info` | Cursor position in tiles, resolution, zoom, and entity counts |
| `show-tile-grid` | Borders of the tiles and chunks |
| `show-collision-rectangles` | Collision box of each entity (red) |
| `show-selection-rectangles` | A blue box over each entity |
| `show-render-rectangles` | A pink box over each entity |
| `show-entity-positions` | Entity location markers |
| `show-entity-velocities` | Entity movement/speed vectors |
| `show-paths` | Calculated paths for biters, in different colors |
| `show-target` | Current target of the biters (red) |
| `show-circuit-network-numbers` | The number (and color) of circuit networks |
| `show-debug-info-in-tooltips` | Additional debug info in entity tooltips |

The Debug_mode page lists many more `show-*` options (trains, rail
pathfinding, pollution, sound, robots, etc.) accessible the same way via
F4 → Ctrl+F search; the table above covers the toggles most relevant to
everyday inspection/testing.

## Console

### Opening it

Toggle with the **grave/backtick key** (`` ` ``, left of `1`, above `Tab`).
Rebindable in Settings → Controls, under **"Toggle chat (and Lua console)."**

### Command categories

The wiki groups console commands into three kinds:

1. **Normal commands** — display game information / customize the experience.
2. **Multiplayer commands** — message filtering, banning, player management.
3. **Scripting/cheating commands** — execute Lua; these disable achievements.

### Lua prefixes

| Prefix | Long form | Behavior |
|---|---|---|
| `/c` | `/command` | Execute a Lua command |
| `/sc` | `/silent-command` | Execute Lua without printing the result to console |
| `/mc` | `/measured-command` | Execute Lua and measure/report its execution time |

**Running any script/Lua command (`/c`, `/sc`, `/mc`) permanently disables
achievements for that save** — the wiki states plainly that using a script
command "disable[s] achievements for the save game."

The console can access the `game` object directly, the same way `control.lua`
does — e.g. `game.player.print()` or
`game.player.force.research_all_technologies()`. Other example snippets
noted on the page: evaluating plain math (`1234*5678`), and adjusting zoom,
crafting/mining speed, or teleporting a player.

### Built-in commands mentioned

| Command | Purpose |
|---|---|
| `/help` | List available commands |
| `/seed` | Show the map seed |
| `/time` | Show elapsed game time |
| `/players` | List players |
| `/admins` | List admins |
| `/ban` | Ban a player |
| `/promote` / `/demote` | Grant/revoke admin |
| `/screenshot` | Capture a screenshot with hidden GUIs |
| `/alerts` | Configure which alert types show |
| `/clear` | Clear the console display |

### Singleplayer vs. multiplayer

The page doesn't call out singleplayer-specific console behavior beyond the
fact that the multiplayer-only commands (banning, promote/demote, player
listing) exist because there are other players to manage; no other
single- vs. multiplayer distinction is stated.

## Performance / UPS diagnosis

Per the wiki's *Tutorial:Diagnosing performance issues* page.

**Debug toggles to enable first (F4):** `show-time-usage` (per-system
timing breakdown) and `show-entity-time-usage` (breaks the entity-manager
cost down by entity type); `hide-mod-guis` is also recommended so mod
windows don't obscure the readout. The time-usage display reports
"average time, minimum time, and maximum time taken by the system over
the last 100 ticks." To widen that sampling window, the console command
`/perf-avg-frames 1000` expands analysis beyond the default (~2 seconds
of ticks).

**The budget:** the game "aims for 60 FPS and UPS," giving "16.667ms to
calculate each tick." Guidance from the page: "Anything above 1ms may be
worth looking into, and anything above 5 is very significant" for any
single line item in the time-usage breakdown.

**GPU-bound vs. simulation-bound:** compare FPS against UPS (`show-fps`).
Low FPS with high UPS points to a graphics (GPU-bound) problem; low FPS
*with* low UPS points to a simulation (CPU-bound) problem, and only the
latter warrants the deeper UPS-specific diagnosis below.

**Named UPS bottlenecks**, per the page:
- **Entity manager** — usually the largest single cost; use the
  entity-time-usage screen to see which entity types dominate.
- **Circuit networks** — "use fewer combinators and other circuit
  connections."
- **Fluid/pipe networks** — "reduce your amount of pipes... replace
  nuclear power with solar power" (nuclear setups are called out as
  especially costly on this axis).
- **Electric networks** — cost scales with "the number of different
  electric networks, not their size," i.e. many small separate networks
  are worse than one big one.
- **Train pathing** — mitigated by using "fewer but bigger trains."
- **Mods** — script update time can dominate; the page's remedy is to
  identify and uninstall the offending mod.

**Optimization tips**, per the page:
- Prefer underground pipes over long pipe runs — each underground pipe
  pair only counts as 2 fluid entities versus 3+ for the equivalent run
  of regular pipes.
- Prefer solar over nuclear power for UPS (independent of raw power
  output considerations).
- Prefer fewer, faster machines (with beacons/modules) over many slow
  machines — the page states this "will cost less" in UPS terms.
- Reduce inserter swing frequency ("inserter clocking") rather than
  letting inserters swing on every possible cycle.
- Consolidate electric networks into fewer, larger networks rather than
  many small separate ones (per the electric-network bottleneck above).
- Reduce the number of radars in use.

## Sources

- https://wiki.factorio.com/Debug_mode
- https://wiki.factorio.com/Console
- https://wiki.factorio.com/Tutorial:Diagnosing_performance_issues
