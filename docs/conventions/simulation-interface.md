# The simulation's interface and its subsystems

## The simulation's interface

`DiveSimulation.new(layout)`, then: commands in, `advance(dt)`, state and events out.
The shape is in the class's header comment; copy it.

- **Commands** are one method per Station command (`set_power()`, `set_course()`, `shift()`, `pulse()` ...).
  They clamp, and take effect on the next step.
  A Station's command that needs the crew present checks `attended()` (as `override_course()` does); one that self-destruct takes off the crew starts with the one guard `if _off_the_crew(): return`.
- **State** is read-only query methods; no public vars.
  Values like `speed()` and `slip()` are recomputed each step, so read them after `advance`.
- **Events**: `take_events() -> Array[Dictionary]`, each `{type = &"...", ...fields}`.
  Raise one by appending to `_events`, and list it in `take_events()`'s doc comment, which is the catalogue.
  In the view, `habitat.gd` is the one consumer (each frame after `advance`); anything else that wants events gets them from the Habitat.
- **Time**: `advance(dt)` runs `dt * time_rate()` seconds, split into steps; per-step work lives in `_step(dt)`.
  A Station call returns the rate to 1 and drops the rest of that advance.
  `advance` does nothing while `surfaced()` or `dead()`.
  While `stranded()` it runs `_step_stranded(dt)` instead: nothing moves and the Head is dark, but a relight is tried, heat soaks into the hull (`Heat.soak()`) while Thermal's pumps cool it on the store, the link sends on the store, the hull may fail, and the rescue may arrive; anything else that runs with the Head dark goes there.
  Stranded, the time rate may be raised even though the Reactor calls.
- **Tuned constants** are private `const _NAME` with a comment citing ADR 0001.
  Tests never reference them; a test that needs a size reads it through a query (`stretch.length`, `minimum_turn_radius()`, `vessel_length()`).
- **Per-step cost**: per-step code must not scan the whole survey; a long dive has thousands of stretches.
- **No extraction**: a test fails any `DiveSimulation` method whose name contains extract, sample, cut, collect or remove (substrings, so `execute` fails too).
  The Bore Station observes and records; nothing leaves the Column.

### Frames and units

- Habitat frame = the Habitat node's axes: `TOWARD_HEAD` is -Z (Head end cap at z = -1.2), `TOWARD_UNDERSIDE` is -Y.
  `felt_acceleration()` is in this frame.
- World frame: origin at dive start, +Y up, so `depth() == -head_position().y`.
  Heading 0 is along -Z, 90 along +X.
  Pitch +90 is the Head straight down, -90 straight up.
- Path distance (`distance()`, metres along the path since the dive began) is what survey stretches, features and the Column are positioned in, not depth.
  The path is 3D; map a path distance to the world with `_depth_at_distance()` / `_medium_at_distance()`, which read the remembered path (`_remember_path()`).
- Power is one budget in the units of `set_power()`.

## Subsystems

Heat, the plasma and stranding each live in their own plain class in `sim/`, owned by `DiveSimulation` (`_heat`, `_plasma`, `_stranding`).
They are not seams: tests never build or read them, only `DiveSimulation`'s interface.
The rules:

- `DiveSimulation` keeps every command, query and event; a subsystem's state reaches the outside only through a `DiveSimulation` query that delegates to it.
  A new query is added to both.
- A subsystem knows nothing of the layout, the path, the Stations or the survey, and holds no reference back to the simulation (a new dive swaps it for a fresh one).
  Whatever it needs (depth, the Wobble, the surroundings' temperature, whether the Reactor's autopilot is engaged) is passed in on each call.
  Its tuned constants are its own `const _NAME`.
- Events a subsystem raises are appended to the `events` array the simulation passes it (`Plasma.tend()`), so `take_events()`'s catalogue still lists them all.
