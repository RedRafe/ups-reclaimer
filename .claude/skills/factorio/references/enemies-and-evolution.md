# Enemies & Evolution (Nauvis) — Biters, Turrets & Evolution Factor

Nauvis-native enemy stats, the evolution factor formula, and military
structures. Figures below are quoted or closely paraphrased from the wiki
pages listed in **Sources**; anything not confirmed on a fetched page is
marked **unverified** rather than guessed.

Combat fundamentals (damage types, the resistance formula, piercing) and
pollution production/absorption/spawner-muster mechanics already live in
`mechanics.md` (**Combat** and **Pollution** sections) — this file does not
repeat them, only references them where relevant.

Space Age planet-native enemies — **Pentapods** (Gleba) and
**Demolishers** (Vulcanus) — are out of scope here; see `space-age.md` for
their stats. This file covers Nauvis biters/spitters/worms only.

## Evolution factor

From the wiki's *Evolution* page. The evolution factor is a single global
value in `[0, 1)` built from three additive raw contributions, then
squashed:

```
evolution_factor = total_evolution / (1 + total_evolution)
```

Each of the three raw contributions is scaled down as evolution rises,
via a marginal-scaling term `(1 − evolution_factor)²` — i.e. the same
absolute cause (an extra second, an extra nest destroyed, an extra unit of
pollution) contributes less to the raw total the higher evolution already
is.

**Default coefficients** (base game defaults; a mod/map setting can change
these):

| Source | Variable | Increase | Rough equivalent |
|---|---|---|---|
| Time | `time_factor` | 0.000004 per second | ~267 pollution/minute worth of effect |
| Spawner destruction | `destroy_factor` | 0.002 per nest destroyed | ~2,222 pollution units worth |
| Pollution produced | `pollution_factor` | 0.0000009 per unit of pollution | 1 unit baseline |

Note the asymmetry: destroying spawners and generating pollution both
*raise* evolution — there is no "clean" way to fight biters that doesn't
also push evolution up (destroying nests is itself a direct contributor,
separate from and in addition to any pollution the fight produces).

**Enemy-appearance thresholds** (evolution factor at which a tier starts
spawning), per the *Evolution*/*Enemies#Evolution* page's table (columns:
evolution factor, pollution equivalent, appearance):

| Evolution factor | Unlocks |
|---|---|
| 20% | Medium Biter |
| 25% | Small Spitter |
| 40% | Medium Spitter |
| 50% | Big biters and big spitters |
| 90% | Behemoth biters and behemoth spitters |

Small biters have **no appearance threshold** — the page states plainly
"In the beginning of a game, there will only be the small ones," and the
table's own 10% row has an empty Appearance cell (10% is listed only as a
pollution-equivalent milestone, not as when small biters first unlock).
Treat small biters as present from evolution factor 0.

**Worm expansion gates** (also from *Evolution*, cross-checked against the
worm-tier requirements on *Enemies*/*Biters*):

| Evolution factor | Unlocks |
|---|---|
| 0.3 | Medium worms |
| 0.5 | Big worms |
| 0.9 | Behemoth worms |

**Per-planet differences**: the page states "the evolution factor is a
global variable" (a single number, not per-surface), but also notes a
2.0.17 change that "Gleba evolution is now more gradual" — implying Gleba's
Pentapod threat scales differently from the Nauvis biter formula above. No
specific Gleba coefficients were given on this page — **unverified**; see
`space-age.md` for Pentapod specifics if covered there.

Spawner (nest) HP itself scales with evolution — see the table below.

## Biters, spitters & worms

All values from the *Biters* and *Enemies* wiki pages (cross-checked
against each other; figures agreed). Damage figures are per-hit before any
resistance is applied on the target (see `mechanics.md` → Combat for the
resistance formula) and before the attacker's own damage-type resistance
on itself. "Speed" for worms is n/a — worms are stationary.

**Biters** (melee, physical damage):

| Tier | HP | Damage | Attack speed | Move speed | Range | Resistances |
|---|---|---|---|---|---|---|
| Small | 15 | 7 physical | 1.71/s | 43.2 km/h | 0.5 | none |
| Medium | 75 | 15 physical | 1.71/s | 51.8 km/h | 1 | Explosion 0/10%, Physical 4/10% |
| Big | 375 | 30 physical | 1.71/s | 49.7 km/h | 1.5 | Explosion 0/10%, Physical 8/10% |
| Behemoth | 3000 | 90 physical | 1.2/s | 64.8 km/h | 1.5 | Explosion 12/10%, Physical 12/10% |

**Spitters** (ranged, acid projectile):

| Tier | HP | Damage | Attack speed | Move speed | Range | Resistances |
|---|---|---|---|---|---|---|
| Small | 10 | 12 acid | 0.6/s | 40.0 km/h | 13 | Explosion 0/10% |
| Medium | 50 | 24 acid | 0.6/s | 35.6 km/h | 14 | Explosion 0/10% |
| Big | 200 | 36 acid | 0.6/s | 32.4 km/h | 15 | Explosion 0/15% |
| Behemoth | 1500 | 60 acid | 0.6/s | 32.4 km/h | 16 | Explosion 0/30% |

**Worms** (stationary, ranged acid projectile; unlock gates above):

| Tier | HP | Damage | Attack speed | Range | Resistances | Evolution gate |
|---|---|---|---|---|---|---|
| Small | 200 | 36 acid | 0.65/s | 25 | none listed (see note) | (available from start) |
| Medium | 500 | 48 acid | 0.65/s | 30 | Explosion 5/15%, Fire 2/50%, Laser 20%, Physical 5/0% | 0.3 |
| Big | 1500 | 72 acid | 0.65/s | 38 | Explosion 10/30%, Fire 3/70%, Laser 50%, Physical 10/0% | 0.5 |
| Behemoth | 3000 | 96 acid | 0.65/s | 48 | Explosion 10/30%, Fire 3/70%, Laser 80%, Physical 10/0% | 0.9 |

The *Enemies* page's Small worm stat block lists no "Resistances:" section at
all (only Health/Range/Acid projectile/Acid puddle) — unlike Medium/Big/
Behemoth worms, which each have an explicit Resistances list. The page's
general Worms intro does say worms as a class are "highly resistant to
fire," but gives no specific number for Small worm, so no per-tier value is
stated here — **unverified** for Small worm specifically.

**Spawners (biter/spitter nests)**: base HP 350, scaling up to 3500 "at max
evolution" (the *Biters* page's phrasing; exact scaling curve between 0 and
max evolution was not given — **unverified**). The *Enemies* page adds
nest resistances: Explosion 5/0%, Fire 3/60%, Physical 2/15%. See
`mechanics.md` → Pollution for the per-spawner pollution-absorption
thresholds that trigger attack musters (that table lives there, not here,
to avoid duplication).

Worms attack automatically at range and do not move; biters/spitters path
toward targets. Neither page gave an explicit vision/aggro range distinct
from attack range — **unverified**.

## Military structures — turrets, walls, mines

All at normal (non-quality) stats unless noted; each entry's wiki page also
lists Uncommon/Rare/Epic/Legendary quality scaling for HP and range, only
the normal-quality baseline is tabulated here.

| Structure | HP | Range | Fire rate | Damage | Power/fuel |
|---|---|---|---|---|---|
| Gun turret | 400 | 18 | 10/s | not fixed — scales with ammo + separate turret-damage research (multiplicative) | none; ammo only (firearm/piercing/uranium magazines, up to 10 loaded) |
| Laser turret | 1000 | 24 | 1.5/s | 20 laser | 1.2 MW firing / 24 kW idle; 800 kJ per shot |
| Flamethrower turret | 1400 | 6–30 (120° arc) | 30/s | 3 fire contact + 13/s ground fire + 100/s fire on ignited targets (30–75s burn) | 3 fluid/s; crude oil 100%, heavy oil 105%, light oil 110% damage |
| Artillery turret | 2000 | auto 224 / manual 560 (min 32) | 0.3/s | one-shots most enemies; behemoth worms/high-evolution spawners can take 2 shots | artillery shells, 15-shell capacity |
| Wall | 350 | — (blocks melee only) | — | — | Acid 0/80%, Explosion 10/30%, Fire 0/100%, Impact 45/60%, Laser 0/70%, Physical 3/20% |
| Land mine | 15 | trigger 2.5 tiles / blast radius 6 | — | 250 | stuns enemies 3s on detonation |

Notes not fitting the table:

- **Gun turret**: needs no power, "can operate practically anywhere as
  long as they have sufficient ammunition." Physical projectile damage
  research upgrades ammo damage and turret damage as two separate
  multiplicative bonuses.
- **Laser turret**: no ammo, draws from the grid; firing-rate research
  increases both fire rate and power draw together, so laser walls can
  cause "electricity usage spikes... offset by using accumulators."
- **Wall**: "Walls only block melee attacks, projectile attacks go over
  them." Also: enemies already aggro'd on a turret or the player will
  pursue that aggressor rather than necessarily stopping to break through
  a wall in the way.
- **Land mine**: "do not damage allied buildings or players." After
  placement they "take 2 seconds to arm and bury in the ground" — during
  that window they're visible and can be destroyed by biters, i.e. they
  are not yet a live threat to (or safely hidden from) approaching enemies.
- **Artillery turret**: in automatic mode "can only target enemy
  structures (spawners and worms), not mobile units (biters and
  spitters)" — everything caught in the blast radius still takes damage,
  but auto-fire will not initiate on a passing biter/spitter. Manual
  targeting has no such restriction.

## Peaceful mode

Per the *Peaceful_mode* wiki page:

- "Enemies don't begin fights, only responding if the player (or a
  structure) fires at them."
- Retaliation is local: "only the enemies located near the fired shot are
  aggravated and they do not call other enemies to join them."
- Aggravated enemies "primarily attack the structures and players that
  initiated the aggression and also the structures that block their
  paths," then most return to peaceful — though some instead "continue a
  nonstop rampage" against nearby (not faraway) structures.
- **Expansion is disabled**: "when a map is in peaceful mode, the enemies
  will not expand."
- **Evolution in peaceful mode**: the page does not state whether
  time/pollution/destroy-factor evolution accrual is suspended or
  continues — **unverified**; do not assume evolution freezes just because
  expansion does.

## Sources

- https://wiki.factorio.com/Evolution
- https://wiki.factorio.com/Biters
- https://wiki.factorio.com/Enemies
- https://wiki.factorio.com/Military_units_and_structures — classification/
  targeting overview only, no numeric stats of its own.
- https://wiki.factorio.com/Gun_turret
- https://wiki.factorio.com/Laser_turret
- https://wiki.factorio.com/Flamethrower_turret
- https://wiki.factorio.com/Artillery_turret
- https://wiki.factorio.com/Wall
- https://wiki.factorio.com/Land_mine
- https://wiki.factorio.com/Peaceful_mode
