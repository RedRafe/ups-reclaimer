# factorio-skill

A Claude Code agent skill giving Claude working knowledge of **Factorio 2.0 +
Space Age** — for Lua modding/scenarios and game-mechanics reasoning.

This repo is also a **Claude Code plugin marketplace**, so the skill can be
installed with one command.

## Install (as a plugin)

In Claude Code:

```
/plugin marketplace add lex/factorio-skill
/plugin install factorio@factorio-skill
```

The skill then activates automatically when you work on Factorio modding or ask
about game mechanics. To update later, re-run `/plugin marketplace add` and
`/plugin install`.

## Install (manual)

Alternatively, copy `skills/factorio/` (the `SKILL.md` plus its `references/`)
into your skills directory, e.g. `~/.claude/skills/factorio/`.

## Layout

```
.claude-plugin/
  plugin.json        # plugin manifest (name: factorio)
  marketplace.json   # marketplace manifest (name: factorio-skill)
skills/factorio/
  SKILL.md           # overview, terminology, quirks, when to fetch deeper
  references/        # distilled topic files + a topic→URL map for on-demand depth
```

All facts are distilled from wiki.factorio.com and lua-api.factorio.com and
cited in-file.
