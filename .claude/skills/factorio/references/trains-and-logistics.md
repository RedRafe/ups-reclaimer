# Trains & Logistics Reference (Factorio 2.0 / Space Age)

Distilled from the Factorio wiki. Every fact below was pulled from the specific page cited in `## Sources`; anything not confirmed there is marked **unverified**.

## Rail signals & blocks

A **block** is the section of track between signals. Per the wiki: "Blocks span all connected rails regardless of whether a train can actually travel between them." Both rail signals and chain signals are what divide the rail network into blocks.

**Rail signal states** (regular, non-chain signals):

| State | Meaning (verbatim) |
|---|---|
| Green | "The monitored block is empty." |
| Yellow | "A train is not able to stop before the monitored block and will pass the signal." (a train is already approved to enter the following block) |
| Red | "The monitored block is not empty or another signal monitoring it is yellow." |
| Blinking (invalid) | The signal is not on a rail, or the monitored block is also the block before the signal |

Directionality: "Signals go on the right side of tracks by default (editable in options) and allow travel in that direction." For two-way single track, "Two signals directly opposite each other allow trains to travel in both directions through that point" — the placement UI highlights the position opposite an existing signal in white.

The wiki page does not state a numeric cap on trains per block; the practical rule falls out of the red-state definition — a train cannot be routed into a block that "is not empty."

## Rail chain signals

Chain signals don't just check their own block — they look ahead: "a chain signal also looks ahead to exit signals of the next block. If the exit signal of the next block does not allow the train to pass, then the chain signal will stop the train."

**The classic gotcha (exact wording):** "A special case for to this rule is when the train's destination can be reached from the chain signal without crossing any other signals. In that case the chain signal will not consider the exit signals." In other words, if the train's actual destination is reachable directly from that chain signal without passing through any further signal, the normal "check the next block's exit signal" behavior is skipped — the exit signals of that next block simply aren't considered for that train's routing decision.

**Chain signal states:**

| State | Meaning (verbatim) |
|---|---|
| Green | "all exits are free" |
| Yellow | "the block is reserved for a train and all other entrance signals of that block turn red" |
| Blue | "some but not all exits are free. In this case trains may or may not stop, depending on their path" |
| Red | "all exits are occupied" |
| Blinking | signal improperly placed / cannot divide blocks |

Additional operational notes captured from the page:
- A single-exit chain signal will hold a train if it can't immediately exit the next block.
- Chain signals placed before a crossing won't stop a train just because the *alternate* track through that crossing is blocked.
- If several chain signals lead into one regular (non-chain) signal, trains queue at the *first* chain signal when the block past the regular signal is occupied.

## Trains

### Schedules and wait conditions

Trains are given an ordered list of stations via the schedule GUI on the leading locomotive: "The player can set up a list of train stations in the left locomotive's GUI. The train will route to stops in the given order, if it's at the end it will continue with the first." Multiple wait conditions at a stop combine as disjunctive normal form (DNF) — i.e., AND/OR groups of conditions.

Wait condition types listed on the wiki (15 total):

1. Circuit condition — network signal-based
2. Empty cargo — all inventories vacant
3. Fluid count — specific fluid amount
4. Fuel (all locomotives) — collective fuel threshold
5. Fuel (any locomotive) — individual locomotive fuel level
6. Full cargo — all inventories filled
7. Full fuel — all fuel inventories filled
8. Has cargo — any items present
9. Inactivity — no transfers for a specified number of seconds
10. Item count — specific item quantity
11. Passenger present — a player is aboard
12. Passenger not present — no players aboard
13. Station is full — respects the target station's train-limit setting
14. Station is not full — inverse of the above
15. Time passed — duration-based

### Interrupts (new in 2.0)

"Schedule interrupts allow a locomotive to override its current schedule when a certain condition is met." Interrupt-trigger conditions include: at a specified station, destination full or no path, not at a specified station, plus the same 15 wait-condition types used for normal schedule stops.

**Wildcard interrupts:** four special virtual signals — Item, Fuel, Fluid, and Signal — can be used as an interrupt condition; each "replace[s] itself with the signal of the first item it finds" in the relevant train inventory, letting one interrupt rule match whatever cargo/fuel/signal is actually present rather than a hardcoded item.

**Resuming the original schedule:** once an interrupt fires, "the locomotive will route to the target station and wait there until the specified wait condition is met, at which point it will leave and resume its original schedule."

### Movement & stop rules

- "Trains can only drive forwards automatically. An automatic train can drive forwards and backwards when two locomotives facing different directions are connected to the train." A single-headed train can still be driven manually backward, just slower, but will not do so under automatic control.
- "Train stops must be on the right-hand side of the track" (relative to the locomotive's forward direction).
- Train stop / station **limits**: the "Station is full" wait/interrupt condition checks whether "a specified stop is full, according to its set train limit. If the stop has no train limit set, this condition will *not* be met."
- Cargo wagons can be serviced by "up to twelve adjacent inserters (six on each side)"; a fluid wagon accepts pumps from "only three pumps ... at once."
- Track is placed on a two-tile grid — "a rail cannot be moved by only one tile" — and the crossing of two straight tracks cannot be used as a switch because of train turning-radius limits.

## Logistic network (chests & robots)

### Network formation

Roboports form a shared logistic network when their (orange) logistic-coverage zones touch each other, shown by "a dashed yellow line connecting them." A gap in coverage between roboports — or all roboports in an area losing power — splits/prevents the network from joining up, i.e., robots on one side can't service chests on the other side of the gap.

### Chest types

| Chest | Definition (verbatim) |
|---|---|
| Active provider | "Pushes stored items into the logistic network." |
| Passive provider | "Places stored items at the logistic network's disposal." |
| Storage | "Stores items currently not requested" (and supplies them back to the network on demand) |
| Buffer | "Functions as both a requester chest and passive provider chest." |
| Requester | "Will be filled by logistic robots until the configured amount is reached, or the chest becomes full." |

### Priorities

- **Source priority (pickup order):** active provider chests and player trash slots first → storage chests and buffer chests next → passive provider chests last.
- **Target priority (delivery order):** player logistic requests are filled first → then requester chests → then buffer chests. Note: "Storage does not 'request' items on its own" — it's a sink of last resort, not a delivery target robots proactively fill.

### Robots

Two robot kinds: **logistic robots** (move items between chests / to players) and **construction robots** (build, deconstruct, and repair entities).

**Energy:** each robot stores "1.5MJ of energy" and, while flying, uses "3kW at all times ... and use an additional 5kJ for every tile travelled."

**Max range formula (verbatim):** `1500 ÷ (3 ÷ speed + 5)` tiles of round-trip range from a charging station, where `speed` is the robot's movement speed. At default (unresearched) speed this yields 250 tiles for logistic robots and 257 tiles for construction robots (construction bots have a slightly higher base speed).

### Personal logistics

Once the logistics research is unlocked, players can configure personal logistic requests — minimum quantities of items the personal logistic system will keep topped up in the player's inventory — plus (per general system behavior) trash-request slots for auto-offloading unwanted items; the page did not spell out trash-slot mechanics in more detail than "configuring minimum amounts for items to maintain in their inventory," so treat any trash-slot specifics beyond that as **unverified**.

## Blueprints & planners

- **Ghost auto-build range:** construction robots can build a blueprint's ghost entities if the ghosts fall "within the green (or orange) 110×110 tiles area of a roboport, or within range of a personal roboport."
- **Force-build (Shift):** "Holding SHIFT will activate 'Force Building' mode. This will mark all trees and rocks underneath the blueprint for deconstruction, as well as place ghosts for landfill if building over water."
- **Super-force-build (Ctrl+Shift):** "acts the same as force building, but will also mark **all** other buildings for deconstruction" — i.e., existing structures conflicting with the blueprint get deconstruction-flagged too, not just trees/rocks/water.
- **Blueprint string format:** "A blueprint string is a JSON representation of the blueprint, compressed with zlib deflate using compression level 9 and then encoded using base64 with a version byte in front." The version byte is currently `0` for all Factorio versions through 2.0. To decode: skip the first byte, base64-decode, then zlib-inflate to get JSON. As of 2.0 the game can also import the uncompressed JSON blueprint string directly. The JSON wraps the payload in an outer object keyed `blueprint` or `blueprint_book`.
- **Max blueprint size:** "The maximum of size a blueprint is 10k by 10k tiles."
- **Rail entities can't be flipped:** "blueprints which contain rail signals, chain signals, or train stops cannot be flipped, only rotated."
- **Parameterization** (added 2.0.7): lets you build "more generic blueprints, which are configured upon building" — parameters can drive recipes, circuit signals, combinator values, and train stop names.
- **Blueprint books:** blueprints can be stored in a blueprint book (or the blueprint library) "to prevent them occupying inventory space or for organization or sharing purposes."

## Sources

- https://wiki.factorio.com/Rail_signal
- https://wiki.factorio.com/Rail_chain_signal
- https://wiki.factorio.com/Railway
- https://wiki.factorio.com/Train
- https://wiki.factorio.com/Logistic_network
- https://wiki.factorio.com/Blueprint
- https://wiki.factorio.com/Blueprint_string_format
