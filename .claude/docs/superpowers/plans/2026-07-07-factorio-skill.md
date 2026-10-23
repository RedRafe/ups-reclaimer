# Factorio Skill Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a distributable Claude Code agent skill named `factorio` that gives Claude working knowledge of Factorio 2.0 + Space Age for both Lua modding/scenarios and game-mechanics reasoning.

**Architecture:** A root-level skill (`SKILL.md` + `references/`) following the standard skill format. Curated essentials are embedded; a URL map enables on-demand `WebFetch` for depth. All facts are distilled from fetched wiki.factorio.com / lua-api.factorio.com pages and cited in-file — never written from memory.

**Tech Stack:** Markdown only. Sources fetched via WebFetch. No build tooling, no runtime.

## Global Constraints

- **Game version:** All facts target Factorio **2.0 + Space Age**. Tag any version-sensitive fact with its version. Do not include pre-2.0 facts unless explicitly labeled as historical context.
- **No facts from memory:** Every factual claim (numbers, API signatures, prototype fields, limits) MUST be distilled from a page fetched during implementation. Each reference file ends with a `## Sources` section listing the exact URLs it was built from.
- **Sources:** `wiki.factorio.com` for mechanics/terminology/data.raw; `lua-api.factorio.com/latest/` for runtime + prototype API.
- **Format:** Standard skill format — `SKILL.md` at repo root with YAML frontmatter (`name`, `description`), reference files under `references/`.
- **Fetch reality:** Some listed URLs may redirect or 404 (wiki reorganizations). When a URL fails, find the current equivalent by fetching the wiki/API index or search, record the URL you actually used, and note substitutions.
- **Distillation over dumping:** Reference files are concise prose + tables, not raw page copies. Prefer ratios, limits, gotchas, and structure a builder actually needs.

---

## File Structure

- `SKILL.md` — frontmatter (trigger), version banner, core terminology, cross-cutting quirks, "when to fetch" guide, index of reference files.
- `references/modding-api.md` — runtime API: data/settings/control lifecycle, `game`/`script`, `LuaSurface`, `LuaEntity`, events, common gotchas.
- `references/data-raw.md` — prototype stage: `data.raw` structure, defining/overriding prototypes, key prototype types.
- `references/mechanics.md` — ratios, belt/inserter throughput, power, pollution, combat, circuit network, hard limits & magic numbers.
- `references/space-age.md` — quality, spoilage, planets, elevated rails, asteroids — 2.0 expansion mechanics that break old assumptions.
- `references/quirks.md` — counterintuitive behaviors & common mistakes.
- `references/url-map.md` — topic → exact wiki/lua-api URL for on-demand deep fetch.
- `README.md` — short "what this is / how to install" for repo visitors.

Reference files are independent of each other (good for parallel execution). `SKILL.md` body (Task 8) depends on all reference files existing so it can index them accurately.

**Per-task verification model:** There are no unit tests. Each content task is verified by a **source-trace check**: every non-obvious factual claim in the file maps to a URL in that file's `## Sources` section. Tasks 9 does end-to-end spot checks.

---

### Task 1: Skill skeleton + frontmatter

**Files:**
- Create: `SKILL.md`
- Create: `README.md`
- Create: `references/.gitkeep`

**Interfaces:**
- Produces: `SKILL.md` with valid frontmatter (`name: factorio`) discoverable as a skill; body is a stub filled in Task 8.

- [ ] **Step 1: Write `SKILL.md` frontmatter + stub**

```markdown
---
name: factorio
description: >-
  Factorio 2.0 + Space Age reference for modding and game mechanics. Use when
  writing control.lua, scenarios, map/surface generation, prototypes or
  data.raw, or mods (Factorio runtime API, LuaSurface, LuaEntity, events), and
  when reasoning about game mechanics — recipes, ratios, entity stats,
  terminology, limits, quirks, quality, spoilage, planets. Targets Factorio 2.0
  and the Space Age expansion.
---

# Factorio (2.0 + Space Age)

> Version: Factorio **2.0** with the **Space Age** expansion. Facts predating
> 2.0 are out of scope unless explicitly labeled historical.

<!-- Body filled in Task 8. -->
```

- [ ] **Step 2: Write `README.md`**

```markdown
# factorio-skill

A Claude Code agent skill giving Claude working knowledge of **Factorio 2.0 +
Space Age** — for Lua modding/scenarios and game-mechanics reasoning.

## Install

Copy this repo's `SKILL.md` and `references/` into your skills directory
(e.g. a plugin's `skills/factorio/`, or `~/.claude/skills/factorio/`).

## Contents

- `SKILL.md` — overview, terminology, quirks, when to fetch deeper.
- `references/` — distilled topic files + a topic→URL map for on-demand depth.

All facts are distilled from wiki.factorio.com and lua-api.factorio.com and
cited in-file.
```

- [ ] **Step 3: Verify frontmatter parses**

Run: `head -20 SKILL.md` and confirm the YAML block is well-formed (opens and closes with `---`, `name` and `description` present).
Expected: valid frontmatter, no tabs in YAML.

- [ ] **Step 4: Commit**

```bash
git add SKILL.md README.md references/.gitkeep
git commit -m "feat: scaffold factorio skill (frontmatter + readme)"
```

---

### Task 2: `references/modding-api.md`

**Files:**
- Create: `references/modding-api.md`

**Interfaces:**
- Produces: `references/modding-api.md` — the runtime/scripting reference. Task 8 links to it.

**Sources to fetch (adapt if a URL moved):**
- `https://lua-api.factorio.com/latest/index.html`
- `https://lua-api.factorio.com/latest/auxiliary/data-lifecycle.html`
- `https://lua-api.factorio.com/latest/classes/LuaGameScript.html`
- `https://lua-api.factorio.com/latest/classes/LuaSurface.html`
- `https://lua-api.factorio.com/latest/classes/LuaEntity.html`
- `https://lua-api.factorio.com/latest/events.html`
- `https://lua-api.factorio.com/latest/auxiliary/libraries.html`
- `https://wiki.factorio.com/Tutorial:Scripting`

- [ ] **Step 1: Fetch the source pages**

WebFetch each URL above. For lifecycle, capture the three stages (settings → data → control) and what code may run in each. For `LuaSurface`/`LuaEntity`/`LuaGameScript`, capture the most-used members (creating/finding entities, `create_entity`, `find_entities_filtered`, `game.surfaces`, `game.players`). For events, capture how to register (`script.on_event`, `defines.events.*`) and the on_init/on_load/on_configuration_changed trio.

- [ ] **Step 2: Write the file**

Structure (fill from fetched content, not memory):
```markdown
# Modding / Scripting Runtime API

## The three stages
(settings, data, control — what runs when, what's available in each)

## Global state & determinism
(the `storage` table (renamed from `global` in 2.0), on_init vs on_load,
why non-determinism/desyncs happen, what you must NOT store)

## Core objects
### game (LuaGameScript)
### script (event registration, on_init/on_load/on_configuration_changed)
### LuaSurface  (create_entity, find_entities_filtered, tiles, chunks)
### LuaEntity   (common properties/methods)

## Events
(registration patterns, defines.events, tick handlers, event.filter)

## Common gotchas
(bulleted; e.g. storing LuaObject refs, validity checks, storage vs locals)

## Sources
(URLs actually used)
```

- [ ] **Step 3: Source-trace check**

Re-read the file; confirm every API name, stage rule, and the `storage`/`global` rename trace to a fetched page listed in `## Sources`. Remove any claim you cannot trace.

- [ ] **Step 4: Commit**

```bash
git add references/modding-api.md
git commit -m "docs: add modding/scripting runtime API reference"
```

---

### Task 3: `references/data-raw.md`

**Files:**
- Create: `references/data-raw.md`

**Interfaces:**
- Produces: `references/data-raw.md` — prototype-stage reference. Task 8 links to it.

**Sources to fetch:**
- `https://wiki.factorio.com/Data.raw`
- `https://lua-api.factorio.com/latest/auxiliary/data-lifecycle.html`
- `https://lua-api.factorio.com/latest/prototypes.html`
- `https://lua-api.factorio.com/latest/types.html`
- `https://wiki.factorio.com/Tutorial:Modding_tutorial/Gangsir`

- [ ] **Step 1: Fetch the source pages**

WebFetch each. Capture: what `data.raw` is (the global prototype table keyed by type→name), how mods add/override/remove prototypes in the data stage, `data:extend{}`, and the top-level prototype categories.

- [ ] **Step 2: Write the file**

Structure:
```markdown
# Prototype Stage & data.raw

## What data.raw is
(the global table; type -> name -> prototype)

## Defining prototypes
(data:extend{...}, structure of a prototype definition)

## Overriding / removing existing prototypes
(mutating data.raw in a later mod's data-updates/data-final-fixes)

## Data stage files
(data.lua, data-updates.lua, data-final-fixes.lua — load order)

## Key prototype categories
(table: category -> what it defines, e.g. recipe, item, entity types)

## Common gotchas
(referencing not-yet-loaded prototypes, icon/size requirements)

## Sources
```

- [ ] **Step 3: Source-trace check**

Confirm every prototype field/category name and load-order rule traces to `## Sources`. Remove untraceable claims.

- [ ] **Step 4: Commit**

```bash
git add references/data-raw.md
git commit -m "docs: add data.raw / prototype stage reference"
```

---

### Task 4: `references/mechanics.md`

**Files:**
- Create: `references/mechanics.md`

**Interfaces:**
- Produces: `references/mechanics.md` — gameplay numbers/ratios reference. Task 8 links to it.

**Sources to fetch:**
- `https://wiki.factorio.com/Transport_belts`
- `https://wiki.factorio.com/Inserters`
- `https://wiki.factorio.com/Electric_system`
- `https://wiki.factorio.com/Pollution`
- `https://wiki.factorio.com/Combat`
- `https://wiki.factorio.com/Circuit_network`
- `https://wiki.factorio.com/Belt_transport_system`

- [ ] **Step 1: Fetch the source pages**

WebFetch each. Capture concrete 2.0 numbers: belt throughput (items/s for yellow/red/blue), inserter throughput/swing rates, power production/consumption units (kW/MW, J), pollution mechanics, combat damage/resistance model, circuit-network signal basics.

- [ ] **Step 2: Write the file**

Structure:
```markdown
# Game Mechanics — Ratios, Limits & Numbers

## Belts & throughput
(table: belt tier -> items/s; sideloading notes)

## Inserters
(table: inserter type -> items/s at various conditions)

## Power
(units, generation vs consumption, accumulators, priorities)

## Pollution
(sources, spread, effect on enemies)

## Combat
(damage types & resistances, how mitigation is computed)

## Circuit network
(signals, wires, combinators — enough to script/design with)

## Hard limits & magic numbers
(anything with a fixed cap or constant)

## Sources
```

- [ ] **Step 3: Source-trace check**

Every number must trace to a `## Sources` URL. Flag any figure you could not confirm as "unverified" rather than guessing.

- [ ] **Step 4: Commit**

```bash
git add references/mechanics.md
git commit -m "docs: add mechanics/ratios reference"
```

---

### Task 5: `references/space-age.md`

**Files:**
- Create: `references/space-age.md`

**Interfaces:**
- Produces: `references/space-age.md` — expansion mechanics reference. Task 8 links to it.

**Sources to fetch:**
- `https://wiki.factorio.com/Space_Age`
- `https://wiki.factorio.com/Quality`
- `https://wiki.factorio.com/Spoilage`
- `https://wiki.factorio.com/Space_platform`
- `https://wiki.factorio.com/Asteroid`
- (planet pages, e.g. `https://wiki.factorio.com/Vulcanus`, `Fulgora`, `Gleba`, `Aquilo`)

- [ ] **Step 1: Fetch the source pages**

WebFetch each. Capture: quality tiers and how quality propagates, spoilage timers/mechanics, the planets and their distinguishing mechanics, space platforms, elevated rails, asteroids.

- [ ] **Step 2: Write the file**

Structure:
```markdown
# Space Age Expansion Mechanics

> These change assumptions valid in base 2.0. Flag when a mechanic only
> exists with Space Age enabled.

## Quality
(tiers, quality modules, how quality flows through crafting)

## Spoilage
(which items spoil, timers, spoil results, freshness on belts/inserters)

## Planets
(table: planet -> signature mechanic/resource/threat)

## Space platforms & asteroids
## Elevated rails
## Scripting notes
(surface-per-planet, how to detect Space Age is active)

## Sources
```

- [ ] **Step 3: Source-trace check**

Confirm each mechanic + the "Space Age only" flags trace to `## Sources`.

- [ ] **Step 4: Commit**

```bash
git add references/space-age.md
git commit -m "docs: add Space Age expansion mechanics reference"
```

---

### Task 6: `references/quirks.md`

**Files:**
- Create: `references/quirks.md`

**Interfaces:**
- Produces: `references/quirks.md` — gotchas reference. Task 8 links to it.

**Sources:** Distill from pages already fetched in Tasks 2–5 (do not invent). Additionally may fetch:
- `https://wiki.factorio.com/Multiplayer` (desync causes)
- `https://lua-api.factorio.com/latest/auxiliary/storage.html` (if present)

- [ ] **Step 1: Assemble quirks from fetched sources**

Collect counterintuitive behaviors surfaced while writing Tasks 2–5 (e.g. determinism/desync rules, `storage` restrictions, prototype load-order surprises, belt sideloading, inserter capacity bonus, quality/spoilage interactions). Each quirk must trace to a source already fetched.

- [ ] **Step 2: Write the file**

Structure:
```markdown
# Quirks & Common Mistakes

Each entry: **what surprises people → why → what to do instead.**

## Scripting quirks
## Prototype/data-stage quirks
## Mechanics quirks
## Space Age quirks

## Sources
```

- [ ] **Step 3: Source-trace check**

Every quirk cites a source URL (may reuse URLs from Tasks 2–5).

- [ ] **Step 4: Commit**

```bash
git add references/quirks.md
git commit -m "docs: add quirks & common mistakes reference"
```

---

### Task 7: `references/url-map.md`

**Files:**
- Create: `references/url-map.md`

**Interfaces:**
- Produces: `references/url-map.md` — topic→URL index for on-demand fetch. Task 8 links to it.

- [ ] **Step 1: Compile the map**

Collect every URL actually used across Tasks 2–6 plus useful entry points not yet distilled (wiki main page, lua-api class index, prototype index). Group by topic.

- [ ] **Step 2: Write the file**

Structure:
```markdown
# URL Map — Fetch These for Depth

When embedded references aren't enough, WebFetch the relevant page below.
Prefer `lua-api.factorio.com/latest/` for API, `wiki.factorio.com` for mechanics.

## Entry points
- Runtime API index: https://lua-api.factorio.com/latest/index.html
- Prototype index: https://lua-api.factorio.com/latest/prototypes.html
- Wiki home: https://wiki.factorio.com/

## Modding / scripting
(topic -> URL)

## Prototypes / data.raw
## Mechanics
## Space Age

## Note
URLs verified on 2026-07-07 against `/latest/`. If a page 404s, check the
API/wiki index — the site reorganizes across versions.
```

- [ ] **Step 3: Verify links resolve**

WebFetch 3–4 sampled URLs from the map; confirm they resolve (not 404). Fix any dead links.

- [ ] **Step 4: Commit**

```bash
git add references/url-map.md
git commit -m "docs: add topic->URL fetch map"
```

---

### Task 8: Fill `SKILL.md` body

**Files:**
- Modify: `SKILL.md`

**Interfaces:**
- Consumes: all `references/*.md` files (must exist and be committed).
- Produces: complete `SKILL.md` that a reader can navigate from.

- [ ] **Step 1: Write the body**

Append after the version banner:
```markdown
## What you get here

Curated essentials below; deeper detail in `references/`. When a fact isn't
here, WebFetch the right page via `references/url-map.md` — do not answer
Factorio 2.0 facts from memory.

## Core terminology

(10–20 key terms: prototype vs entity, surface, chunk, tick (60/s), UPS,
storage table, data stage vs control stage, recipe, assembler, quality,
spoilage, planet/surface. Each one line. Distill from Glossary +
already-fetched pages.)

## Cross-cutting quirks (read before scripting)

(3–6 highest-value gotchas, e.g. determinism/desync, `storage` restrictions,
LuaObject validity. Link to references/quirks.md for the full list.)

## When to fetch deeper

(short decision guide: mechanics number → mechanics.md / wiki; API signature →
modding-api.md / lua-api; prototype field → data-raw.md; anything missing →
url-map.md)

## Reference files

- `references/modding-api.md` — runtime/scripting API.
- `references/data-raw.md` — prototype stage & data.raw.
- `references/mechanics.md` — ratios, limits, numbers.
- `references/space-age.md` — expansion mechanics.
- `references/quirks.md` — gotchas & common mistakes.
- `references/url-map.md` — topic → URL for deep fetch.
```

- [ ] **Step 2: Source-trace check**

Terminology and quirks in `SKILL.md` must trace to a fetched source (reuse reference-file sources). Confirm all six reference links point to files that exist.

- [ ] **Step 3: Verify links**

Run: `ls references/` and confirm all six linked files exist.
Expected: all present.

- [ ] **Step 4: Commit**

```bash
git add SKILL.md
git commit -m "docs: complete SKILL.md body (terminology, quirks, navigation)"
```

---

### Task 9: End-to-end verification

**Files:**
- Modify: none (may fix issues found, then commit).

- [ ] **Step 1: Frontmatter/description sanity**

Confirm `description` contains both trigger paths (modding keywords AND mechanics keywords) and names version 2.0 / Space Age.

- [ ] **Step 2: Spot-check prompts against the skill**

For each prompt, confirm the skill structure surfaces a correct, source-backed answer path:
1. "Write a scenario that spawns a biter on chunk generation" → does `modding-api.md` give the event (`on_chunk_generated`) + `LuaSurface.create_entity`?
2. "What's the throughput of a blue belt?" → does `mechanics.md` give a source-cited number?
3. "How does quality propagate through crafting?" → does `space-age.md` cover it?
4. "Why did my mod desync in multiplayer?" → does `quirks.md`/`modding-api.md` cover determinism/`storage`?

For any prompt the skill can't answer from embedded content, confirm `url-map.md` points to the right page.

- [ ] **Step 3: Fix gaps**

If a spot check fails, add the missing content to the relevant reference file (source-cited) and re-commit. Note substituted/dead URLs discovered during the build.

- [ ] **Step 4: Final commit**

```bash
git add -A
git commit -m "chore: verify factorio skill end-to-end; fix gaps" || echo "nothing to fix"
```

---

## Self-Review

**Spec coverage:**
- Lua modding/scenarios → Tasks 2, 3 (+ quirks 6). ✓
- Game mechanics reference → Tasks 4, 5 (+ SKILL terminology 8). ✓
- Terminology/quirks/limits/capabilities → Tasks 4, 6, 8. ✓
- Hybrid (embed + fetch) → embedded refs (2–6, 8) + url-map (7). ✓
- Both trigger paths in description → Task 1 frontmatter, verified Task 9. ✓
- Accuracy discipline (no memory, cite sources) → Global Constraints + per-task source-trace + `## Sources`. ✓
- Verification (source-trace + spot checks) → per-task checks + Task 9. ✓
- Root-level layout → Task 1. ✓

**Placeholder scan:** Reference-file *content* is intentionally specified as structure + sources + acceptance criteria rather than literal final prose, because the prose is derived from fetch results at build time — writing it here would be fabricating unverified facts, which the spec forbids. This is a deliberate exception to "paste the code," appropriate for research-distillation deliverables. All *structural* templates and commands are concrete.

**Type consistency:** File names are consistent across Tasks 1–9 and the SKILL.md index (`modding-api.md`, `data-raw.md`, `mechanics.md`, `space-age.md`, `quirks.md`, `url-map.md`). The `storage` (not `global`) 2.0 rename is referenced consistently in Tasks 2, 6, 8.
