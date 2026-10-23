# UPS Reclaimer (Factorio 2.1)

Copy the `ups-reclaimer` folder into `%APPDATA%\Factorio\mods`.

## Use
1. Click the **UPS reclaimer** shortcut. Drag to add entities (blue overlay), shift-drag to remove them.
2. Run the factory first, so every belt and pipe crossing the selection border carries its items or fluid.
3. The panel lists each replaceable entity in the selection with its count, like the blueprint window. Click an entity to keep it real; it turns red. Click it again to replace it.
   Below, the panel previews the border inputs and outputs at their steady-state rates. Click one to switch it off (red): it crosses at 0, so what makes it inside slows down and uses less of its own inputs (for an input, what uses it starves). The other rates update at once. An output at 0 is left out of the reclaimed block: its belt's loader doesn't take it and it never reaches the output chest. An item that also has a surplus on another output belt keeps leaving there, so switch that one off too if the inputs should drop. While the reclaim is blocked (a splitter on the border, an empty belt...), the panel lists why instead.
4. Click **Reclaim**. If something blocks the reclaim, a chat message gives the reason and a map link.
5. To restore a reclaimed subfactory, right-drag over it.

## What reclaiming does
- These entities become `simple-entity-with-owner` copies named "Reclaimed …" that show a still frame of the original graphics, at no UPS cost (an inserter's arm reaches for its pickup): assemblers (including the Space Age machines), furnaces, beacons, inserters, belts, underground belts, splitters, pipes, underground pipes, pumps, storage tanks and combinators.
- In alt mode, reclaimed machines and beacons show their recipe and module icons, like vanilla. The icons are attached to the copy, so they disappear with it.
- Each belt crossing the border becomes a linked belt. It connects to a hidden lab surface with a loader and a buffer chest; each block's columns there sit on a concrete patch. Each input belt has its own chest, an infinity chest that keeps the items the belt was seen carrying and deletes anything else, so a stray item never jams the belt. All output chests of a block share one inventory (copies of the base linked chest with huge stacks, one slot per item). Each item's stock is kept to the "Border buffer" map setting, 10 seconds of flow by default (2 to 60); changing it applies to reclaimed blocks at once. A single-item input belt's loader is wired to its chest with the condition "item < target", so the engine switches it every tick at no script cost; an oversupplied belt just backs up like a real one. A mixed input belt's loader goes through a powerless decider that ANDs one such condition per item. The script never switches a loader. What a belt carries is read once, at reclaim, from the border tile and up to 100 belt pieces upstream of it (outside for an input, inside for an output). An output belt also gets the products of the machines whose inserters drop onto it, so each output belt ships what is made for it even when it is still empty. An output belt with two items that each fit one lane gets one loader per item, side-loading from both sides, so each item keeps its own lane.
- Each pipe crossing the border becomes a port: a real pipe, drawn straight, that stays part of the outside pipe network. The script takes and adds fluid directly on that network. Whether a fluid goes in or out follows from the block's balance.
- Rates come from the selected machines: recipe and its quality, crafting speed, productivity (capped like vanilla), the quality spread from quality modules (up to the last quality you unlocked), and the fuel burned by burner machines. Each item quality is its own flow, and one belt may carry up to 5 item/quality kinds. At reclaim the block is settled at the steady state it would really reach: a recipe short on an internal intermediate, or backed up because nothing uses its output, is slowed down, and the chat says which and why.
- At the steady state a step only reads the border, moves each flow at its cached rate and draws the cached power: the cost doesn't depend on how many machines are inside. Machines with the same recipe and quality share one row, with their rates and power summed at reclaim time. Only when an input runs short or an output backs up does the step solve the rows, and only for that step.
- Once per second each recipe in the block runs as far as its own inputs, its own outputs and the power allow. A starved input or a backed-up output only slows the recipes that touch it: independent lines in one block never wait on each other, and a short input shared by two lines goes to the one that can still deliver. 90% input supply gives 90% output. A stalled block is checked less and less often, down to once every 10 seconds.
- Any number of belts and pipes may cross the border. Each belt gets its own loader, switched on its own, so belts never stop each other. The shared output chest holds up to 100 item/quality kinds per block; each belt carries up to 5 kinds.
- Power follows the vanilla model: idle power (every drain, plus beacons, which run all the time) is always drawn, even when the block is stalled. Each recipe adds its active power times how busy it is. Active power is the machine's energy usage including the consumption effect of its modules and beacons, so speed, productivity and efficiency modules count; a machine without a recipe only drains. Inserters and pumps add their max power times the average busyness of the recipes. A hidden electric energy interface draws all of it: the engine bills the idle part every tick, the script the active part each step ran. Brownouts slow the block.

Entities you keep real stay in place. Belts crossing the border are always replaced. Machines you keep real are left out of the rate and power calculation.

## Known limits (first draft)
- Only belt, underground belt, pipe and underground pipe tiles can cross the border, not splitters or other fluid entities. An underground belt with one end on each side makes its outside end the border tile; it turns into a linked belt drawn as an underground belt and comes back on restore. An underground pipe on the border keeps its link to the outside end. A machine connected straight to an outside pipe blocks the reclaim; include a pipe tile between them.
- A mixed input belt jams when one of its items piles up (arrives faster than the block uses it), like a real mixed belt, only before the belt itself fills up. That only affects that one belt.
- A port network must hold one second of flow: border fluid rates above about 10000/s per pipe network get capped (`PORT_VOLUME` in `prototypes/border.lua`). Fluid temperature is not checked on inputs.
- Inserters and pumps are billed at max power while working; their real average is lower.
- Items and fluids inside entities are lost when you reclaim, and items in a block's border buffer are lost when you restore. Restoring brings back recipes, modules, direction, quality and underground in/out. It does not restore circuit wires, combinator settings, inserter filters or splitter priorities.
- Not replaced, compared with what RateCalculator and Factory Planner model:
  - rocket silos: what they make is a launch, which a reclaimed silo can't do; it would eat rocket parts for nothing. Keep the silo outside and feed it by belt from the block.
  - labs: research progress would need scripting per technology, and labs are cheap to run anyway.
  - mining drills and agricultural towers: their output comes from depleting ore patches or growing plants, which a reclaimed block can't track.
  - boilers, generators, reactors and offshore pumps: power and heat follow demand, not a fixed rate.
  - loaders, lamps, chests and electric poles. Poles must stay so the power draw has a network to connect to.
- Machines powered by fluid or heat (some mods) are billed no power.
- Not tested in game. Blocks reclaimed with an older version must be restored before updating. Graphics calibration knobs are marked `ponytail:` in `prototypes/` and `scripts/`.

## Code layout
- `constants.lua`: names and limits shared by the data and the control stage.
- `data-final-fixes.lua` loads `prototypes/`: `look-alikes.lua` (static twins, built from `sprites.lua`), `border.lua` (linked belt, loader, ports, decider, buffers, power interface) and `tool.lua`.
- `control.lua` registers the `scripts/` modules with the core `event_handler`:
  - `selection.lua`: the selection and the panel.
  - `freeze.lua`: reclaim and restore.
  - `rates.lua`: full-load rates and flow keys.
  - `solver.lua`: steady state and the runtime throttle.
  - `border.lua`: belt and pipe connections.
  - `look-alike.lua`: variations, icons and snapshots.
  - `runtime.lua`: the batched step and the timer wheel.
- `tests/solver_test.lua` checks the solver in plain Lua 5.2+: run `lua tests/solver_test.lua` from the mod folder.
- Format with [StyLua](https://github.com/JohnnyMorganz/StyLua) (`stylua .`, settings in `.stylua.toml`).
