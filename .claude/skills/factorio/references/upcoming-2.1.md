# Upcoming: Factorio 2.1 (UNRELEASED)

> ⚠️ **UNRELEASED / SUBJECT TO CHANGE.** Everything here describes **Factorio
> 2.1**, which is *not the version the rest of this skill targets* (2.0 +
> Space Age). Per the wiki's Upcoming features page: experimental release was
> planned for **end of June 2026**, stable **by end of summer 2026**, and 2.1
> is intended to be "the final update, with a shift afterwards to bug-fixing,
> platform compatibility, and modding features." Details, numbers, and names
> below are pre-release and may change or be cut before launch. Do **not**
> treat these as current behavior — for shipped facts use the other reference
> files. When precision matters, WebFetch the source pages in `## Sources` for
> the latest state.

This file exists so the skill can *reason about* what 2.1 is expected to
change without contaminating the stable 2.0 references. If you are writing a
mod or map for a released game today, target 2.0 + Space Age.

## Space logistics

- Rocket silos request only the materials actually needed for construction,
  instead of requesting full rockets.
- Space platforms prioritize requesting foundations and cargo bays before other
  materials.
- Mods can modify rocket silo weight capacity.

## Space platforms

- Platforms attempt to request items from all planets by default, with an
  optional single-planet filter.
- Platforms wait until all orbital drop slots are empty before leaving.
- Platforms can request items from orbiting planets or from other platforms,
  with a toggleable delivery option.

## New building: Landing Pad Unloading Bay

- A special cargo bay that lets inserters remove items.
- Placement restricted to planets within a certain radius of cargo landing pads.
- Dimensions 4×5 tiles, sized for direct train insertion.
- Elevated rails can be placed over it and over ordinary cargo bays.

## Circuit network additions

- Space platform requests become controllable via the circuit network.
- Radar can specify a "universe" channel to transmit signals across
  planets/platforms.
- All circuit-connected entities can toggle input/output on the green/red wire
  channels.
- New circuit connections:
  - Pipes — contents and temperature readable.
  - Boilers / heat exchangers — conditional enable.
  - Landmines — conditional detonation.
  - Labs / biolabs — contents and current research readable; conditional
    "research this technology".

## Visual changes

- Improved environmental graphics for the Space Age planets.
- Flamethrower turrets placeable diagonally (like railgun turrets).
- Demolisher models on Vulcanus tweaked to look more intimidating.
- Planets visible in the background while space platforms orbit.
- Updated models: rocket silo, oil refinery, assembly machines.

## Quality changes

- The **Quality** mod is no longer required for Space Age — it becomes
  "recommended" rather than mandatory.
- The **Recycler** is moved to a separate mod (required for Fulgora
  progression). *(This changes the 2.0 arrangement described in
  `space-age.md`, where Recycler ships as a separable bundled mod alongside
  Space Age — see that file for the current/2.0 state.)*
- Quality modules are banned from crushers running asteroid reprocessing.
- Train rolling stock gains quality-dependent improvements:
  - Locomotives — higher acceleration and top speed.
  - Cargo wagons — increased stack count (up to 100).
  - Fluid wagons — increased capacity (up to 125,000 units).
  - Artillery wagons — increased shooting range.

## Miscellaneous changes

- Pumpjacks and burner mining drills become flippable.
- Flipping inserters, mining drills, and the recycler changes their belt
  drop-side behavior.
- Fluid system improved to prevent mixing in multi-input/output entities.
- Pumps can load/unload fluid wagons on curves and transfer fluid between
  adjacent wagons.
- Upgrade planner works on locomotives and wagons, with a train wait override.

## Achievements

- Multiple new achievements planned.
- A possible special achievement requiring all others to be earned in a single
  playthrough.

## Maintenance (for skill maintainers)

This file has a limited shelf life. 2.1 stable was planned for around
mid-2026, so this content **will drift as features actually ship** — some may
change, some may be cut.

When 2.1 is released:

1. Re-fetch the sources below and diff against this file — what shipped, what
   changed, what was dropped.
2. Fold the **confirmed** changes into the main references (`mechanics.md`,
   `space-age.md`, `data-raw.md`, `modding-api.md`), re-sourced to the live
   2.1 wiki/API pages, and update the version banner in `SKILL.md`.
3. Shrink this file to only genuinely-still-upcoming items, or delete it and
   remove its pointers from `SKILL.md` and `url-map.md` once nothing here is
   unreleased.

Until then, treat everything above as pre-release.

## Sources

- https://wiki.factorio.com/Upcoming_features (Factorio 2.1 upcoming features)
- The wiki page cites Friday Facts posts FFF-440, FFF-441, FFF-442 and the
  official forums for the underlying details.
