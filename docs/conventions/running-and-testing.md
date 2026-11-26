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

Ad-hoc checks: prefer a headless check when a window isn't needed.
For a look at the game, `tools/screenshot/shot.sh` takes one PNG of a Scenario run to a dive time; from Git Bash at the repo root, with `GODOT_BIN` set as for the tests:
`tools/screenshot/shot.sh --scenario "First dive" --look Reactor --time 120 --out /c/tmp/reactor-120.png`.
It prints the PNG's path and exits 0; on any failure it prints why, leaves no PNG at that path and exits 1.

- `--look` is a Station by the name on its screen (seen seated at it by the Arm, so that Station is attended), `bore` (into the Bore from the outer wall, Head end down), `column` (the Column as the crew see it turning round from the Bore Station, seated there) or `crew` (the crew's own view where the dive starts them).
- `--do "<seconds> <command> [arguments]"`, repeated, sends a `DiveSimulation` command at that dive time, in time order, then in the order given: `--do "0 set_power 1" --do "40 set_course 30 60"`.
  Any public method works, Scenario start and debug commands included (`"0 start_below 500"`, `"1 debug_skip 600"`); a debug command the simulation refuses fails the shot, but a crew command it ignores (an override with nobody at the Drive) does not.
- Times are `dive_time()`, so a skip or a raised time rate counts for what it ran; ten minutes at the normal rate take about half a minute to stage.
- `--out` defaults to `tools/screenshot/out/<scenario>-<look>-<time>.png`, which Godot (`.gdignore`) and git both ignore; `--overlay` keeps the centre notice; `--size 1920x1080` for a larger picture; `--help` lists the rest.
- The same arguments give the same PNG, byte for byte: the Habitat is stepped by hand in the game's own 1/60 s steps (`ShotPlan.stage()`, `tools/screenshot/shot_plan.gd`), then drawn for a fixed 8 frames at a fixed frame time.
  So a view that animates off its own clock (`_process(delta)`: a display's sweep, sparks, a call light's fade) is always 8 frames old in a shot; drive it from `dive_time()` if a shot must show it moving.
- It is safe to run several at once, in one checkout or in several worktrees; each opens a silent window centred on the developer's second monitor (`SHOT_MONITOR` names another).
- A staged Habitat is tested headless through `ShotPlan` (`test/screenshot_test.gd`); the picture itself needs the window.

## Testing

- Test through the simulation's interface only, and assert relationships ("deeper than", "further than"), never tuned values.
  Build test Media from test values (`DiveTestKit.rock()`, `.basalt()`) and test layouts with `MediumLayout.uniform()` / `.layered()`.
- Use `DiveTestKit` (static): `run(sim, seconds, step)`, `run_until(sim, type, seconds, seen, step, before)` (keeps every event of the step that raised the one wanted), `types(events)`.
  Add shared helpers there rather than copying them into suites.
- Read expected sequences from the layout (`MediumLayout.first_dive().boundary_depths()` and `medium_at()`), never a hand-written list of depths.
- Every autopilot starts off, so a setting holds with no help.
  Engage the autopilot of a Station the test wants to steady itself: the Reactor's for a Shift nobody makes (`shift_test`, `stranding_test`, `repair_test`), Thermal's to keep the hull whole at full power (`steering_test`, `habitat_down_test`).
  Attend a Station only for a command that needs the crew there (the Drive's override, self-destruct's hold).
- The full-dive pattern is `full_trip_test.gd::_full_trip`: no autopilot engaged, the Drive set to steer gently and eased off whenever it slips, raise the time rate before each `advance(1.0)`, Shift on `plasma_frequency()` when `shift_due()`, plot pitch -90 past `TURN_AT_M`, and (by default) ease the Drive off while `heat_warning()`.
  Full power with all heat outward wears the hull through before the turn, so a trip that must surface either heeds the warning or cooks the Column.
  The careful and cooked trips are flown once per suite (`_careful_trip()`, `_cooked_trip()`); a test that goes on with the sim flies its own.
  Each trip takes a few seconds.
- Keep lambdas in tests on one line: a multi-line lambda as a call argument has broken GdUnit discovery.

## Gotchas

- Type inference (`:=`) from a missing class is a parse error: the run exits 105, not with a test failure.
- `runtest.*` refuses `--headless` without `--ignoreHeadlessMode`; the wrappers pass it.
