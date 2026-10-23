# Circuits and Combinators (deep reference)

Detailed operator/mode specs for the circuit network and its four combinator
types, for Factorio 2.0 / Space Age. This is the deep companion to the
shallow circuit-network section in `mechanics.md`.

## Signals & wires

- **Red/green independence**: red and green wires form completely separate
  networks. "If red and green wires happen to touch the same power pole or
  device, the red and green networks will remain separate and will not link
  up. However, two red wires or two green wires will link if they touch."
  (Circuit_network)
- **Summing at receivers**: "Receiving devices sum all signals from each wire
  connected to them, even red and green wires." Example given: an inserter
  connected to a red wire carrying 20 copper plates and a green wire
  carrying 10 copper plates sees an input signal of 30 copper plates.
  (Circuit_network)
- **Summing within one color**: "Multiple wires of the same color will share
  & sum their signals." Example: three chests A, B, C wired in a row with
  green wire (A‑B‑C) output the sum of their contents on any green wire
  touching any of the three; a separate red wire from only chest A to a
  device would give that device only A's contents. (Circuit_network)
- **Wire networks are formed by direct connection**, device-to-device or via
  intervening power poles; wire length is limited by the previous
  connection segment. (Circuit_network)
- **Virtual signals**: signals that don't correspond to real items/fluids.
  "There are 177 virtual signals available (or 241 in Space Age) split
  between the Signals, Enemies, Environment, and Unsorted tabs" — numbers,
  letters, arrows, info icons, enemy variants, environment features, and a
  Nauvis planet signal. Other than the three logic signals below, virtual
  signals behave exactly like item signals. (Circuit_network)
- **The three logic/wildcard signals** — "Three of the virtual signals
  cannot be sent over a network but apply special logic to multiple
  signals":
  - **Everything**: usable on the left side of conditionals. "The condition
    will be true when the condition is true for each input signal. The
    condition is also true if there are no signals" — i.e. universal
    quantification (so `Everything ≠ 0` is always true). (Circuit_network)
  - **Anything**: usable on the left side of conditions. "It will be false
    when there are no inputs. The condition will be true when the condition
    is true for at least one signal" — existential quantification (so
    `Anything = 0` is always false). (Circuit_network)
  - **Each**: "can only be used in left input side and output of decider and
    arithmetic combinators... When used in both the input and output, it
    makes a combinator perform its action on each input signal
    individually. The combinator will output the sum of each of the actions
    if only used in the input." Each as an input is only evaluated over
    signals with a non-zero value. (Circuit_network)

## Wire reach (small electric pole only — confirmed)

Only the small electric pole's dedicated wiki page loaded; `/Wire`,
`/Power_pole`, and `/Electric_pole` were not fetched, so medium pole, big
pole, and substation reach are **unverified** here (do not state numbers for
those without checking their own pages).

Small electric pole, per quality tier (from the page's infobox, cross-checked
against the quality icon alt-text order Normal → Uncommon → Rare → Epic →
Legendary):

| Quality   | Wire reach (tiles) | Supply area |
|-----------|--------------------|-------------|
| Normal    | 7.5                | 5×5         |
| Uncommon  | 9.5                | 7×7         |
| Rare      | 11.5               | 9×9         |
| Epic      | 13.5               | 11×11       |
| Legendary | 17.5               | 15×15       |

(Small_electric_pole)

## Arithmetic combinator

Accepts two operands (each a signal or a constant), performs one operation,
and outputs the result. It "accepts two input connections (red and green
wires), and sends its output to both output connections." (Arithmetic_combinator)

### Operator list (exact, as printed on the page)

```
addition        ( + )
subtraction     ( − )
multiplication  ( * )
division        ( / )
modulo          ( % )
exponentiation  ( ^ )
bit shift left  ( << )
bit shift right ( >> )
bitwise AND     ( & )
bitwise OR      ( | )
bitwise XOR     ( ^ )
```

**`^` ambiguity — flagged, not resolved by the source**: the wiki's own
operator list literally prints *both* "exponentiation ( ^ )" and "bitwise
XOR ( ^ )" with the identical caret symbol; the page does not visually or
textually disambiguate them beyond the operator name. They are two distinct
selectable operations in the combinator's dropdown (confirmed by the
History entry: "Added Modulo, Power, Left Bit Shift, Right Bit Shift,
Bitwise AND, Bitwise OR and Bitwise XOR to the Arithmetic Combinator" —
version 0.15.0 — which lists Power and Bitwise XOR as separate additions),
but which on-screen glyph distinguishes bitwise XOR from `^`-exponentiation
is **unverified** from this page alone. Treat "bitwise XOR symbol = `^`" as
unconfirmed; treat "exponentiation symbol = `^`" and "AND = `&`" and
"OR = `|`" as confirmed (they're unambiguous, only XOR collides with
exponentiation).

### Division truncation (exact examples from the page)

"When using division, the result is truncated":

```
 21 /  10 =  2
 19 /  10 =  1
−21 /  10 = −2
−19 /  10 = −1
 21 / −10 = −2
 19 / −10 = −1
−21 / −10 =  2
−19 / −10 =  1
```

### Modulo notes

"Modulo, indicated using % as it is in most programming languages, is the
remainder after division. For example, 13 % 3 is 1 (13 = 4 * 3 + 1)."
Negating the left operand of a modulo negates the result; negating the right
operand does nothing:

```
 13 %  3 =  1
 13 % −3 =  1
−13 %  3 = −1
−13 % −3 = −1
```

### Bit shifts

"Bit shift right and Bit shift left deal with numbers in the binary
representation... The shift performed is called arithmetic shift, because it
preserves the sign bit on bit shift right."
- Shift left: a 0 is inserted at the LSB; the MSB bit is lost.
- Shift right, positive number (MSB=0): a 0 is inserted at the MSB; the LSB
  bit is lost.
- Shift right, negative number (MSB=1): a 1 is inserted at the MSB (keeps
  sign); the LSB bit is lost.

### Operand rules and the "each" wildcard (two output modes)

"The operands can be any single signal or a constant value. Up to one of the
operands can be the each virtual signal. For each signal operand, the input
wires can be selected. If both wires are selected, the inputs are summed."

- If neither operand is `each`: output must be a single specific signal; the
  op runs once on the chosen left/right values and the result goes to that
  signal.
- If one operand is `each`, two output modes are possible:
  - **Output = each (per-signal mode)**: "the operation is performed
    individually on the value of each input signal along with the value of
    the other operand, and each result is sent to the output on the same
    signal [it came in on]."
  - **Output = a single specific signal (summed mode)**: "the operation is
    done on each of the input signals, the individual results are all added
    together, and that result is sent to the output on the specified
    signal."

### Latency

"With both the arithmetic and decider combinator, there is one tick (60th
of a second) of latency before the output signal is ready to be used as an
input into a circuit network." (Decider_combinator, applies to both)

### Version history (from the page)

- **2.0.7**: UI overhaul; now displays input signals while configuring;
  signals used by combinators can be filtered between red, green, or both.
- **0.15.0**: added Modulo, Power (exponentiation), Left Bit Shift, Right
  Bit Shift, Bitwise AND, Bitwise OR, and Bitwise XOR.

## Decider combinator

"Used to make comparisons of signals on the network." Specifies a list of
conditions on the left of the GUI and a list of normal/else outputs on the
right; "Generally whenever the conditions are satisfied the normal outputs
are activated. When the conditions are not satisfied, the else outputs are
activated." (Decider_combinator)

### Comparators (exact list from the page)

```
>   <   =   >=   <=   !=
```

A condition is "a 'first' input signal, a comparison (>, <, =, >=, <=, !=),
and a 'second' input signal or constant." Input wires per side can be
selected; if both red and green are checked, the input values are summed.

### Multiple conditions — 2.0.7 rework

"If there are more than one conditions, a logical operator appears to the
left of every adjacent pair of conditions. Each of these operators can be
toggled between AND and OR with AND having higher order of precedence. An
AND condition will return true if all terms are true. An OR condition will
return true if at least one term is true." The version history entry for
this: **2.0.7** — "Multiple and/or operations can be performed in a single
decider combinator" (alongside the same UI overhaul as the arithmetic
combinator: input-signal display, red/green/both wire filtering).

### everything / anything / each semantics (exact table from the page)

| Output ↓ \ Input → | No `each` condition | `each` condition present |
|---|---|---|
| **Everything** | Evaluated on every signal that has a non-zero sum on the selected wires † | — (not applicable) |
| **Anything** | Evaluated on one signal that has a non-zero sum on the selected wires † | Evaluated on one signal that activates this output |
| **Each** | — (not applicable) | Evaluated on Each signal that activates this output |
| **Specific signal** | Evaluated on the specified signal | Evaluated on Each signal that activates this output, but the results are output on the specified signal instead |

† wires can be selected even if a constant value is specified.

"If an Each is present in any of the conditions, the decider combinator
evaluates the conditions for every input signal, resulting in each signal
activating either the normal or else outputs."

### Output modes

"Each output has the option to specify a constant value, or to take the
input count from specified wires. If both red and green are checked, the
input values are summed." **2.0.36**: "Decider combinator output constant
can be changed" (i.e. output-constant became independently editable per
output row, per the history entry — exact scope of this change beyond the
quoted line is unverified).

### Latency

Same one-tick output latency as the arithmetic combinator (see above).

## Constant combinator

"Constantly outputs the selected signal(s) to all connected wire networks
without the need for a specific input, and can be turned on/off in the GUI
manually." "Unlike the other three combinators, the constant combinator
does not require electricity to function." (Constant_combinator)

### 2.0.7 rework: logistic groups supersede the flat signal list

**Version 2.0.7** ("Constant combinators now use logistic groups for
configuration and output"): "Constant combinators can use named logistics
groups to group constants, which can be shared with other logistic
requesters. Logistic requests have two values for each signal: the minimum
and maximum for the entity. The constant combinator will only output the
minimum value. The UI for setting constants also cannot change the maximum
value, so new entries in a group will set the maximum value to infinity.
Modifying the constant for entries that have a maximum value set will not
alter that maximum value." (Constant_combinator, History section)

This explicitly supersedes an older model. The Circuit_network page still
describes that older behavior in its (apparently unrevised) body text: "The
constant combinator broadcasts up to 20 values on any of the channels...
Note that using two of the 20 slots to broadcast values on the same channel
is the same as broadcasting the sum of the two values from one slot." Treat
the "flat list of ~20 signal slots" description as the **pre-2.0.7 model**;
the current (2.0.7+, i.e. current 2.0/Space Age) model is the logistic-groups
system quoted above, where each entry carries a min/max pair but the combinator
only ever emits the minimum.

### Power / toggle recap

- Does **not** need electricity to operate.
- Can be manually turned on/off from its GUI ("can be turned on/off in the
  GUI manually").
- Recommended pattern if you need remote/automatic on-off switching: "channel
  its output through a decider combinator."

## Selector combinator

New combinator type, introduced in **2.0.7** per its own History section.
"Part of the circuit network... It has five different modes of operation
(or eight with Space Age enabled) to filter out various signals from an
input wire." (Selector_combinator)

### Modes (exact behavior per the page)

1. **Select input** — "the combinator sorts its input signals by value and
   outputs one of them at the same value."
   - *Sort descending* (default): signal with the highest value is selected.
   - *Sort ascending*: signal with the lowest non-zero value is selected.
   - *Index*: picks by sorted position, 0-based (first = 0, second = 1,
     third = 2...). If multiple signals are provided and the index is out
     of bounds, nothing is output; valid bounds are `0` through
     `(count of input signals) − 1`. If only a single input signal is
     provided, it is always passed through even if the index is out of
     bounds.
2. **Count inputs** — "will count and output the number of unique inputs on
   the selected signal." The value of the input signals is not considered.
3. **Random input** — "will pass through a random input signal every
   certain number of game ticks." Default update rate: every 1 tick (60
   times/second). If there's only one input signal, it's output once the
   tick threshold is met; if that input disappears before then, nothing is
   output.
4. **Stack size** — "will output the stack sizes of the input items." Does
   not output fluids or virtual signals; the value of the input items is
   not considered.
5. **Rocket capacity** — "will output the rocket capacity of the input
   signals." Excludes fluids, virtual signals, and items too heavy for a
   rocket (the page names the atomic bomb and the rocket silo item itself);
   input item values are not considered.
6. **Quality filter** *(Space Age)* — "will pass through any input signals
   that meet a conditional against a certain quality grade." Supported
   comparisons: greater than, less than, equal to, greater-or-equal,
   less-or-equal, not-equal, against one chosen quality grade. "If comparing
   against any quality grade, the only valid comparison is equal to."
7. **Quality transfer** *(Space Age)* — "will take the selected target
   signal from its inputs and output it with a particular quality grade."
   - *Direct selection*: attaches the specified quality grade to the target
     signal, but only if that target signal is present among the inputs.
   - *Select from input*: searches inputs for a chosen item and applies
     that found input's quality to the target signal, but only if both the
     selected input and the target signal are present among the inputs.
8. **Time** *(added 2.1.7)* — "will output three virtual signals: 'T', 'L'
   and 'D' based on certain game ticks":
   - **T**: counts up by 1 every tick, starting when the world is created.
   - **L**: outputs the number of game ticks in a day-length for the current
     planet (25,000 on Nauvis).
   - **D**: counts up by 1 every tick, resetting whenever it reaches the
     current value of L.

Note: the base-game count is 5 modes; Space Age adds Quality filter, Quality
transfer, and Time, for 8 total (Time itself shipped slightly later, in
2.1.7, per the page's own history — so on a strict 2.0/Space-Age-launch
build without later patches, only 7 modes may be present; treat the exact
version at which Time became available as the qualifier here).

## Sources

- https://wiki.factorio.com/Circuit_network
- https://wiki.factorio.com/Arithmetic_combinator
- https://wiki.factorio.com/Decider_combinator
- https://wiki.factorio.com/Constant_combinator
- https://wiki.factorio.com/Selector_combinator
- https://wiki.factorio.com/Small_electric_pole (wire reach/supply area only;
  medium electric pole, big electric pole, and substation reach were **not**
  fetched and are unverified — do not assume they scale the same way)
