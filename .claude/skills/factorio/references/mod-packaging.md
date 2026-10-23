# Mod Packaging (Factorio 2.0 / Space Age)

Covers `info.json`, `settings.lua`, localisation, and migrations — the
structural/metadata parts of a mod (as opposed to prototype or runtime
scripting APIs, which are covered elsewhere).

## info.json

Every mod's top-level folder (or zip) must contain an `info.json`. Example
from the Lua API docs:

```json
{
  "name": "better-armor",
  "version": "0.3.6",
  "title": "My better armor mod",
  "author": "A very great modder",
  "factorio_version": "2.0",
  "dependencies": ["? optional-mod"]
}
```

### Required fields

| Field | Notes |
|---|---|
| `name` | Internal name of the mod. Alphanumeric, dashes, underscores. Max 100 characters (mod portal restricts to 3–50). |
| `version` | Format `number.number.number` (e.g. `"0.6.4"`). Each segment ranges 0–65535. |
| `title` | Human-readable display name, max 100 characters. Overridable via locale. |
| `author` | The author of the mod. No format restrictions. |

### Optional fields

| Field | Notes |
|---|---|
| `contact` | How to reach the mod creator (email, etc.). |
| `homepage` | Where the mod is found online (website, forum, Discord). |
| `description` | Short description of what the mod does. Overridable via locale. |
| `factorio_version` | Format `number.number` (e.g. `"2.0"`). Major-version compatibility; effectively mandatory for modern releases. |
| `dependencies` | Array of dependency strings. Default: `["base"]`. |

### Feature-flag booleans (Space Age)

Per the Lua API mod-structure page, all default to `false`:

- `quality_required`
- `rail_bridges_required`
- `spoiling_required`
- `freezing_required`
- `segmented_units_required`
- `expansion_shaders_required`
- `expansion_required`
- `space_travel_required`

### Dependency string syntax

Format: `"<prefix> internal-mod-name <operator> <version>"`

Prefixes:

| Prefix | Meaning |
|---|---|
| (none) | Hard requirement |
| `!` | Incompatibility |
| `?` | Optional |
| `+` | Recommended (load-order only, mod not required) |
| `(?)` | Hidden optional |
| `~` | Doesn't affect load order |

Operators: `<`, `<=`, `=`, `>=`, `>`

Example: `"? some-other-mod >= 4.2.0"`

### Folder / zip naming

- Folder: `{mod-name}_{version-number}` or plain `{mod-name}`
- Zip file: `{mod-name}_{version-number}` (the interior folder name is unrestricted)

### Other files in the mod folder (from the Lua API mod-structure page)

- `settings.lua` — settings prototypes (see below)
- `data.lua` — prototype stage
- `control.lua` — runtime stage
- `changelog.txt` — version history shown in the mod browser; "must follow strict formatting requirements" (exact format documented on a separate Changelog Format page — **unverified** here, not fetched).
- `thumbnail.png` — shown on the mod portal / in-game mod browser; ideally 144x144px.

## settings.lua

Five setting prototype types:

| Type | Description |
|---|---|
| `bool-setting` | A true/false checkbox. Requires `default_value` (boolean); optional `forced_value`. |
| `int-setting` | A signed 64-bit integer textfield (or selection dropdown). Requires `default_value`; optional `minimum_value`, `maximum_value`, `allowed_values` (array). |
| `double-setting` | Floating-point equivalent of `int-setting`, same optional numeric constraints. |
| `string-setting` | A string textfield (or selection dropdown). Requires `default_value` (string); optional `allow_blank`, `auto_trim`, `allowed_values` (array of strings). |
| `color-setting` | A color picker (sliders) with whole-number textfields, includes alpha. Requires `default_value` of type Color. |

### setting_type scopes

| Scope | Behavior |
|---|---|
| `startup` | Available during the prototype (data) stage only; cannot be changed at runtime; must match across all multiplayer players. |
| `runtime-global` | Accessible during the control stage; changeable at runtime; on multiplayer, only server admins can modify. |
| `runtime-per-user` | Only available at runtime in the control.lua stage; each player has an independent value; synced per player preference. |

### Required / notable optional fields

Mandatory for every setting: `name` (string; recommended to prefix with the mod name), `type` (the prototype type above), `setting_type` (scope), `default_value` (type varies by setting type).

Notable optional fields: `order` (GUI sort order), `hidden` (hidden from players but still accessible to other mods), `minimum_value` / `maximum_value`, `allowed_values` (creates a dropdown), `forced_value` (hidden-only enforcement), `localised_name`, `localised_description`.

### Access syntax

```lua
-- Startup setting, in the data stage:
settings.startup["setting-name"].value

-- Runtime-global setting, in the control stage:
settings.global["setting-name"].value

-- Runtime-per-user setting, in the control stage:
settings.get_player_settings(player_index)["setting-name"].value
-- or
game.players[player_index].mod_settings["setting-name"].value
```

Settings can be modified by assigning a ModSetting table, e.g.
`settings.global["name"] = {value = new_value}`.

## Localisation

Locale files live at `__mod__/locale/<lang_code>/<filename>.cfg` (language
codes like `en`, `ru`, `de`, `fr`, etc.). Mods should always provide English
(`en`) as the fallback language.

Format is category + key/value pairs:

```
[category]
key=value
```

**Whitespace gotcha (verbatim):** "Any whitespace after or before `=` is
included in the key or string, so `title =Category related title` will give
an unknown key error if you are looking for the `title` key."

### Placeholders

- Positional parameters: `__1__`, `__2__`, etc., e.g. `time-left=Time left: __1__ minutes.`
- Built-in parameters: `__CONTROL__name__` (control key combos), `__ITEM__name__`, `__ENTITY__name__`, `__FLUID__name__` (prototype names), `__CONTROL_MOVE__` (movement keys).
- Plurals: `__plural_for_parameter__1__{1=day|rest=days}__` handles singular/plural forms.
- Concatenation: use an empty-string key, `{"", ...}`, to concatenate localised strings.

### LocalisedString array syntax

```lua
{"category.key", param1, param2}
game.print({"item-name.iron-plate"})
```

### Parameter-must-be-a-string gotcha

At the prototype data stage, all parameters passed into a LocalisedString
must be strings — passing a number directly produces a "Value must be a
string" error. Convert with `tostring()`:

```lua
-- Wrong:
localised_description = {"description.example", 42}
-- Correct:
localised_description = {"description.example", "42"}
```

## Migrations

Migration files are `.lua` or `.json` files placed in the mod's
`"migrations"` folder.

- **JSON migrations**: allow changing one prototype into another (renaming,
  type changes). They are "applied as a map is being loaded. Multiple such
  migrations can be applied at once."
- **Lua migrations**: modify game state via the `game` object. Note: "The
  game resets recipes and technologies any time mods, prototypes, or startup
  settings change, so this does not need to be done by migration scripts
  anymore."

### Ordering

- "All JSON migrations are applied before any Lua migrations."
- "The sequence in which migrations are executed is sorted by mod order
  first, migration file name second (using lexicographical comparison)."
- No numeric filename template is specified on the page — do not assume one
  (e.g. do not assume a required `0.0.1.lua`-style prefix format beyond
  ordinary lexicographic sort).

### Save tracking

"Each save file remembers (by name) which migrations from which mods have
been applied and will not apply the same migration twice."

### Adding a mod to an existing save

When a mod is added to an existing save, "all migration scripts for that mod
will be run."

**Unverified**: the claim that migrations specifically do not run when a
client joins an already-running multiplayer session was not found on the
fetched Lua API migrations page — it makes no statement about that scenario
either way. Treat this as unconfirmed.

### Entity behavior across migrations

When entity names change via migration, "the entity retains its previous
`unit_number` and any references to the entity saved in storage stay valid."
When entity *type* changes, this results in a "new `unit_number` and an
invalid entity reference."

## Sources

- https://lua-api.factorio.com/latest/auxiliary/mod-structure.html (info.json fields, dependency syntax, feature-flag booleans, folder/zip naming, sample info.json, changelog.txt/thumbnail.png/settings.lua/data.lua/control.lua listing)
- https://wiki.factorio.com/Tutorial:Mod_structure (redirect/deprecation notice only; no content — confirms the wiki page has moved to the lua-api page above)
- https://wiki.factorio.com/Tutorial:Mod_settings (setting prototype types, setting_type scopes, required/optional fields, access syntax)
- https://wiki.factorio.com/Tutorial:Localisation (locale file path, .cfg format, whitespace gotcha, placeholders, LocalisedString syntax, string-parameter gotcha)
- https://lua-api.factorio.com/latest/auxiliary/migrations.html (migrations folder, .lua vs .json, ordering rules, save tracking, mod-added-to-save behavior, entity unit_number behavior)
