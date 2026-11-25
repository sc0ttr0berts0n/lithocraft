# Conventions

How the code is put together and the rules for changing it. Read before changing `sim/`, `view/` or `test/`. Each public method's meaning is in its doc comment; this file holds what the code does not say.

## Layout

- `sim/`: the simulation. Every class is `RefCounted` with a `class_name`; nothing here touches the scene tree, `Input` or rendering. `DiveSimulation` is the one seam; `Medium`, `MediumLayout`, `SurveyStretch`, `ColumnFeature` and `ScanPoint` are data it reads or hands out.
- `view/`: scenes and view logic. `view/habitat.tscn` is the main scene. `Arm` (`view/arm.gd`) is view logic as a plain `RefCounted`, tested directly with plain transforms.
- `test/`: GdUnit4 suites, `*_test.gd`, `extends GdUnitTestSuite`, `func test_...`. Shared helpers in `test/support/dive_test_kit.gd`.
- Commit the `*.gd.uid` files Godot generates beside each script.
- Files are LF. On Windows, write files from Python with `newline=''`, or they come back CRLF.

## Running

Tests: set `GODOT_BIN` to a Godot 4.7 binary (on Windows the `_console.exe` build), then `./test.sh` or `test.cmd`. Exit 0 is a pass, 100 a test failure, 105 a script or parse error.

- The wrappers run an `--import` pass first. Without it a fresh checkout fails discovery with "Could not find type" for `class_name` classes.
- Every run prints `ERROR: Remote Debugger: Unable to connect to host '127.0.0.1:0'`. That is GdUnit4 disabling the debugger on purpose.
- A low test count means a failure: GdUnit stops a suite at its first failing test.

Scene smoke check: `"$GODOT_BIN" --headless --path . --quit-after 120`. Success prints only `WARNING: 1 ObjectDB instance was leaked at exit` (a playing `AudioStreamGenerator`'s playback, engine behaviour). Any script error is a real failure.

Ad-hoc checks: a `SceneTree` script outside the repo, run with `-s <script>`, can load `res://` scenes. Such runs go in real time (60 physics frames per simulated second). A non-headless one can save `get_viewport().get_texture().get_image()` to PNG for a visual check. To look into the Bore, add your own `Camera3D` and call `make_current()` a frame after adding it (the crew's camera claims current in its `_ready`); (2.6, 0, 0) looking at the origin sees between two Stations. Hide `Overlay` for a clean shot. Prefer headless checks when a window isn't needed.

## The simulation's interface

`DiveSimulation.new(layout)`, then: commands in, `advance(dt)`, state and events out. The shape is in the class's header comment; copy it.

- **Commands** are one method per Station command (`set_power()`, `set_course()`, `shift()`, `pulse()` ...). They clamp, and take effect on the next step. A Station's command that needs the crew present checks `attended()` (as `override_course()` does).
- **State** is read-only query methods; no public vars. Values like `speed()` and `slip()` are recomputed each step, so read them after `advance`.
- **Events**: `take_events() -> Array[Dictionary]`, each `{type = &"...", ...fields}`. Raise one by appending to `_events`, and list it in `take_events()`'s doc comment, which is the catalogue. In the view, `habitat.gd` is the one consumer (each frame after `advance`); anything else that wants events gets them from the Habitat.
- **Time**: `advance(dt)` runs `dt * time_rate()` seconds, split into steps; per-step work lives in `_step(dt)`. A Station call returns the rate to 1 and drops the rest of that advance. `advance` does nothing while `stranded()` or `surfaced()`.
- **Tuned constants** are private `const _NAME` with a comment citing ADR 0001. Tests never reference them; a test that needs a size reads it through a query (`stretch.length`, `minimum_turn_radius()`, `vessel_length()`).
- **Per-step cost**: per-step code must not scan the whole survey; a long dive has thousands of stretches.
- **No extraction**: a test fails any `DiveSimulation` method whose name contains extract, sample, cut, collect or remove (substrings, so `execute` fails too). The Bore Station observes and records; nothing leaves the Column.

### Frames and units

- Habitat frame = the Habitat node's axes: `TOWARD_HEAD` is -Z (Head end cap at z = -1.2), `TOWARD_UNDERSIDE` is -Y. `felt_acceleration()` is in this frame.
- World frame: origin at dive start, +Y up, so `depth() == -head_position().y`. Heading 0 is along -Z, 90 along +X. Pitch +90 is the Head straight down, -90 straight up.
- Path distance (`distance()`, metres along the path since the dive began) is what survey stretches, features and the Column are positioned in, not depth. The path is 3D; map a path distance to the world with `_depth_at_distance()` / `_medium_at_distance()`, which read the remembered path (`_remember_path()`).
- Power is one budget in the units of `set_power()`.

## Extension points

**A new power-drawing system.** Add its request in `_share_power()`, slotted into the shortfall order (Navigation, then Thermal, then the Drive: each gets all it asks while power lasts), and add its draw to `power_drawn()`. Heat follows, since `heat_produced()` is `power_drawn()` times a constant. Starvation is `<station>_supplied() < 1`; decide what a starved system does.

**Reactor output.** `reactor_output()` scales with `_plasma_stability`; anything that unsteadies the plasma lowers that, and it flows through the budget with no other change.

**Survey quality.** `_recording_quality()` is the one hook: today the shutter term (Quiet Ship) times `_unheated_share()` (heat into the Column). A new effect multiplies in another term there. Survey stretches and feature recording both read it, so nothing else changes.

**Recovery and new dives.** `recover()` and `new_dive()` share `_start_fresh()`, which resets every script variable to a fresh simulation's except `_KEPT_ON_RECOVERY`. A new per-dive variable needs nothing. A variable that must survive (what was paid, where the crew is) goes in that list; a test in `stranding_test.gd` checks the list against the script's variables. Station settings return to their start, so the view re-sends its own (`habitat.gd::_reset_settings`).

**A new Station call.** Add an `_offer_call(calls, station, reason, urgency)` in `_update_calls()`, with urgency from `_urgency(_<KIND>_CALL, share)` and a new `const _<KIND>_CALL := Vector2(begins, worst)` beside the others, never an inline number. A call that begins or changes reason raises `&"station_call"` and drops the time rate to 1.

**Unattended behaviour.** An unattended Station holds its setting and applies its steadying rule in `_steady_unattended()` (Drive backs power off to the grip limit while slipping; Thermal raises the heat split while the hull warns), or in its own system for the Reactor's late autopilot Shift and the Drive's capped steering effort. All Stations start unattended, so a test that wants a setting held must attend that Station (see Testing).

**Payment.** A stretch pays `SurveyStretch.value()` once all of it is up the link. Surfacing and a recovery through the open tunnel both sell what is aboard through `_sell_aboard()`. A fully recorded feature becomes a `SurveyStretch.feature_record()` on the link queue, not an entry in `survey()`. For "aboard" counts use `unsold_survey()` / `unsold_value()`, not `survey().size()` minus uploads: `uploaded_survey()` spans every dive. Heat and shuttering's cost is `pristine_value() - value()`.

**New minerals.** Add the mineral to `ColumnLook.MINERAL_COLOURS` (its look in the Bore) and to `SurveyStretch._MINERAL_WORTH` (its worth; defaults to 1).

## The view

- `habitat.gd` owns the `DiveSimulation`, sets each Station's attendance from `_at(station)`, calls `advance(delta)` in `_physics_process`, then takes events. Child views get the sim handed to them (`DiveView.attach(sim)`, or a public `sim` var on a `Control`).
- `_at(station)`: the crew member is seated there by the Arm, or within `STATION_REACH` of its pivot. Every Station key is gated by `_at` of its Station.
- Nothing is drawn over the crew's view (story 52). What the crew must know goes on a Station screen, into the Bore, or into shake and sound. The only screen-space text is the centre notice (`_show_notice(lines, seconds)`, 0 = until replaced), the F1 controls label and the F3 `DiveView` debug overlay (hidden by default; reads only, sends no commands). Keep Medium names off anything always on screen: the Medium is recognised by its look in the Bore.
- Station screens are `GimballedStation`: `show_reading(text)` for text, `show_display(texture)` for a `SubViewport` texture (the Bore, Reactor and Navigation screens do this), `set_supplied(share)` dims a starved screen, `set_call(urgency)` beats the Station's tone and flashes its light. Set `call_tone_hz` / `call_pips` before `_ready`.
- Anything drawn along the Column pins each piece to its path position (`distance() - behind_head`) so it scrolls at exactly `speed()`. Never integrate speed in the view. The Bore's Column uses its own tube mesh with explicit UVs, because `CylinderMesh` shares its texture with its caps.
- Controls that sit over the Habitat set `mouse_filter = 2` so clicks reach the mouse capture. An `HSlider` sets `focus_mode = 0` so arrow keys reach `_unhandled_input`.
- `head_wear()` (the Head, from poor Shifts) and `vessel_wear()` (the hull, from heat) are different things.

### Key map

Stand-in keys until the Stations get their own controls, all in `habitat.gd` except walking (`crew_member.gd`). Check here before binding a key, add yours, and update the F1 controls text in `habitat.tscn`.

| Where | Keys |
|---|---|
| Anywhere | WASD walk; mouse look (click captures, Esc releases); Space calls the Arm / lets go; A / D while held: next Station left / right |
| Anywhere | `.` time rate x4 (refused while any Station calls), `,` normal; Enter / keypad Enter: `recover()` then `new_dive()` (each ignored when not applicable); F1 controls; F3 debug overlay |
| Navigation | Plot the Course: 1 / 2 / 3 pitch dive / level / climb, Z / X pitch -/+15 deg, J / L heading -/+15 deg; P pulse; Q Quiet Ship |
| Drive | T / G power +/-10%; Y / H steering effort +/-10%; the Course keys override the Course from what the Drive steers toward now; O ends the override |
| Bore Station | F observe the next feature in the Column; U cycle upload priority |
| Thermal | C / V heat split outward / into the Column, 10% a press |
| Reactor | N / M Shift dial down / up 2%; R Shift |

## Testing

- Test through the simulation's interface only, and assert relationships ("deeper than", "further than"), never tuned values. Build test Media from test values (`DiveTestKit.rock()`, `.basalt()`) and test layouts with `MediumLayout.uniform()` / `.layered()`.
- Use `DiveTestKit` (static): `run(sim, seconds, step)`, `run_until(sim, type, seconds, seen, step, before)` (keeps every event of the step that raised the one wanted), `types(events)`. Add shared helpers there rather than copying them into suites.
- Read expected sequences from the layout (`MediumLayout.first_dive().boundary_depths()` and `medium_at()`), never a hand-written list of depths.
- Attend the Station whose setting the test holds: Thermal for a held outward split (`heat_test`, `survey_test`), the Drive for a slipping Drive held at full or for tight turns (`steering_test`, `habitat_down_test`). A stopped vessel cannot turn, so tests that change the Course also set power.
- The full-dive pattern is `full_trip_test.gd::_full_trip`: attend Reactor and Thermal, raise the time rate before each `advance(1.0)`, Shift on `plasma_frequency()` when `shift_due()`, plot pitch -90 past `TURN_AT_M`. It runs in under a second.
- Keep lambdas in tests on one line: a multi-line lambda as a call argument has broken GdUnit discovery.

## Gotchas

- Type inference (`:=`) from a missing class is a parse error: the run exits 105, not with a test failure.
- `runtest.*` refuses `--headless` without `--ignoreHeadlessMode`; the wrappers pass it.
