# Space Age Expansion Mechanics

> Space Age is a paid expansion (released 2024-10-21) bundling four mods:
> **Space Age** itself, **Quality**, **Elevated Rails**, and **Recycler**
> (per the wiki's *Space Age* page). These change assumptions valid in base
> 2.0 — every section below is flagged **[Space Age only]** where the
> fetched source says the mechanic doesn't exist without the expansion, and
> **[separable mod]** where a source says that piece can be toggled on
> independently of the rest of Space Age.

## Quality

**[Space Age only to unlock; separable mod once unlocked]** — the wiki
states "quality is a feature of the Space Age expansion... While players
are required to own Space Age to access this feature, quality is a
separate mod, and can be activated independent of most Space Age content."

**Tiers** — 5 quality tiers, with *tier strength* in brackets (strength is
what scales the bonuses, not the ordinal position):

| Tier | Strength |
|---|---|
| Normal | 0 |
| Uncommon | 1 |
| Rare | 2 |
| Epic | 3 |
| Legendary | 5 |

Legendary is explicitly a **2-strength jump** over Epic, not a simple +1
step. Research gating: the two highest tiers (Epic quality, Legendary
quality) require technology "not available on Nauvis" initially — i.e.
Gleba/Aquilo-line tech — while the base Quality module tech is available
earlier.

**Effects** — bonuses are per quality-strength and additive. The wiki lists
(non-exhaustive but the significant ones): +30% health, +30% crafting
speed, +30% robot limit, +30% robot recharge rate, +30% positive module
effects, +10% turret range, +10% weapon range, +1 tile reach / +2 wire
reach on power poles, +1 equipment grid size, +30% chest inventory size,
+30% ammo damage, +30% inserter rotation speed (which also raises inserter
energy consumption by 30%, since power is defined per angle turned), +30%
solar panel output, +100% (+5 MJ) accumulator capacity, +30% output rate
on boilers/steam engines/steam turbines/accumulators/nuclear reactors
(consumption and pollution scale with it too), −16.67% (1/6) resource
drain on miners/pumpjacks (multiplicative with productivity), and −16.67%
(1/6) power consumption on beacons. Worked example given verbatim by the
page: "a Legendary (5 tier-levels) Productivity module 3 (base +10%
productivity) would grant 25% productivity."

Some entity classes get **only health scaling, no special effect**: circuit
network/rail-signal entities, transport belts, pipes, walls, trains, cargo
wagons.

**Two ways to raise an item's quality:**
1. **Quality ingredients** — craft using ingredients that are *all* the
   target quality. Item-ingredient quality must match **exactly** (not
   "at least") — e.g. you cannot combine uncommon iron plates with rare
   batteries. Fluids have no quality and are exempt from this. Barrel
   fill/empty recipes and recipes producing the same item they consume
   (Kovarex enrichment, fish breeding) don't accept quality modules.
2. **Quality modules** — give a probabilistic chance to output a
   higher-tier item than the ingredients. A machine's roll chance is the
   **sum of the quality chance of all its installed quality modules**.
   Quality module base chances (own-module quality Normal→Legendary):

   | Module | Normal | Uncommon | Rare | Epic | Legendary |
   |---|---|---|---|---|---|
   | Quality module | 1% | 1.3% | 1.6% | 1.9% | 2.5% |
   | Quality module 2 | 2% | 2.6% | 3.2% | 3.8% | 5% |
   | Quality module 3 | 2.5% | 3.2% | 4% | 4.7% | 6.2% |

   On success, the product is upgraded one tier from its ingredient
   quality; the machine then **repeats the roll at a flat 10% chance** to
   upgrade again, continuing until a roll fails. So going from Normal all
   the way to Legendary in one craft is possible but geometrically rare.

**Recyclers** [separable mod] return only **25% of
input items**, so the wiki's own guidance is: it's optimal to push quality
upgrades right before the final target item (recycling loses too much
material) *unless* a productivity research exists for that item, in which
case looping through a recycler is free of net material cost (ignoring
fluids) and becomes optimal.

## Spoilage

**[Space Age only]** — "spoilage is a feature of the Space Age expansion,"
per the wiki. Many items — mostly Gleba biological products — turn into
**spoilage** (or a specific spoil product) after a fixed timer. Spoiling
can happen **anywhere** (the wiki lists "in machines, belts and even when
being held by an inserter"): in a chest, on a transport belt, in a
machine's input/output slot, or while held in an inserter's hand — the
timer never pauses regardless of
where the item sits, and there is no way to "freeze" an item's clock short
of raising its quality.

Confirmed per-item spoil timers (from the wiki's *Spoilage mechanics*
page):

| Item | Spoil time |
|---|---|
| Raw fish | 7,550 s (~2h 5m 50s) |
| Bioflux | 7,200 s (2h) |
| Jellynut | 3,600 s (1h) |
| Yumako | 3,600 s (1h) |
| Agricultural science pack | 3,600 s (1h) |
| Biter egg | 1,800 s (30 min) |
| Captive biter spawner | 1,800 s (30 min) |
| Pentapod egg | 900 s (15 min) |
| Nutrients | 300 s (5 min) |
| Jelly | 240 s (4 min) |
| Yumako mash | 180 s (3 min) |
| Copper bacteria | 60 s (1 min) |
| Iron bacteria | 60 s (1 min) |

Mechanism: each spoilable item stack tracks **freshness as a percentage**
of how far it is from spoiling (100% = fresh/full timer remaining, 0% =
spoils). "Quality increases the freshness duration of an item" — higher
quality items generally take longer to spoil, but the fetched pages gave
no specific per-tier percentage for this, so treat the exact multiplier as
**unverified**.

Spoiled items become the **spoilage** item itself, which is not simply
trash — recipes consume it: converted to nutrients in assembling machines,
burned as fuel (250 kJ, per the *Spoilage* results page), and used in
biosulfur/efficiency-module/soil recipes. Recycling nutrients is noted to
produce a disproportionate amount of spoilage because the primary
nutrients-from-spoilage recipe runs at a 10:1 ratio.

## Planets

Author's grouping, not a wiki-sourced table — each row's facts are cited
individually below and trace to that planet's own wiki page. **All four
planets and their surfaces are Space Age only.**

| Planet | Signature mechanic | Key resources | Threat / hazard |
|---|---|---|---|
| Vulcanus | Lava casting into metal; no pollution; 1.5-min day/night | Tungsten ore (needs big mining drill), lava, calcite | Demolishers — large territorial boss enemies, fixed at world-gen, permanently gone once killed |
| Fulgora | Lightning-strike power harvesting; scrap recycling loop | Scrap (only surface-mineable resource), heavy oil (unlimited, offshore-pumped), ice (from scrap recycling) | Lightning storms every night (90 s of a 3-min cycle; ~1 strike/chunk/10s); no enemies at all |
| Gleba | Spoilage-driven "just-in-time" production; bacteria-grown ore | Yumako/Jellynut fruit (Agricultural Tower), bioplastic/biosulfur/biolubricant in place of oil products, iron/copper via biochamber bacteria | Pentapods, drawn to Spores (Gleba's pollution analog); nests only on shallow water |
| Aquilo | Everything freezes without active heating; final-tier destination | Ammoniacal solution, lithium brine, fluorine (none of these three are transportable off-planet); imported iron/copper/coal/stone (none exist locally) | Cold: buildings stop without heat >30°C; solar output only 1% of Nauvis (0.6 kW peak); gravity/pressure ratio 5× normal, so robots use 5× power |

Per-planet detail, each traced to that planet's own wiki page:

**Vulcanus** — "a hot volcanic planet with mountainous volcanoes, rivers of
lava, plains of ash, and sulfuric acid geysers," no pollution mechanic, 1.5
minute day/night cycle. Biomes: ashlands (coal, flammable alien trees),
lava basins (tungsten ore near lava rivers), mountains (volcanoes with
sulfuric acid geysers and calcite). Exclusive recipes: Metallurgic science
pack, Foundry, Big mining drill, Turbo transport belt/underground
belt/splitter, Acid neutralisation. Solar panels output 4× Nauvis rate.
Acid neutralization byproduct is 500°C steam usable in turbines. No crude
oil, but coal liquefaction and heavy oil are available. Connected to
Nauvis and Gleba, 15,000 km each.

*Demolishers* (per the wiki's *Demolisher* page; unrelated to Nauvis biters
— see `references/enemies-and-evolution.md` for those) come in three
sizes, each with HP and a per-second regen rate: small 30,000 HP (regen
2,400/s), medium 100,000 HP (regen 7,800/s), big 300,000 HP (regen
24,000/s). They are **territorial**: "building structures in their
territory will disturb them and cause them to attack," implying they
otherwise leave players alone. Resistances are near-total and identical
across all three sizes: 100% fire, 100% impact, 100% laser, 60%
explosion (head) / 99% explosion (body), 50% physical (head) / 5–50%
physical (body), 10% poison (head) / 50% poison (body), 20/20% electric.
Contact deals "high damage to the player, and instantly destroy[s]
buildings and cliffs"; ranged attacks erupt explosions from the ground,
and they can coil around a player to block escape. On death they leave
remains "similar to that of black volcanic rock, which contain tungsten
ore."

**Fulgora** — "a new barren desert planet" of island plateaus separated by
deep oilsand oceans; 3-minute day/night cycle, no native enemies, buildable
area limited to plateaus. Lightning: each bolt carries 1 GJ; lightning
rods extract at 20% efficiency, lightning collectors at 40%; strike
priority favors collectors (priority 10,000) then rods (1,000) over
Fulgoran ruins/attractors (91–95); average harvestable power is 5–10 MW
per chunk across a full cycle. Solar panels run at only 20% efficiency (12
kW). Exclusive recipes: Electromagnetic science pack, Lightning rod,
Lightning collector, Recycler, Electromagnetic plant. Scrap recycling
yields (probabilistic): iron gear wheel 20%, solid fuel 7%, advanced
circuits 3%, processing units 2%, Holmium ore 1%. Planet properties table
from the page: Solar power 20%, Magnetic field 99, Gravity 8, Pressure
800. Connects to Nauvis (15,000 km), Gleba (15,000 km), Aquilo (30,000
km); orbit runs at 120% solar power.

**Gleba** — "moist, agricultural planet with fungal hills and swampy
lowlands"; 10-minute day/night cycle; uses **Spores** instead of pollution
as its native-enemy attractant, produced by biological processing.
Pentapods nest only on shallow-water tiles. Exclusive recipes: Agricultural
science pack, artificial/overgrowth jellynut/yumako soil, Biochamber.
Iron and copper come from bacteria cultivation in biochambers, not mining.
No crude oil — bioplastic/biosulfur/biolubricant substitute, plus rocket
fuel from jelly. Heating tower is a burner device generating electricity
via heat exchangers + steam turbines. Planet properties: Solar power 50%
(surface) / 200% (orbit), Gravity 20, Pressure 2000, Magnetic field 10.
Connected to all of Nauvis, Vulcanus, Fulgora, Aquilo (15,000–30,000 km).

*Pentapods* (per the wiki's *Pentapods* page; distinct from Nauvis biters
— see `references/enemies-and-evolution.md` for those) come in three
behavioral types, each in small/medium/big sizes with rising HP:
**Wrigglers** are melee (100/200/400 HP, dealing 3.75+3.75 to 8+8
combined physical+poison damage as they scale up, 50% laser resistance);
**Strafers** are ranged/circling (800/1400/2400 HP, explosive projectile
damage 67.5/90/144, ~2–10% physical resistance, 50% laser resistance);
**Stompers** are melee with the heaviest resistances (3,500/8,000/15,000
HP, 80% impact and 80% laser resistance, 2–50% physical resistance) and
apply an acid-splash-on-contact effect that slows the target's movement
speed to 60%. They nest in **egg rafts** placed on marsh tiles — a
regular egg raft has 500 HP (5,000 at max evolution) and a small egg raft
100 HP (1,000 at max evolution). Per the wiki, pentapods are drawn to
**Spores** (Gleba's pollution analog, produced by biological
processing) — an in-game achievement is literally themed around
attracting a pentapod group with spores.

**Aquilo** — "a vast ocean of liquid ammonia, with the occasional floating
iceberg"; final progression planet. Cold is the defining hazard: most
buildings freeze and stop without a heat source keeping them above 30°C
(heat pipes, nuclear reactors, heating towers prevent it); different
entities drain different heat amounts (pipes ~1 kW; underground belts
50–200 kW depending on tier). Solar panels: 1% of Nauvis rate, 0.6 kW peak.
Gravity-to-pressure ratio is 5× other planets, so construction/logistic
robots consume 5× normal power. Ammoniacal solution, lithium brine, and
fluorine cannot be shipped off-world; iron ore, copper ore, coal, and
stone don't exist locally and must be imported. Exclusive recipes:
Cryogenic plant, Fusion reactor, Fusion generator, Cryogenic science pack,
Quantum processor. Ice terrain requires ammoniacal-solution separation
into ice + ammonia, recombined into buildable platforms; most structures
there need concrete foundation to place reliably.

## Space platforms & asteroids

**[Space Age only]** — both features are stated as exclusive to the
expansion on their respective wiki pages.

**Space platforms**: self-contained orbital factories anchored by a
**space platform hub** (indestructible-until-lost-entirely — losing the
hub loses the whole platform); it's also the main storage/logistics
control point. Platforms start as a 10×10 area of **space platform
foundation** tiles (each tile 200 kg / 0.2 t; the hub itself is 20 t); the
foundation must stay a single connected area with no detached islands and
no enclosed holes. A platform may extend up to 200 tiles north of the
hub's center. Construction is entirely ghost-based remote view — regular
construction robots don't work in space, and chests, roboports, railways,
and burner devices cannot be placed on a platform.

Travel: **thrusters** mounted on the southern edge drive interplanetary
movement — more thrusters mean more speed but also attract more asteroids;
if thrusters stop mid-flight, gravity slowly pulls the platform toward the
nearest valid destination anyway. Platforms follow **automated schedules**
between planets, train-style, with wait conditions including damage taken,
item counts, passengers present, or circuit signals.

Cargo: **rockets** launched from a planetary rocket silo carry items up to
a platform (manual or automated via logistic requests); platforms send
items back down via **cargo pods** to a planetary cargo landing pad, at no
material cost (unlike the upward trip).

**Asteroids**: "floating minerals found in space," found near stationary
platforms and spawning at a higher rate during transit, where they can
damage a platform on contact. Five size classes (wiki's *Asteroid* page):

| Type | Health | Behavior |
|---|---|---|
| Asteroid chunk | — (harmless) | only type over Nauvis; destroyed instantly on contact |
| Small asteroid | 100–200 | splits into 2 chunks when destroyed |
| Medium asteroid | 400–800 | splits into 3 small asteroids; heavily laser-resistant |
| Big asteroid | 2,000–4,000 | spawns beyond certain planets; near-immune to physical/laser damage |
| Huge asteroid | 5,000–10,000 | spawns beyond Aquilo; needs specialized turrets (e.g. railguns) |

**Asteroid collectors** gather chunks and feed them to a **crusher**, which
grinds chunks into raw resources. Four chunk varieties: metallic → iron
ore/copper ore, carbonic → carbon/sulfur, oxide → ice/calcite, promethium →
used directly for science packs (not processable into other resources).
"Advanced asteroid processing" research unlocks alternate recipes that
extract additional materials from chunks. Orbits of specific planets spawn
different chunk-type ratios (e.g. Vulcanus orbit: metallic/carbonic/oxide;
Fulgora orbit: mostly metallic and carbonic).

## Elevated rails

**[separable mod]** — "elevated rails come as a separate mod which can be
enabled independently of Space Age," per the wiki, though the source notes
they matter most for crossing hazardous Space-Age planet terrain.

Adds **rail ramps** (transition trains between ground level and elevated
level) and **rail supports** (structural, hold elevated track up) — these
two are, per the page, "the only items in the game able to be built in the
oceans of Nauvis." A **rail support must be placed at least every 16
straight tiles**. Building: the rail planner tool builds elevated
sections; pressing G switches build level and attempts to place a ramp if
one is in inventory; holding Shift while targeting the opposite level
auto-places the needed supports/ramps.

Restrictions: several tall entities cannot be placed underneath elevated
track — big electric poles, roboports, rocket silos, oil refineries, and
Space-Age-specific tall buildings like agricultural towers and cargo bays.
Players and enemies cannot walk on elevated rail. Both regular and chain
rail signals work on elevated sections, but **train stops cannot be placed
there**. Removing a support auto-removes the rail sections that depend on
it.

## Scripting notes

**Detecting whether Space Age (or its sub-features) is active**, per the
Factorio Lua API docs (`LuaBootstrap`):

- `script.active_mods` — a dictionary of active mod name → version string.
  Space Age ships as separate mods, so checking for keys like
  `"space-age"` or `"quality"` in this table tells you which pieces are
  enabled.
- `script.feature_flags` — a dictionary of feature-flag name → boolean,
  specifically documented to include `expansion`, `quality`,
  `space_travel`, `spoiling`, `freezing`, `segmented_units`, and
  `expansion_shaders`. This is the more direct way to ask "is spoilage
  mechanically active" etc., rather than mapping mod names to behavior
  yourself.

**Surfaces are per-planet.** Per `LuaGameScript`:
- `game.surfaces` — sparse table of all `LuaSurface`, indexable by name or
  index (e.g. the Nauvis surface is present in vanilla and Space Age
  alike).
- `game.planets` — table of all `LuaPlanet` (indexed by planet name),
  present when Space Age content is active. Per `LuaPlanet`: it has a
  read-only `name`, a read-only `surface` (a `LuaPlanet` does **not**
  auto-generate its surface — call `create_surface()` to generate it, or
  `associate_surface(surface)` to link an existing one), a `prototype`
  reference, and `get_space_platforms(force)` to list constructed
  platforms belonging to a force.
- `LuaSpacePlatform` has its own read-only `surface` field ("the surface
  that belongs to this platform (if it has been created yet)") — a
  `LuaSurface`, same class as planet surfaces. So code written against
  `LuaSurface` generically (see `references/modding-api.md`) works for
  both planet surfaces and platform surfaces — the platform-specific
  behavior (no robots, restricted buildable entity list) lives in what
  you're allowed to build there, not in a different surface API.

## Sources

- https://wiki.factorio.com/Space_Age
- https://wiki.factorio.com/Quality
- https://wiki.factorio.com/Spoilage
- https://wiki.factorio.com/Spoilage_mechanics — followed from `Spoilage`,
  which is documented as "the result of an item's spoilage" and points to
  this separate page for spoil-timer mechanics; both pages are current
  (no redirect/404).
- https://wiki.factorio.com/Space_platform
- https://wiki.factorio.com/Asteroid
- https://wiki.factorio.com/Vulcanus
- https://wiki.factorio.com/Demolisher
- https://wiki.factorio.com/Fulgora
- https://wiki.factorio.com/Gleba
- https://wiki.factorio.com/Pentapods
- https://wiki.factorio.com/Aquilo
- https://wiki.factorio.com/Elevated_rail
- https://lua-api.factorio.com/latest/classes/LuaBootstrap.html
- https://lua-api.factorio.com/latest/classes/LuaGameScript.html
- https://lua-api.factorio.com/latest/classes/LuaPlanet.html
- https://lua-api.factorio.com/latest/classes/LuaSpacePlatform.html
