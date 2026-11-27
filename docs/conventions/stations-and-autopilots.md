# Station calls and autopilots

**A new Station call.**
Add an `_offer_call(calls, station, reason, urgency)` in `_update_calls()`, with urgency from `_urgency(_<KIND>_CALL, share)` and a new `const _<KIND>_CALL := Vector2(begins, worst)` beside the others, never an inline number.
A call that begins or changes reason raises `&"station_call"` and sounds (`call_sounding()`).
Every call is a warning (`call_warns()`) but those in `_REPORTS`, today only `&"feature_in_column"`: science never touches the time rate.
A warning that begins, changes reason or sounds again drops the time rate to 1, and `set_time_rate()` refuses a raised rate while any warning sounds; stranded or self-destructing, neither holds.
A new call that only reports goes in `_REPORTS`; anything that puts the vessel at risk stays a warning.

**The master acknowledge.**
`acknowledge_calls()` (/, anywhere) silences every call now sounding; it is no Station's command, so no autopilot lets go, and it works stranded and self-destructing alike.
An acknowledged call still shows (`call_urgency()`, `call_reason()`); it sounds again when its reason changes, when it has grown `_CALL_SOUNDS_AGAIN_RISE` more urgent since the acknowledge, or when it ends and comes back.
The view reads the three queries: a sounding warning beats its tone and flashes its light, a sounding report chimes once, and a call that shows but does not sound keeps its light lit, steady and silent (`GimballedStation.set_call()`); while any call sounds, every screen's footer names the key.

**The Boundary call waits for a ready crew.**
While STANDBY's predicted Residual is inside the Band (`residual(CHANNEL_STANDBY) <= band()`), the Reactor's `&"boundary_approaching"` waits until `boundary_countdown()` is within `_BOUNDARY_CALL_READY_S` (`_boundary_call_waits()`); untuned or unscanned (the Residual NAN) it comes when the Boundary is announced.
It reads the countdown and the guess through their queries, so a misleading scan holds the call back as it misleads both.

**Autopilots.**
Each Station's autopilot is a switch, A320 style: `set_autopilot(station, engaged)` (E at every Station), read with `autopilot(station)`.
The switch alone decides whether a Station steadies itself; attendance (`set_attended()`) matters only for commands that need the crew there (the Drive's nudges, self-destruct's hold), so a crew member can stand and watch an autopilot work.
Every autopilot starts off each dive (`_autopilot` is per dive).
Any Station command other than a reading (one that changes a setting, or acts as `shift()` and `relight()` do: the crew taking the controls) starts with `_disengage_on_command(STATION_...)` after its guards, which disengages its autopilot and raises `&"autopilot_off"` with `cause` `AUTOPILOT_OFF_BY_COMMAND` (the switch's own cause is `AUTOPILOT_OFF_BY_SWITCH`);
a reading (`pulse()`, `set_observed_feature()`) does not call it.
A new command calls it unless it only takes a reading.
Off, a Station holds its setting and does nothing more; its calls still come.
Engaged, its steadying rule runs in `_steady_autopilots()` (Drive backs power off to the grip limit while slipping; Thermal raises the heat split while the hull warns), or in its own place: the Reactor's slow tuning of ACTIVE toward the Wobble in `Plasma.tend()` (passed `autopilot(STATION_REACTOR) or _self_destructing`), the Drive's gentle steering cap in `_steer()`.
Engaging the Drive's sets its slow, safe power (`_AUTOPILOT_DRIVE_POWER`) and ends any override, so a plotted Course plus the Drive's autopilot gets the vessel moving.

**The Course and the Drive's nudges.**
The Course is Navigation's alone: `set_course()` is the only command that takes a heading or a pitch.
The Drive leaves it only by `nudge_pitch(direction)` / `nudge_heading(direction)`, each one step of `nudge_degrees()` from what the Drive steers for now (`steered_heading()`, `steered_pitch()`), only the sign of `direction` counting; `course_test.gd` fails a Drive command that takes degrees.
The first nudge begins the override (`overriding()`), which holds its own heading and pitch after the crew walks away, and ends on `end_override()`, on engaging the Drive's autopilot, or as soon as a nudge or a newly plotted Course brings the two together.
The deviation is `deviation_pitch()` (+ steeper down) and `deviation_heading()` (+ to the right, the short way round): what the Drive steers for less the Course, zero while it follows.
Heading means nothing straight up or down, so the heading deviation is zero while either what the Drive steers for or the Course points there (tilted off a Course straight down, the whole deviation is the pitch).
**The lean** (#91): while the Drive steers straight up or down (`steers_straight_up_or_down()`), a heading nudge turns the lean (`lean()`) and nothing else, and a pitch nudge off vertical tilts toward it; off vertical `lean()` is `steered_heading()`.
Every command that changes what the Drive steers for first snapshots `_lean = lean()`, so steered back to vertical the lean keeps the way it came, and a Course plotted off vertical (turned onto the short way, whatever the lean) leaves the lean at its heading.
A view that says how far off the Drive is reads these two, in `CourseDeviation`'s words, never its own subtraction.
A new Station's rule goes in `_steady_autopilots()` behind `autopilot(STATION_...)`.
A test that wants a Station to steady itself engages its autopilot (see Testing).

**The ring's slide.**
`station_ring()` is where the ring of Stations and the Arm's rail are along the Habitat, 0 by the Head end floor to 1 by the Tail end floor, and `ring_sliding()` whether it is on its way.
Both delegate to `RingSlide` (`sim/ring_slide.gd`, a subsystem owned as `_ring`), which is told only the share of the felt gravity along the Bore.
`RingSlide.step()` runs every step, stranded steps included (`_step()` calls it before anything else): the ring sets off once an end is the floor (the felt gravity points more toward it than toward the outer wall, `_END_IS_FLOOR`) and takes `_SLIDE_S`; near level it stays at, or finishes going to, the end it last set off for.
It is handed `pitch()`, not `felt_acceleration()`, so the Head's shudder cannot start a slide.
Nothing else in the simulation knows of the slide: Stations stay live through it, and a held command stops only because the view reports the Station unattended.
The slide is free; what it should cost and how it fails is in `docs/design/not-yet-designed.md`.
