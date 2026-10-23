# Game Mechanics — Ratios, Limits & Numbers

Concrete numbers for reasoning about throughput, power, pollution, combat, and
circuits. Figures below are quoted or closely paraphrased from the wiki pages
listed in **Sources**; anything not confirmed on a fetched page is marked
**unverified** rather than guessed. Where a page itself ties a number to a
build (e.g. 2.0.26/2.0.67), that build is noted — treat un-tagged figures as
current-2.0/Space Age per the page as fetched.

## Belts & throughput

Belt tier throughput, per the wiki's belt table (*Belt transport system*):

| Belt | Speed (tiles/s) | Max throughput |
|---|---|---|
| Transport belt (yellow) | 1.875 | 15 |
| Fast transport belt (red) | 3.75 | 30 |
| Express transport belt (blue) | 5.625 | 45 |
| Turbo transport belt (Space Age) | 7.5 | 60 |

The wiki's table header labels the throughput column "stacks/second" but
footnotes that "the 'stacks' below refers to stacks created by a stack
inserter, not inventory stacks" — i.e. these are effectively items/second
figures (the commonly-quoted 15/30/45/60 items/s), not a stack-size-scaled
number. A fully filled straight belt holds 8 stacks in total. Both lanes
exist on every tier (2 lanes per belt).

Underground belts (base game): max gap is 4 / 6 / 8 tiles for
transport/fast/express respectively, storing up to 44 items at a 4-tile gap
and up to 72 items at an express 8-tile gap. Turbo (Space Age) underground
range was **not confirmed** on the fetched page — unverified.

Splitters divide input/output in a 1:1 ratio and preserve lane (left items
stay left, right items stay right) unless configured otherwise; if one
output is blocked, a splitter routes all input to the other output. The
fetched pages did not give a specific throughput-loss figure for
sideloading (merging a belt in from the side) or for belt curves/corners —
**unverified**, do not assume a specific fraction.

## Inserters

Chest-to-chest throughput in items/second, from the wiki's *Inserters* page
(data there is explicitly tied to Factorio 2.0.26, cross-checked against a
1.1 baseline — treat as current 2.0 figures):

| Inserter | No bonus | +2 stack-size bonus | +7 stack-size bonus |
|---|---|---|---|
| Burner | 0.79 | 1.58 | 2.37 |
| Yellow (regular) | 0.86 | 1.71 | 3.43 |
| Long-handed | 1.2 | 2.4 | 4.8 |
| Fast (red) | 2.5 | 5.0 | 10.0 |
| Bulk | 5.0 | 10.0 | 30.0 |
| Stack (blue) | 15.0 | 20.0 | 40.0 |

"Bonus" columns are the capacity-bonus research (stack-size) levels; they
raise how many items an inserter moves per swing, not swing speed. Bulk
inserters get an extra edge dropping onto splitter *sides* — the page cites
16.0 items/s there instead of the usual 14.4 for the equivalent no-side
case.

Rotation/extension speed (fraction of full turn or tile per tick):

| Inserter | Rotation speed | Extension speed | Ticks/full rotation |
|---|---|---|---|
| Burner | 0.013 | 0.035 | 76 |
| Yellow | 0.014 | 0.035 | 70 |
| Long-handed | 0.02 | 0.05 | 50 |
| Fast / Bulk / Stack | 0.04 | 0.1 | 24 |

Power draw has two components — a per-transfer-cycle energy cost, and a
continuous rotation/extension power draw while swinging. Re-querying the
page by exact type name (rather than the wiki's color coding, which an
earlier pass mis-mapped) gives:

| Inserter | Rotation power (kW) | Extension power (kW) |
|---|---|---|
| Burner | 39 | 105 |
| Inserter (yellow) | 4.2 | 10.5 |
| Long-handed | 6 | 15 |
| Fast | 16.8 | 42 |
| Bulk | 48 | 120 |
| Stack | 96 | 240 |

Per-transfer-cycle energy cost was only confirmed unambiguously for three
types: Burner 66.9 kJ, Inserter (yellow) 6.65 kJ, Stack inserter 46.4 kJ.
The page also showed figures of 7.0/8.12/23.2 kJ that would presumably
belong to Long-handed/Fast/Bulk, but a follow-up query asking for those by
exact name came back "not specified in tables" for that metric — the two
fetches disagree on whether/how those three numbers are labeled, so they
are **unverified** and omitted rather than guessed.

Inserters can pick up from the ground, a belt, or anything with storage
space. On perpendicular belts, an inserter prefers the near lane and only
reaches the far lane if the near one is empty.

## Power

Units: electricity is tracked in W/kW/MW (instantaneous power) and
J/kJ/MJ/GJ (stored/transferred energy).

Generation figures from the wiki's *Electric system* page:

| Source | Output |
|---|---|
| Steam engine | 900 kW (from stored steam) |
| Steam turbine | 5800 kW |
| Solar panel | 60 kW per panel |
| Accumulator | 5 MJ capacity; 300 kW max charge/discharge rate |
| Nuclear reactor | ~8 GJ released per fuel-cell burn (baseline; more with reactor bonuses) |

Solar panel average output across the day/night cycle (the commonly-cited
"effectively less than peak" figure) was **not confirmed** on the fetched
page — only the 60 kW peak-per-panel figure is sourced; treat any
day/night-averaged number as unverified.

**Priority order** — the page states electricity demand is satisfied in
this order: solar panels first ("they always work at maximum performance
available"), then steam engines/turbines/fusion generators (which "match
whatever demand solar panels cannot satisfy," dividing load equally among
themselves), and accumulators last, only discharging once the above can't
cover demand. Accumulators charge from any surplus once demand is met.

**Brownouts**: if a network's generation can't cover total demand, the
available power is "evenly spread across all machines in the network
(based on each machine's demand), and all machines will slow down
proportionally to the power available." Worked example from the page: an
assembling machine 3 (210 kW) and an electric mining drill (90 kW) demand
300 kW total; with only 180 kW available (3 solar panels at 60 kW), both
machines run at roughly 60% speed.

**Idle drain**: machines draw power even when not actively working — e.g.
"assembling machine 2 will consume 155 kW (150 kW energy consumption + 5 kW
drain)."

## Pollution

Pollution production, in pollution/minute at full power, per the wiki's
*Pollution* page (base game and Space Age buildings mixed together below —
figures are additive per building, not global caps):

| Source | Pollution/min |
|---|---|
| Boiler | 30 |
| Burner mining drill | 12 |
| Electric mining drill | 10 |
| Pumpjack | 10 |
| Oil refinery | 6 |
| Steel furnace | 4 |
| Chemical plant | 4 |
| Centrifuge | 4 |
| Stone furnace | 2 |
| Assembling machine 1/2/3 | 4 / 3 / 2 |
| Electric furnace | 1 |
| Heating tower (Space Age) | 100 |
| Big mining drill (Space Age) | 40 |
| Foundry / Cryogenic plant / Biolab (Space Age) | 6 / 6 / 8 |
| Electromagnetic plant (Space Age) | 4 |
| Recycler / Crusher (Space Age) | 2 / 1 |

Module effects compose as `final pollution = pollution_multiplier ×
energy_usage_multiplier × base_pollution`.

**Spread**: a chunk starts spreading pollution to its four cardinal
neighbors once it accumulates 15.0 pollution, spreading roughly "2% per 64
ticks" (64 ticks ≈ one game-second).

**Absorption/dissipation** (per minute, by tile, from the page's table):
water tiles ‑1.536, grass/dirt ‑1.10592, red desert/sand ‑0.9216, nuclear
ground ‑0.768, path/landfill 0, out-of-map ‑6.144. Trees also absorb
pollution passively (rate depends on growth stage, from ‑0.001/s at full
density down to 0 at minimum), and can absorb a burst of "10 pollution"
when damaged if local chunk pollution exceeds 60.

**Evolution and enemies**: the page is explicit that "evolution factor is
not increased by spreading/absorbed pollution, but by pollution produced by
all machinery at every tick" — i.e. containing/absorbing pollution locally
does not slow the global evolution factor, only reducing pollution produced
does. Biter spawners absorb pollution and use it to trigger attacks: each
spawner type has an absorption threshold before it musters an attack group
(small biter/spitter 4, medium spitter 12, medium biter 20, big spitter 30,
big biter 80, behemoth spitter 200, behemoth biter 400), and once a chunk's
pollution exceeds 20, spawners absorb "20 + 0.01 × [chunk's pollution]"
every 64 ticks. Attack groups muster on a random 1–10 minute timer, with
stragglers given up to 2 more minutes to join.

## Combat

*The wiki's `Combat` page returned 404 when fetched; `Damage` and
`Resistance` (both current, mutually consistent) were used instead — see
Sources.*

**Damage types** (from `Damage`): physical, physical+explosion (cannon/
artillery shells), impact (vehicle collisions), fire, acid, poison,
explosion, laser, and electric — nine categories total, each resisted
independently by an entity's per-type resistance values.

**Resistance formula** (confirmed identically on both `Damage` and
`Resistance`): each resistance is a flat component `R` and a percentage
component `P` (as a decimal). Given incoming damage `D`, final damage `F`
is:

- If `R + 1 < D`: `F = (D − R) × (1 − P)`
- Else if `D > 1`: `F = (1 − P) / (R − D + 2)`
- Else (`D ≤ 1`): `F = (1 − P) / (R + 1)`

Flat resistance is applied first, percentage resistance after. Flat
resistance alone can never reduce damage to zero (it asymptotically
approaches a floor above 0); **only 100% percentage resistance grants true
immunity** to that damage type. Worked example from the page: 25/10%
resistance against 45 incoming damage → `(45 − 25) × 0.9 = 18` damage
taken.

**Health**: player base health is 250 HP (before Health research);
entity/turret/biter HP values are per-entity and listed on their individual
wiki pages, not enumerated here.

**Piercing**: piercing ammunition (e.g. tank cannon rounds) can continue
through and hit additional targets as long as remaining piercing power
exceeds the damage already dealt to the target killed.

## Circuit network

From the wiki's *Circuit network* page (current as of 2.0.67):

- **Wire colors are independent networks.** Red and green wires never
  merge with each other even when landing on the same pole/device; two
  wires of the *same* color joined together do merge into one network.
- **A receiving device sums all signals from every wire connected to it**,
  red and green alike — it sees one combined set of channel values, not two
  separate ones.
- **Signals**: every item type and every fluid type in the game has its own
  channel automatically (a storage device broadcasts its contents on the
  matching channel). On top of that there are virtual signals for things
  with no physical item — 177 in the base game, 241 once Space Age content
  is included (exact base-vs-added split not itemized on the page — treat
  241 as the Space Age-inclusive total, not necessarily "177 + 241").
- **Signal values are signed 32-bit integers**, range
  −2,147,483,648 to 2,147,483,647 inclusive, and they wrap on overflow
  (e.g. `2147483647 + 10` becomes `-2147483639`).
- **Multiple senders on a network add together** — two storage tanks each
  holding 1000 crude oil produce a combined crude-oil signal of 2000 on
  that network.
- **Combinators**:
  - *Constant combinator* — in the **pre-2.0.7 model**, broadcasts up to 20
    fixed signal values (the description used throughout the rest of this
    section). The wiki's *Constant combinator* page confirms **2.0.7
    reworked this**: combinators now configure and output via named
    **logistic groups** rather than a fixed 20-slot grid (a logistic group
    holds a min/max per signal, and "the constant combinator will only
    output the minimum value"). For full combinator operator/mode details,
    see `references/circuits-and-combinators.md`.
  - *Arithmetic combinator* — takes input signal(s), applies a math
    operation, emits a result signal.
  - *Decider combinator* — compares input signal(s) against a condition
    and emits signal(s) conditionally (true/false-gated).
  - *Selector combinator* — picks a single signal out of its inputs (e.g.
    largest/smallest, a random one, or a signal's stack size/item count)
    and outputs just that one.
- **Logic conditions** on decider-style comparisons can be quantified as
  *everything* (true only if the condition holds for every input signal),
  *anything* (true if it holds for at least one), or *each* (evaluated
  per-signal, independently, with results summed on output).
- **Feedback loops**: wiring a combinator's output back into its own input
  creates a loop where the value changes every tick, so it "shoot[s]
  upward" quickly (tick-rate speed) but not instantaneously — useful
  deliberately as a tick-rate counter, dangerous by accident.
- Wire reach/length limits are governed by the connecting entity (pole or
  wire type), which the page does not enumerate numerically — **specific
  wire-reach distances are unverified here**; consult individual
  entity pages if a wire-length number is needed.

## Nuclear & heat

From the wiki's *Nuclear reactor*, *Heat pipe*, *Uranium processing*, and
*Heat exchanger* pages.

**Reactor output**: a single normal-quality reactor produces **40 MW**
thermal (scales with quality, up to 100 MW at legendary). Reactor heat
capacity is 10 MJ/°C, buffering 5 GJ across its 500–1000°C working range.

**Neighbour bonus**: "reactors receive a bonus for adjacent operating
reactors, which increases their effective thermal output by 100% per each
such link" — i.e. +100% per adjacent connected reactor, and the page states
this uncapped (two adjacent reactors run at 80 MW each, 160 MW combined;
longer rows compound further since every link adds another 100%).

**Meltdown**: confirmed on the *Nuclear reactor* page — "if a reactor is
destroyed (by damage) while it is above 900°C, it will explode, having the
same effects of an atomic bomb," and critically "one explosion can lead to a
chain reaction of exploding reactors." 900°C is exactly the page's stated
threshold, not an approximation.

**Heat pipe / conduction formulas** (from *Heat pipe*, quoted verbatim):
heat pipes "lower the temperature by `1 + (P / 15) °C`" per pipe segment,
where P is the power (MW) flowing through it; a reactor's own internal
conduction drops temperature by `1 + (P / 387) °C` (the page notes 387 is a
rounding of the actual constant, "200000/517 or about 386.847"). Heat pipes
have 1 MJ/°C capacity, buffering 500 MJ across the same 500–1000°C range,
max temperature 1000°C.

**Heat exchanger**: consumes 10 MW (heat) and produces "~103 steam with a
temperature of 500°C every second" (derived on the page from 500°C steam
holding 0.097 MJ/unit). Since a reactor outputs 40 MW, **4 heat exchangers
exactly consume one reactor's output** (computed from these two confirmed
figures — the page does not itself state a reactor:exchanger ratio). A
steam turbine consumes 60 steam/s for 5.82 MW, so one heat exchanger's 103
steam/s feeds roughly 1.7 turbines.

**Fuel / Kovarex** (from *Uranium processing*): centrifuge processing of
uranium ore yields "99.3% chance to produce 1 uranium-238 and a 0.7% chance
to produce 1 uranium-235" per cycle (10 ore in, 12 s/cycle). The Kovarex
enrichment process needs **40 U-235 stockpiled to start** — the page frames
reaching 40 U-235 as the threshold to "initiate Kovarex enrichment" (exact
recipe input/output ratios were not itemized on the page — unverified
beyond that starting threshold). Uranium fuel cells burn for **200
seconds**, confirmed on both *Nuclear reactor* and *Uranium processing*;
combined with the 40 MW reactor output this is consistent with the already-
sourced "~8 GJ per fuel-cell burn" figure in the Power section above (40 MW
× 200 s = 8 GJ).

## Modules & beacons

From the wiki's *Module* and *Beacon* pages.

| Module | Tier 1 | Tier 2 | Tier 3 |
|---|---|---|---|
| Speed (speed / energy) | +20% / +50% | +30% / +60% | +50% / +70% |
| Productivity (prod / speed / energy / pollution) | +4% / −5% / +40% / +5% | +6% / −10% / +60% / +7% | +10% / −15% / +80% / +10% |
| Efficiency (energy) | −30% | −40% | −50% |

Figures are normal-quality module values. Efficiency modules also reduce
pollution roughly in proportion to the energy reduction.

**Effects are additive, not multiplicative** — stacking modules gives
linear gains, no compounding. Energy-consumption reduction caps at −80%
total, and the page states "the lowest amount of energy that efficiency
modules can be used to achieve is **20% of the machine's base energy
usage**" (i.e. a hard floor, not a ratio that can be driven to zero).

**Productivity module restrictions**: disallowed on barrel filling/emptying,
barrel production from steel, and steam condensation (Space Age); a short
list of non-intermediate exceptions (stone bricks, certain concrete
recipes, artificial soil) are explicitly allowed despite not being typical
productivity-eligible recipes.

**Beacons (2.0 rework)**: a normal-quality beacon has **distribution
efficiency 1.5** (150%), rising to 2.5 at legendary quality. Only speed and
efficiency modules can be inserted into a beacon — productivity and quality
modules are rejected. The *Beacon* page gives the current stacking formula
directly: for a machine affected by `n` beacons, each beacon's contribution
is

```
(distribution efficiency) ÷ √n
```

so same-tier normal beacons combine to `1.5 × √n` total effect. Confirmed
worked example from the page: 1 beacon → 150% total effect; 2 beacons →
212.13% total (a marginal gain of only 62.13% from the second beacon) —
i.e. genuine diminishing returns per additional beacon, not a hard cap.
Beacon power draw is 480 kW at normal quality (down to 80 kW at legendary),
and beacons "always consume power, even when the machines they're boosting
are halted."

## Fluids

From the wiki's *Fluid system* page (storage-tank and fluid-wagon figures
cross-checked against *Storage*).

A single pipe segment holds 100 fluid. Per unique input/output pipe
connection, the page gives a **theoretical maximum of 6000 fluid/s** (100
fluid/tick) and a **practical maximum around 4200 fluid/s**; a machine with
two separate output connections for the same fluid can push roughly 8400
fluid/s combined. A connected run of pipes needs an interposed pump once it
exceeds **320×320 tiles (10×10 chunks)** — beyond that unaided distance
fluid stops flowing until a pump breaks the segment. Storage tank capacity
is 25,000 fluid; fluid wagon capacity is 50,000 (both pages agree); barrels
hold 50 fluid each, and a cargo wagon fully loaded with barrels carries
20,000 fluid total.

## Mining

From the wiki's *Mining* page.

| Drill | Mining speed | Footprint | Coverage area | Resource drain |
|---|---|---|---|---|
| Burner mining drill | 0.25 | 2×2 | 2×2 | 100% |
| Electric mining drill | 0.5 | 3×3 | 5×5 | 100% |
| Big mining drill (Space Age) | 2.5 | 5×5 | 13×13 | 50% |

Base mining time (before speed/productivity modifiers) is 1 second each for
iron ore, copper ore, coal, stone, and calcite; 2 seconds for uranium ore;
5 seconds for tungsten ore; 0.5 seconds for scrap. "Resource drain" is the
percentage of a patch's remaining amount consumed per mining action — big
mining drills deplete finite patches at half the normal rate. The page
additionally notes quality tiers reduce drain further (roughly 1/6th per
quality level, with legendary giving a double bonus).

Mining productivity research is confirmed to exist and to raise output
"without... slow[ing] the mining drill down (unlike productivity modules),"
but the fetched page did not give the per-level percentage bonus or
infinite-research cost curve for it in isolation — treat any specific
mining-productivity percentage as **unverified** (see the infinite-research
formula for the arithmetic *cost*, which the *Technology* page does confirm,
below).

## Research / technology

From the wiki's *Technology* page.

**Science packs** — base game: Automation, Logistic, Chemical, Military,
Production, Utility, Space. Space Age adds: Metallurgic, Electromagnetic,
Agricultural, Cryogenic, Promethium.

**Infinite research cost formulas** (confirmed on the page; `N` = level
being purchased, `F` = level the formula starts counting from):

| Research | Formula | Type |
|---|---|---|
| Mining productivity | `P[N] = 2500 × (N − F)` | Arithmetic |
| Follower robot count | `P[N] = 1000 × (N − F)` | Arithmetic |
| Most weapon damage | `P[N] = 1000 × 2^(N − F − 1)` | Geometric (×2) |
| Artillery shell range | `P[N] = 1000 × 2^N` | Geometric (×2) |
| Artillery shooting speed | `P[N] = 1000 + 1000 × 3^(N − 1)` | Geometric (×3) |
| Research productivity (Space Age) | `P[N] = 1000 × 1.2^N` | Geometric |
| Most other productivity techs (Space Age) | `P[N] = 1000 × 1.5^N` | Geometric |

**Practical caps** stated on the page: follower-robot-count level 50 is the
theoretical max (1200 deployable robots); recipe productivity research hits
the Space Age 300% productivity cap around level 30; railgun-turret-speed
research reaches an effective maximum around level 10.

## Energy & work

From the wiki's *Energy and work* page.

`1 W = 1 J/s` — power is simply energy per second. The page defines
efficiency as "the ratio between *useful* work done and the energy
expended," and notes Factorio mostly abstracts inefficiency through
**pollution output** rather than tracking heat loss directly, and that a few
systems deliberately break real-world 100%-efficiency limits (belts and
turrets run unpowered; the player performs work without consuming food).

Worked example from the page: an **Assembling machine 1** draws 3 kW while
idle (drain) plus 90 kW while actively crafting, for 93 kW combined while
working. (Compare the Power section above's Assembling machine 2 example,
150 kW + 5 kW drain = 155 kW — a different machine tier, sourced from
*Electric system* instead, consistent in method.)

## Balancers

From the wiki's *Balancer mechanics* page.

- **Input-balanced**: "take evenly from all input belts/belt lanes."
- **Output-balanced**: "distribute evenly to all output belts/belt lanes."
- **Throughput-unlimited**: the strict combination of (1) 100% throughput
  under full load, and (2) working for "any arbitrary amount of input belts
  ... to any arbitrary amount of output belts" — i.e. neither balance
  property alone guarantees full throughput at every input/output ratio.

For an `n`-to-`n` balancer where `n` is a power of two, the page gives the
Beneš-network splitter-count formula directly:

```
splitters = n × log2(n) − n / 2
```

(the page describes this as "based on the number of nodes in a Beneš
network, essentially the same as a throughput-unlimited balancer"; it does
not itemize a table of splitter counts by `n` — e.g. `n=4` → 6 splitters and
`n=8` → 20 splitters are simple arithmetic from the formula above, not
values quoted directly on the page).

## Stacks & storage

From the wiki's *Stack* and *Storage* pages.

| Stack size | Example items |
|---|---|
| 1 | Nuclear fuel, artillery shell, satellite, modular armor, blueprint |
| 5 | Locomotive, all wagons |
| 10 | Roboport, rocket fuel, artillery turret, atomic bomb, low density structure |
| 20 | Some equipment modules, pumpjack |
| 50 | Ores, stone, coal, modules, electric mining drill, electric furnace, assemblers, chests, inserters, turrets (gun/laser), power poles, worker robots, solid fuel |
| 100 | Iron/copper/steel plate, processing unit, iron gear wheel, stone brick, concretes, both uranium isotopes, pipe, belts, wall, landfill |
| 200 | Electronic/advanced circuit, magazines, tank cannon shells, copper cable, circuit wires, science packs (except space science) |
| 2000 | Space science pack only |

Rule from the page: "the first inserted item determines which item types
can be stored" in a slot, which indirectly sets that slot's effective
capacity via the item's stack size.

**Storage capacities**: car 80 inventory slots; cargo wagon 40 slots;
storage tank 25,000 fluid; barrel 50 fluid each; belt storage is quoted on
the page as "80 items per 10 belts when both sides of the belt are used"
(i.e. per 10 belt tile-pieces, both lanes).

## Transport-method selection

From the wiki's *Tutorial:Transport use cases* page. These are decision
thresholds, not hard engine limits.

| Method | Throughput | Practical range |
|---|---|---|
| Basic (yellow) belt | ≤900 items/min | short–medium (matches the 15 items/s figure in Belts above: 900/60 = 15) |
| Express belt | ≤2700 items/min | short–medium (2700/60 = 45, matching Belts above) |
| Cargo wagon (ore) | ~2000 items/wagon | long distance |
| Cargo wagon (plates) | ~4000 items/wagon | long distance |
| Logistic bots | very high in dense areas | sweet spot **under 50 tiles** |

The page frames belts/trains crossover at roughly **500 tiles** — beyond
that, trains generally beat belts on a bulk route. For logistic bots, its
worked example for delivering 3000 items/minute needs about 300 bots at 50
tiles but about 3000 bots at 500 tiles (bot count scales with distance), and
it characterizes bots as "terrible at long distances and bulk goods" —
best suited to short-range, low-volume/high-value delivery inside a dense
factory rather than bulk ore/plate hauling.

## Hard limits & magic numbers

Collected fixed constants from the sections above — treat any not listed
here as not yet confirmed:

- Belt throughput ceiling: 15 / 30 / 45 / 60 items-per-second for
  transport / fast / express / turbo belts.
- Underground belt max gap: 4 / 6 / 8 tiles for transport / fast / express
  (turbo's gap is unverified).
- Fully-loaded straight belt holds 8 stacks.
- Splitters split input/output 1:1.
- Accumulator capacity: 5 MJ; max charge/discharge: 300 kW.
- Circuit signal range: signed 32-bit integer, −2,147,483,648 to
  2,147,483,647 (wraps on overflow).
- Constant combinator: up to 20 signal values per combinator (pre-2.0.7 model;
  2.0.7+ uses logistic groups — see the Circuit network section).
- Virtual signals: 177 (base game) / 241 (with Space Age).
- Player base health: 250 HP.
- Resistance: 100% percentage resistance is the only way to reach true
  damage immunity; flat resistance alone never reaches zero damage.
- Pollution spread trigger: a chunk must reach 15.0 pollution before it
  spreads to neighbors, then spreads at ~2%/64 ticks.
- Biter spawner attack-muster timing: random 1–10 minutes, stragglers get
  up to +2 minutes.
- Nuclear reactor: 40 MW base output; +100% output per adjacent-reactor
  link (uncapped); meltdown above 900°C if destroyed.
- Heat pipe drop: `1 + P/15 °C`; reactor internal conduction: `1 + P/387 °C`.
- Uranium fuel cell: 200 s burn time; Kovarex needs 40 U-235 stockpiled to
  start.
- Module effects are additive; efficiency-module energy floor is 20% of
  base; consumption reduction caps at −80%.
- Beacon distribution efficiency: 1.5 (normal quality); per-beacon
  contribution to a shared machine = distribution efficiency ÷ √n.
- Pipe throughput: ~6000 fluid/s theoretical, ~4200 fluid/s practical per
  connection; pipe segment limit 320×320 tiles (10×10 chunks) without a
  pump; storage tank 25,000; fluid wagon 50,000.
- Mining drill speeds: burner 0.25, electric 0.5, big mining drill 2.5;
  resource drain 100% (normal) / 50% (big mining drill).
- Beneš balancer splitter count for power-of-two `n`: `n × log2(n) − n/2`.
- Belt decision throughput: 900 items/min (basic) / 2700 items/min
  (express); logistic bots' practical sweet spot is under 50 tiles.

## Sources

- https://wiki.factorio.com/Transport_belts
- https://wiki.factorio.com/Belt_transport_system
- https://wiki.factorio.com/Inserters
- https://wiki.factorio.com/Electric_system
- https://wiki.factorio.com/Pollution
- https://wiki.factorio.com/Damage — substituted for `Combat`, which
  404'd at fetch time; no page at that URL currently exists.
- https://wiki.factorio.com/Resistance — fetched alongside `Damage` to
  cross-check the resistance formula.
- https://wiki.factorio.com/Circuit_network
- https://wiki.factorio.com/Constant_combinator — fetched to confirm the
  2.0.7 logistic-groups rework of constant combinators.
- https://wiki.factorio.com/Nuclear_reactor
- https://wiki.factorio.com/Heat_pipe
- https://wiki.factorio.com/Uranium_processing
- https://wiki.factorio.com/Heat_exchanger
- https://wiki.factorio.com/Module
- https://wiki.factorio.com/Beacon
- https://wiki.factorio.com/Fluid_system
- https://wiki.factorio.com/Mining
- https://wiki.factorio.com/Technology
- https://wiki.factorio.com/Energy_and_work
- https://wiki.factorio.com/Balancer_mechanics
- https://wiki.factorio.com/Stack
- https://wiki.factorio.com/Storage
- https://wiki.factorio.com/Tutorial:Transport_use_cases
