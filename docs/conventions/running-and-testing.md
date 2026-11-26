# Running and testing

## Running

Tests: set `GODOT_BIN` to a Godot 4.7 binary (on Windows the `_console.exe` build), then `./test.sh` or `test.cmd`.
Exit 0 is a pass, 100 a test failure, 105 a script or parse error.

- The wrappers run an `--import` pass first.
  Without it a fresh checkout fails discovery with "Could not find type" for `class_name` classes.
- Every run prints `ERROR: Remote Debugger: Unable to connect to host '127.0.0.1:0'`.
  That is GdUnit4 disabling the debugger on purpose.
- A low test count means a failure: GdUnit stops a suite at its first failing test.

Scene smoke check: `"$GODOT_BIN" --headless --path . res://view/habitat.tscn --quit-after 120` (the Habitat on its own plays the First dive).
Success prints only `WARNING: 1 ObjectDB instance was leaked at exit` (a playing `AudioStreamGenerator`'s playback, engine behaviour).
Any script error is a real failure.
The same without the scene path runs the main scene, the start menu, which should print nothing.

Ad-hoc checks: a `SceneTree` script outside the repo, run with `-s <script>`, can load `res://` scenes.
Such runs go in real time (60 physics frames per simulated second).
A non-headless one can save `get_viewport().get_texture().get_image()` to PNG for a visual check.
To look into the Bore, add your own `Camera3D` and call `make_current()` a frame after adding it (the crew's camera claims current in its `_ready`); (2.6, 0, 0) looking at the origin sees between two Stations.
Hide `Overlay` for a clean shot.
Prefer headless checks when a window isn't needed.

## Testing

- Test through the simulation's interface only, and assert relationships ("deeper than", "further than"), never tuned values.
  Build test Media from test values (`DiveTestKit.rock()`, `.basalt()`) and test layouts with `MediumLayout.uniform()` / `.layered()`.
- Use `DiveTestKit` (static): `run(sim, seconds, step)`, `run_until(sim, type, seconds, seen, step, before)` (keeps every event of the step that raised the one wanted), `types(events)`.
  Add shared helpers there rather than copying them into suites.
- Read expected sequences from the layout (`MediumLayout.first_dive().boundary_depths()` and `medium_at()`), never a hand-written list of depths.
- Every autopilot starts off, so a setting holds with no help.
  Engage the autopilot of a Station the test wants to steady itself: the Reactor's for any dive that crosses a Boundary with nobody at the Reactor (`survey_test`, `stranding_test`, `repair_test`; left alone, the Residual outside the Band loses the plasma within minutes), Thermal's to keep the hull whole at full power (`steering_test`, `habitat_down_test`).
  Attend a Station only for a command that needs the crew there (the Drive's override, self-destruct's hold).
- The full-dive pattern is `full_trip_test.gd::_full_trip`: no autopilot engaged, the Drive set to steer gently and eased off whenever it slips, raise the time rate before each `advance(1.0)`, Shift onto the Wobble (`DiveTestKit.shift_to(sim, DiveTestKit.wobble(sim))`) when `out_of_band()`, plot pitch -90 past `TURN_AT_M`, and (by default) ease the Drive off while `heat_warning()`.
  Full power with all heat outward wears the hull through before the turn, so a trip that must surface either heeds the warning or cooks the Column.
  The careful and cooked trips are flown once per suite (`_careful_trip()`, `_cooked_trip()`); a test that goes on with the sim flies its own.
  Each trip takes a few seconds.
- Keep lambdas in tests on one line: a multi-line lambda as a call argument has broken GdUnit discovery.

## Gotchas

- Type inference (`:=`) from a missing class is a parse error: the run exits 105, not with a test failure.
- `runtest.*` refuses `--headless` without `--ignoreHeadlessMode`; the wrappers pass it.
