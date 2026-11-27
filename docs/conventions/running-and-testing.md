# Running and testing

## What runs when

Plan tests, screenshots and long-running processes as the work goes, but run the slow ones near review, not on every round.

- While iterating: the one test being written, and the suites for the code being changed (`./test.sh heat scan`).
- Once, at hand-back or before the push: the whole suite (`./test.sh`), the docs check (`python tools/docs/check_docs.py`), the lint (when ticket #79 has given it a command), and the ticket's screenshots.
- At the push: CI repeats it, so do not rerun a green whole suite to be sure.
  CI runs the whole suite and the scene smoke checks today; the lint and the docs check join it with ticket #87.
- An orchestrator merging several tickets runs the whole suite once per merge that had conflicts and once before review, and puts this policy in each agent's brief.
- An orchestrator names a model for every agent it starts: a ticket's implementer runs on Opus, a docs-only or mechanical ticket on a smaller model, and the largest model is kept for work that is mostly hard reasoning, which a ticket rarely is (the developer's rule, 27 November 2026).

## Running

Tests: set `GODOT_BIN` to a Godot 4.7 binary (on Windows the `_console.exe` build), then `./test.sh` or `test.cmd`.
Exit 0 is a pass, 100 a test failure, 105 a script or parse error.

- While iterating, run only the suites for the code being changed: `./test.sh heat scan` runs `test/heat_test.gd` and `test/scan_test.gd` in seconds (`heat`, `heat_test`, `heat_test.gd` and `test/heat_test.gd` all name the same suite).
  With no suite named, every suite runs, which takes minutes.
- A run ends with one plain line, `PASSED: 8 test cases, 0 errors, 0 failures, ... (exit 0)`.
  A failing run first prints `FAILED <suite> > <test>` with what was expected and the line, for each failing test; a script or parse error prints the engine's error lines.
  The run's full output is in `reports/last_run.log`; `--verbose` prints it as it comes instead, colours and all.
- `test.cmd` hands its arguments to `test.sh` through the bash of Git for Windows, so there is one script to change: `test.sh`.
- The wrappers run an `--import` pass first.
  Without it a fresh checkout fails discovery with "Could not find type" for `class_name` classes.
- Every verbose run (and every `last_run.log`) has `ERROR: Remote Debugger: Unable to connect to host '127.0.0.1:0'`.
  That is GdUnit4 disabling the debugger on purpose.
- A low test count means a failure: GdUnit stops a suite at its first failing test.

Scene smoke check: `"$GODOT_BIN" --headless --path . res://view/habitat.tscn --quit-after 120` (the Habitat on its own plays the First dive).
Success prints nothing after the engine's version line.
Any script error is a real failure.
The same without the scene path runs the main scene, the start menu, which should print nothing.
`tools/ci/smoke.sh [scene]` runs either one and exits 1 if Godot exits non-zero or prints an error; Godot itself exits 0 after a script or parse error, so the exit code alone proves nothing.
A warning, such as leaked ObjectDB instances at exit, passes.

CI: `.github/workflows/ci.yml` runs on every push to `dev` and every pull request into `dev`.
It fetches the Linux Godot binary named by its `GODOT_VERSION` (cached between runs), then runs `./test.sh`, then `tools/ci/smoke.sh res://view/habitat.tscn`, then `tools/ci/smoke.sh` for the main scene; the first failure turns the job red.
A pull request merges into `dev` only on a green job.

Cost budget: `tools/cost/cost.sh`, no part of `./test.sh`; see `cost-budget.md`.

Ad-hoc checks: prefer a headless check when a window isn't needed.
For a look at the game, `tools/screenshot/shot.sh` takes one PNG of a Scenario run to a dive time; from Git Bash at the repo root, with `GODOT_BIN` set as for the tests:
`tools/screenshot/shot.sh --scenario "First dive" --look Reactor --time 120 --out /c/tmp/reactor-120.png`.
It prints the PNG's path and exits 0; on any failure it prints why, leaves no PNG at that path and exits 1.

- `--look` is a Station by the name on its screen (seen seated at it by the Arm, so that Station is attended), `bore` (into the Bore from the outer wall, level with the ring of Stations, Head end down), `column` (the Column as the crew see it turning round from the Bore Station, seated there) or `crew` (the crew's own view where the dive starts them).
- `--do "<seconds> <command> [arguments]"`, repeated, sends a `DiveSimulation` command at that dive time, in time order, then in the order given: `--do "0 set_power 1" --do "40 set_course 30 60"`.
  Any public method works, Scenario start and debug commands included (`"0 start_below 500"`, `"1 debug_skip 600"`, and `"0 debug_next_scan_view"`, once or twice, for Navigation's second or third candidate scan view); a debug command the simulation refuses fails the shot, but a crew command it ignores (a nudge with nobody at the Drive) does not.
  To work one Station while looking at another, attend it in the same moment, before its command: `--look Navigation --do "40 set_attended drive true" --do "40 nudge_pitch -1"` (the Habitat sets attendance back at its next step, after the command has acted).
- Times are `dive_time()`, so a skip or a raised time rate counts for what it ran; ten minutes at the normal rate take about half a minute to stage.
- `--out` defaults to `tools/screenshot/out/<scenario>-<look>-<time>.png`, which Godot (`.gdignore`) and git both ignore; `--overlay` keeps the centre notice; `--size 1920x1080` for a larger picture; `--help` lists the rest.
- A climb is a long way into a dive at the game's own steps; skip to it: `--do "0 start_below 800" --do "0 set_power 1" --do "0 set_steering_effort 1" --do "0 set_autopilot thermal true" --do "0 set_autopilot reactor true" --do "0 set_course 0 -90" --do "1 debug_skip 2400"` has the ring of Stations start its slide to the Tail end near dive time 2498 s.
- `--tilt <degrees>` and `--turn <degrees>` turn any look from what it names, the eyes staying put: up (down if negative) and to the right (left if negative).
  `--look crew --tilt 55` looks up the Habitat's height from the floor; `--look Drive --turn 180 --tilt 30` looks back across the room from the Arm's hold.
- The same arguments give the same PNG, byte for byte: the Habitat is stepped by hand in the game's own 1/60 s steps (`ShotPlan.stage()`, `tools/screenshot/shot_plan.gd`), then drawn for a fixed 8 frames at a fixed frame time.
  So a view that animates off its own clock (`_process(delta)`: a display's sweep, sparks, a call light's fade) is always 8 frames old in a shot; drive it from `dive_time()` if a shot must show it moving.
- For more than one look, take a sheet: `tools/screenshot/shot.sh --sheet <list file>` takes every shot of a list in one Godot start (about 5 s a shot) and tiles them into one PNG, each tile under a label with its name and arguments, so one image read shows them all.
  The list is plain text, a shot to a line, `<name>: <arguments>`, the arguments those of one shot without `--out` or `--size`, quoted as on a command line; blank lines and lines starting with `#` are skipped, and the tiles go in the order of the lines:
  `lit: --look Reactor --time 120 --do "0 set_power 1"`.
  `--out` defaults to `tools/screenshot/out/<list>-sheet.png`, and `--size` is the size every shot is taken at.
  A tile is its shot scaled down to 768 pixels wide, two to a row, at which the text on a Station's screen still reads; `--tile <width>` and `--columns <count>` change that (`--tile 1152` for no scaling).
  A shot that fails, in the list or in its staging, fails the sheet: the reason names the shot, the exit is 1 and no PNG is left at that path.
  The same list gives the same sheet, byte for byte; each shot gets a fresh Habitat and the same seed as a shot alone (`ShotSheet`, `tools/screenshot/shot_sheet.gd`).
- The evidence for a screen is its recipe, a list kept in `tools/screenshot/recipes/`, one per Station screen and per view a ticket checked by eye: `reactor.txt`, `thermal.txt`, `drive.txt`, `navigation.txt`, `stations.txt` (every Station from the Arm's hold), `habitat.txt` (the room, and the ring at each end and mid-slide) and `column.txt` (features in the Column).
  `tools/screenshot/shot.sh --sheet tools/screenshot/recipes/reactor.txt` makes its sheet, `tools/screenshot/out/reactor-sheet.png`; each takes under a minute, and no sheet is ever committed.
  A ticket that changes a screen or a view adds the states it makes to that recipe, or corrects the tiles it changes, and a new screen gets a new recipe; the reviewer regenerates the sheet and reads it (`review.md`).
  A tile's name says the state it shows, and a comment line over it says what to look for and how the state is reached.
  Stage a state with crew and Scenario start commands, and check it headless before the sheet is read (`ShotPlan.stage()` on a Habitat, then the simulation's queries); a `debug_*` command only where the state is otherwise far away, named in the recipe's header.
  `shot_recipes_test.gd` fails a recipe that no longer makes a sheet (a renamed command, Station or Scenario); what a tile shows is the reader's to check.
- It is safe to run several at once, in one checkout or in several worktrees; each opens a silent window centred on the developer's second monitor (`SHOT_MONITOR` names another).
- A staged Habitat is tested headless through `ShotPlan`, and a list and its layout through `ShotSheet` (`test/screenshot_test.gd`); the picture itself needs the window.

## Testing

- Test through the simulation's interface only, and assert relationships ("deeper than", "further than"), never tuned values.
  Build test Media from test values (`DiveTestKit.rock()`, `.basalt()`) and test layouts with `MediumLayout.uniform()` / `.layered()`.
- Use `DiveTestKit` (static): `run(sim, seconds, step)`, `run_until(sim, type, seconds, seen, step, before)` (keeps every event of the step that raised the one wanted), `types(events)`.
  Add shared helpers there rather than copying them into suites.
  Test Media there too: `rock()`, `basalt()`, and `soft()` over `hard()` for a layout with one clear Boundary; `heating(power, to_column)` is a dive for tests of the hull's heat.
- A Habitat-level test starts from `DiveTestKit.staged_habitat(self, scenario)`: in the tree, freed with the test, stepped only by `habitat._physics_process(step)`.
  `station(habitat, name)` / `stations(habitat)` find its Stations, `await DiveTestKit.laid_out(self)` waits for a screen's Containers before its readings are read, and `staged_shot(self, arguments)` stages one as the screenshot tool does.
- No test of the game calls a `debug_*` command (see `debug-commands.md`): wear the Head with `wear_head_gently()`, lose the plasma with `lose_plasma()`, strand with `strand()`, and end a dive by losing the plasma with the tunnel open (brought home) or by flying it.
- Convention checks that read the source live in `test/convention_test.gd`, their allow-lists and reasons with them: fix the code before adding an entry.
- Read expected sequences from the layout (`MediumLayout.first_dive().boundary_depths()` and `medium_at()`), never a hand-written list of depths.
- Every autopilot starts off, so a setting holds with no help.
  Engage the autopilot of a Station the test wants to steady itself: the Reactor's for any dive that crosses a Boundary with nobody at the Reactor (`survey_test`, `stranding_test`, `repair_test`; left alone, the Residual outside the Band loses the plasma within minutes), Thermal's to keep the hull whole at full power (`steering_test`, `habitat_down_test`).
  Attend a Station only for a command that needs the crew there (the Drive's nudges, self-destruct's hold).
  `DiveTestKit.nudge(sim, heading_degrees, pitch_degrees)` nudges an attended Drive that far off where it steers.
- The full-dive pattern is `full_trip_test.gd::_full_trip`: no autopilot engaged, the Drive set to steer gently and eased off whenever it slips, raise the time rate before each `advance(1.0)`, Shift onto the Wobble (`DiveTestKit.shift_to(sim, DiveTestKit.wobble(sim))`) when `out_of_band()`, plot pitch -90 past `TURN_AT_M`, and (by default) ease the Drive off while `heat_warning()`.
  Full power with all heat outward wears the hull through before the turn, so a trip that must surface either heeds the warning or cooks the Column.
  The careful and cooked trips are flown once per suite (`_careful_trip()`, `_cooked_trip()`); a test that goes on with the sim flies its own.
  Each trip takes a few seconds.
- Keep lambdas in tests on one line: a multi-line lambda as a call argument has broken GdUnit discovery.

## Gotchas

- A playing `AudioStreamGenerator` freed with no sound device can crash the engine a little later (exit 139, a segmentation fault, most often in `screenshot_test`, which has three Habitats alive at once).
  `SlipSound` therefore plays nothing when the audio driver is `Dummy` (headless); a new generated, looping sound does the same.
- Type inference (`:=`) from a missing class is a parse error: the run exits 105, not with a test failure.
- `runtest.*` refuses `--headless` without `--ignoreHeadlessMode`; the wrappers pass it.
