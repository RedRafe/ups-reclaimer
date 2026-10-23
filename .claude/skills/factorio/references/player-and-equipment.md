# Player, Armor, and Equipment (Factorio 2.0 + Space Age)

Sources: wiki.factorio.com pages fetched directly (see `## Sources`). Every stat below
is attributed to the page it came from; nothing is pulled from memory. Where a value
could not be confirmed from a fetched page it is marked **unverified**.

## Player character

Stats per the [Player](https://wiki.factorio.com/Player) wiki page.

| Stat | Value | Notes |
|---|---|---|
| Base HP | 250 | "without energy shields" |
| Health research bonus | +50 HP / level | stacks with base 250 |
| Base main inventory slots | 80 | default, no armor |
| Inventory w/ Modular armor | 90 | i.e. +10 |
| Inventory w/ Power armor | 100 | i.e. +20 |
| Inventory w/ Power armor MK2 | 110 | i.e. +30 |
| Toolbelt research bonus | +10 slots / level | quickbar-related inventory research |
| Move speed (base) | 8.9 tiles/s (page also gives 8.902 on Exoskeleton page) | ~32 km/h |
| Move speed comparison | "half the speed of a behemoth biter" | per Player page |
| Reach distance | 10 | increased from 6 as of version 0.17.0 |
| Mining speed | 0.5 | base character mining speed stat |
| Passive health regen | 6 HP/s | kicks in after a few seconds without taking damage |
| Map/vision reveal | 5x5 chunks | centered on the chunk the character occupies |
| Respawn time | 10 s after death | |
| Respawn location | world center or a set spawn point | |
| Character size | 1x1 | |

Quickbar layout is not detailed on the fetched Player page — **unverified**.

## Armor tiers

Grid size and resistances scale with item **quality** (Normal -> Uncommon -> Rare ->
Epic -> Legendary). Resistance values are written `flat/percent%` (e.g. `8/30%` = 8 flat
reduction, 30% reduction) as given on each wiki page's infobox.

### Basic armor (no equipment grid)

| Armor | Physical | Explosion | Fire | Acid | Recipe | Source |
|---|---|---|---|---|---|---|
| Light armor | 3/20% | 2/20% | 0/10% | 0/20% | 40 iron plates, 3s | [Light armor](https://wiki.factorio.com/Light_armor) |
| Heavy armor | 6/30% | 20/30% | 0/30% | 0/40% | 100 copper plate, 50 steel plate, 8s | [Heavy armor](https://wiki.factorio.com/Heavy_armor) |

Neither page mentions an equipment grid or an inventory-slot bonus for these two, so
both are treated as **not equipped with a grid / no inventory bonus** (absence of
mention on the page, not confirmed negative).

### Equipment-grid armor (Modular / Power / Power MK2 / Mech)

Grid size by quality tier:

| Armor | Normal | Uncommon | Rare | Epic | Legendary | Source |
|---|---|---|---|---|---|---|
| Modular armor | 5x5 (25) | 6x6 (36) | 7x7 (49) | 8x8 (64) | 10x10 (100) | [Modular armor](https://wiki.factorio.com/Modular_armor) |
| Power armor | 6x8 (48) | 7x9 (63) | 8x10 (80) | 9x11 (99) | 11x13 (143) | [Power armor](https://wiki.factorio.com/Power_armor) |
| Power armor MK2 | 10x10 (100) | 11x11 (121) | 12x12 (144) | 13x13 (169) | 15x15 (225) | [Power armor MK2](https://wiki.factorio.com/Power_armor_MK2) |
| Mech armor (Space Age) | 10x12 (120) | 11x13 (143) | 12x14 (168) | 13x15 (195) | 15x17 (255) | [Mech armor](https://wiki.factorio.com/Mech_armor) |

Resistances (Normal quality; format `flat/percent%`):

| Armor | Physical | Explosion | Fire | Acid |
|---|---|---|---|---|
| Modular armor | 6/30% | 30/35% | 0/40% | 0/50% |
| Power armor | 8/30% | 40/40% | 0/60% | 0/60% |
| Power armor MK2 | 10/40% | 60/50% | 0/70% | 0/70% |
| Mech armor | 10/50% | 60/50% | 10/70% | 70%* |

\* Mech armor's acid resistance was returned by the fetch as a single `70%` value with no
flat component listed — **unverified whether a flat component exists**; presented as
fetched.

Inventory slot bonus by quality tier:

| Armor | Normal | Uncommon | Rare | Epic | Legendary |
|---|---|---|---|---|---|
| Modular armor | +10 | +13 | +16 | +19 | +25 |
| Power armor | +20 | +26 | +32 | +38 | +50 |
| Power armor MK2 | +30 | +39 | +48 | +57 | +75 |
| Mech armor | +50 | +65 | +80 | +95 | +125 |

Power armor's and Mech armor's Uncommon/Rare/Epic intermediate inventory-bonus figures
are confirmed directly from each page's "Inventory size bonus" infobox table (per
quality tier), not derived.

Crafting recipes (key ingredients, per [respective wiki pages](#sources)):

| Armor | Time | Key ingredients |
|---|---|---|
| Modular armor | 15s | 30 advanced circuits, 50 steel plates (150 copper, 60 iron, 60 plastic, 50 steel in raw materials) |
| Power armor | 20s | 20 electric engine units, 40 processing units, 40 steel plates |
| Power armor MK2 | 25s | 60 processing units, 40 electric engine units, 30 low density structures, 100 speed modules, 100 efficiency modules |
| Mech armor | 60s | 200 holmium plate, 1 Power armor MK2, 100 processing units, 50 supercapacitors, 50 superconductors |

All four are stack size 1, infinite durability, and require their own named tech
research to unlock (per each page).

**Mech armor flight** (Space Age only, per [Mech armor](https://wiki.factorio.com/Mech_armor)):
Mech armor grants free/automatic flight when it needs to cross obstacles — cliffs,
trees, factory buildings, vehicles, enemies, water, lava, and ammonia oceans. Flight
consumes no energy and has no time limit. Exceptions/caveats stated on the page:
- Smoke clouds from demolishers disable the mech armor's flying ability.
- The armor cannot be removed while airborne.
- Landing on unwalkable terrain while flight ends results in near-instant death.

## Equipment grid items

All energy/consumption figures below are the **Normal quality** value unless stated
otherwise; most items scale with quality the same way armor grids do (Uncommon ->
Legendary), and per-tier figures are included where the fetch returned them.

| Item | Grid shape | Key stats (Normal quality) | Space Age only? | Source |
|---|---|---|---|---|
| Personal roboport | 2x2 | 2.0 MW consumption, 35 MJ buffer, 10 construction robots capacity, 2 charging ports at 1.0 MW each, 30x30 tile construction area; only draws grid energy while recharging a robot, robot needs 20% charge before deploying | No | [Personal roboport](https://wiki.factorio.com/Personal_roboport) |
| Energy shield | 2x2 | 50 HP shield capacity, 12 HP/s recharge, 240 kW consumption, 120 kJ internal buffer, ~20 kJ per shield HP, ~4s full recharge from zero; damage splits equally across multiple shields so they recharge together | No | [Energy shield](https://wiki.factorio.com/Energy_shield) |
| Exoskeleton | 2x4 | +30% move speed per unit (additive stacking), consumes 200 kW only while actually moving, 56 kJ internal buffer; base speed 8.902 tiles/s becomes 11.483 tiles/s with one unit | No | [Exoskeleton](https://wiki.factorio.com/Exoskeleton) |
| Personal battery | 1x2 | 20 MJ storage capacity; can be placed in armor grids, tanks, spidertron, and mech armor | No | [Personal battery](https://wiki.factorio.com/Personal_battery) |
| Portable solar panel | 1x1 | 30 kW peak output, ~21 kW average (70% of peak, same day curve as the entity solar panel); described as "nearly useless" alone for demanding loads like personal laser defense/exoskeleton | No | [Portable solar panel](https://wiki.factorio.com/Portable_solar_panel) |
| Night vision | 2x2 | 10 kW consumption, 120 kJ internal buffer (drains in a few seconds if unpowered); auto-activates only at night, no effect from stacking multiple units, unaffected by quality | No | [Night vision](https://wiki.factorio.com/Night_vision) |
| Belt immunity equipment | 1x1 | 100 kW consumption, 100 kJ buffer; grants immunity to belt movement; draws power continuously regardless of whether the wearer is on a belt; can go in modular/power/power MK2/mech armor, tank, or spidertron | No | [Belt immunity equipment](https://wiki.factorio.com/Belt_immunity_equipment) |
| Fusion reactor | 6x6 | 100 MW production / 100 MW fuel (burner) consumption, 10 MW electric drain, 4 fluoroketone(cold)/s consumption, 1000 HP; single fuel cell lasts 400s at full power | Yes | [Fusion reactor](https://wiki.factorio.com/Fusion_reactor) |

### Per-quality scaling (where the fetch returned explicit tiered numbers)

**Personal roboport:**

| Quality | Energy consumption | Construction robots | Recharge rate |
|---|---|---|---|
| Normal | 2.0 MW | 10 | 2 ports x 1.0 MW |
| Uncommon | 3.9 MW | 13 | 3 x 1.3 MW |
| Rare | 5.6 MW | 16 | 4 x 1.6 MW |
| Epic | 6.65 MW | 19 | 5 x 1.9 MW |
| Legendary | 8.75 MW | 25 | 7 x 2.5 MW |

**Energy shield capacity by quality** (shield hitpoints): Normal 50, Uncommon 65,
Rare 80, Epic 95, Legendary 125.

**Energy shield max recharge speed by quality** (HP/s): Normal 12, Uncommon 15.6,
Rare 19.2, Epic 22.8, Legendary 30.

**Energy shield energy consumption by quality** (kW): Normal 240, Uncommon 312,
Rare 384, Epic 456, Legendary 600.

Energy shield MK2 exists per the page (linked as the item this equipment is
"consumed by"/obsoleted by) but its own capacity/recharge/consumption numbers are
not given on the *Energy shield* page itself — **unverified** (would need the
*Energy shield MK2* page fetched separately).

**Exoskeleton speed bonus by quality:** Normal +30%, Uncommon +39%, Rare +48%, Epic
+57%, Legendary +75%.

**Personal battery capacity by quality:** Normal 20 MJ, Uncommon 26 MJ, Rare 32 MJ,
Epic 38 MJ, Legendary 50 MJ. Personal battery MK2 exists (built from Personal
batteries) but its own capacity number was not returned by the fetch — **unverified**.

**Portable solar panel output by quality:** Normal 30 kW, Uncommon 39 kW, Rare 48 kW,
Epic 57 kW, Legendary 75 kW.

**Belt immunity equipment consumption by quality:** Normal 100 kW, Uncommon 76.92 kW,
Rare 62.5 kW, Epic 52.63 kW, Legendary 40 kW.

**Fusion reactor by quality** (infobox table, per page):

| Quality | Energy production / fuel consumption (burner) | Heat output (Plasma) | Fluoroketone (cold) consumption |
|---|---|---|---|
| Normal | 100 MW | 100 MW | 4/s |
| Uncommon | 130 MW | 130 MW | 5.2/s |
| Rare | 160 MW | 160 MW | 6.4/s |
| Epic | 190 MW | 190 MW | 7.6/s |
| Legendary | 250 MW | 250 MW | 10/s |

Electric drain is stated as a flat 10 MW figure on the page (tier scaling of drain not
given — **unverified** whether drain also scales with quality). Health scales 1000
(Normal) to 2500 (Legendary) per the page.

**Fusion reactor "Neighbour bonus" table** — transcribed verbatim from the page's
own reactors/generators/power table (this is the exact table content, not a derived
calculation):

| Reactors | Generators | Power |
|---|---|---|
| 1 | 2 | 100 MW |
| 2 | 8 | 400 MW |
| 3 | 18 | 900 MW |
| 4 | 28 | 1400 MW |

**Ambiguity flag (fusion reactor scaling) — unverified derivation:** This table's power
totals do not reconcile cleanly with a simple orthogonal neighbor-bonus formula (the
kind documented for the nuclear reactor, where each adjacent pair adds +100% to both
reactors). Applying that formula to a compact layout of N reactors predicts roughly
400 MW for 2 reactors (matches), but ~700 MW for 3 and ~1200 MW for 4 — not the 900 MW
/ 1400 MW the page's table states. Rather than guess at the actual layout or bonus
formula the page assumes, this document presents the table exactly as fetched and
flags the reactors-to-power relationship (and the generators-count column) as
**unverified/not independently reconciled**. Treat the row values as the wiki's stated
figures, not as a formula you can extrapolate past 4 reactors.

## Sources

- https://wiki.factorio.com/Player
- https://wiki.factorio.com/Armor
- https://wiki.factorio.com/Light_armor
- https://wiki.factorio.com/Heavy_armor
- https://wiki.factorio.com/Modular_armor
- https://wiki.factorio.com/Power_armor
- https://wiki.factorio.com/Power_armor_MK2
- https://wiki.factorio.com/Mech_armor
- https://wiki.factorio.com/Personal_roboport
- https://wiki.factorio.com/Energy_shield
- https://wiki.factorio.com/Exoskeleton
- https://wiki.factorio.com/Fusion_reactor
- https://wiki.factorio.com/Personal_battery
- https://wiki.factorio.com/Portable_solar_panel
- https://wiki.factorio.com/Night_vision
- https://wiki.factorio.com/Belt_immunity_equipment
