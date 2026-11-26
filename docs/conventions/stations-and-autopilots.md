# Station calls and autopilots

**A new Station call.**
Add an `_offer_call(calls, station, reason, urgency)` in `_update_calls()`, with urgency from `_urgency(_<KIND>_CALL, share)` and a new `const _<KIND>_CALL := Vector2(begins, worst)` beside the others, never an inline number.
A call that begins or changes reason raises `&"station_call"` and drops the time rate to 1.

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
Heading means nothing straight up or down, so there the heading deviation is zero and a heading nudge turns nothing.
A view that says how far off the Drive is reads these two, in `CourseDeviation`'s words, never its own subtraction.
A new Station's rule goes in `_steady_autopilots()` behind `autopilot(STATION_...)`.
A test that wants a Station to steady itself engages its autopilot (see Testing).

**The ring's slide.**
`station_ring()` is where the ring of Stations and the Arm's rail are along the Habitat, 0 by the Head end floor to 1 by the Tail end floor, and `ring_sliding()` whether it is on its way.
`_slide_ring()` runs every step, stranded steps included: the ring sets off once an end is the floor (the felt gravity points more toward it than toward the outer wall, `_END_IS_FLOOR`) and takes `_RING_SLIDE_S`; near level it stays at, or finishes going to, the end it last set off for.
It reads `pitch()`, not `felt_acceleration()`, so the Head's shudder cannot start a slide.
Nothing else in the simulation knows of the slide: Stations stay live through it, and a held command stops only because the view reports the Station unattended.
The slide is free; what it should cost and how it fails is in `docs/design/not-yet-designed.md`.
