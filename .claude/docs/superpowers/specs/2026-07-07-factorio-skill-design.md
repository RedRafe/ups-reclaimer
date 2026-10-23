# Factorio Skill — Design

**Date:** 2026-07-07
**Status:** Approved, pre-implementation
**Target game version:** Factorio 2.0 + Space Age expansion

## Purpose

A distributable Claude Code agent skill that gives Claude working knowledge of
Factorio for two equally-weighted use cases:

1. **Lua modding / scenarios** — writing `control.lua`, scenarios, map/surface
   generation, prototypes/`data.raw`, and mods using the Factorio runtime API
   (the RedMew style of work).
2. **Game mechanics reference** — recipes, ratios, entity stats, terminology,
   limits, quirks, and capabilities, for reasoning about designs.

The skill lives in this repo so it can be copied/installed by others.

## Non-goals

- Not a gameplay strategy guide or "how to beat the game" walkthrough.
- Not an exhaustive offline mirror of the wiki — it is curated + fetch-extensible.
- Not targeting pre-2.0 versions (facts are 2.0 / Space Age).

## Knowledge strategy: Hybrid

The wiki (wiki.factorio.com) plus the Lua API (lua-api.factorio.com) are
thousands of pages — too much to embed fully. The skill therefore:

- **Embeds curated essentials** — terminology, cross-cutting quirks/limits, the
  API structure, key ratios — directly in `SKILL.md` and distilled reference
  files.
- **Provides a URL map** so future uses can `WebFetch` the exact page for depth
  on demand instead of guessing.

Self-contained enough to be useful without network; extensible when depth is
needed.

## File layout

Skill lives at the **repo root** (the whole repo is the skill), standard skill
format:

```
SKILL.md              # overview, core terminology, cross-cutting quirks/limits,
                      # version banner (2.0 + Space Age), "when to fetch" guide
references/
  modding-api.md      # lua-api.factorio.com runtime: game/script/LuaSurface/
                      # LuaEntity, events, data/control/settings stages, gotchas
  data-raw.md         # prototype stage: data.raw structure, defining/overriding
                      # prototypes, key prototype types
  mechanics.md        # ratios, belt/inserter throughput, power, combat, pollution,
                      # circuits, hard limits & magic numbers
  space-age.md        # quality, spoilage, planets, elevated rails, asteroids —
                      # the 2.0 expansion mechanics that break old assumptions
  quirks.md           # counterintuitive behaviors & common mistakes (the gotchas)
  url-map.md          # topic -> exact wiki/lua-api URL for deep fetch on demand
docs/superpowers/specs/  # this design + future specs
```

Each reference file is distilled prose + tables, version-tagged where
version-sensitive, and ends with the source URLs it was distilled from.

## Trigger design (frontmatter `description`)

Keyword-rich so it auto-activates on both paths:

- Modding-code path: `control.lua`, scenario, surface/map generation, prototype,
  `data.raw`, mod, Factorio runtime API, LuaSurface, LuaEntity, events.
- Mechanics-question path: game mechanics, recipes, ratios, entity stats,
  terminology, limits, quirks, quality, spoilage, planets.

Explicitly scoped to Factorio 2.0 / Space Age.

## Content sourcing — accuracy discipline

**Facts are NOT written from memory.** 2.0 / Space Age is recent and easy to get
subtly wrong — and the version-sensitive limits/quirks are exactly the valuable
part. At build time:

- `WebFetch` the actual wiki.factorio.com and lua-api.factorio.com pages.
- Distill each into the relevant reference file.
- Cite the source URL in-file.
- Tag version-sensitive facts.

## Verification

A skill has no unit tests, so verification is:

1. **Source-trace self-review** — every claimed fact traces to a fetched source
   URL recorded in the file.
2. **Realistic-prompt spot checks** — exercise the skill against a couple of
   representative prompts (e.g. "write a scenario that spawns X on chunk
   generation", "what's the belt/inserter ratio for Y") to confirm the structure
   surfaces the right information.

## Open considerations

- Root-level vs `skills/factorio/` layout: design assumes root-level; revisit if
  the repo later hosts multiple skills.
