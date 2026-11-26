# Station calls and autopilots

**A new Station call.**
Add an `_offer_call(calls, station, reason, urgency)` in `_update_calls()`, with urgency from `_urgency(_<KIND>_CALL, share)` and a new `const _<KIND>_CALL := Vector2(begins, worst)` beside the others, never an inline number.
A call that begins or changes reason raises `&"station_call"` and drops the time rate to 1.

**Autopilots.**
Each Station's autopilot is a switch, A320 style: `set_autopilot(station, engaged)` (E at every Station), read with `autopilot(station)`.
The switch alone decides whether a Station steadies itself; attendance (`set_attended()`) matters only for commands that need the crew there (the Drive's override, self-destruct's hold), so a crew member can stand and watch an autopilot work.
Every autopilot starts off each dive (`_autopilot` is per dive).
Any Station command other than a reading (one that changes a setting, or acts as `shift()` and `relight()` do: the crew taking the controls) starts with `_disengage_on_command(STATION_...)` after its guards, which disengages its autopilot and raises `&"autopilot_off"` with `cause` `AUTOPILOT_OFF_BY_COMMAND` (the switch's own cause is `AUTOPILOT_OFF_BY_SWITCH`);
a reading (`pulse()`, `set_observed_feature()`) does not call it.
A new command calls it unless it only takes a reading.
Off, a Station holds its setting and does nothing more; its calls still come.
Engaged, its steadying rule runs in `_steady_autopilots()` (Drive backs power off to the grip limit while slipping; Thermal raises the heat split while the hull warns), or in its own place: the Reactor's slow tuning of ACTIVE toward the Wobble in `Plasma.tend()` (passed `autopilot(STATION_REACTOR) or _self_destructing`), the Drive's gentle steering cap in `_steer()`.
Engaging the Drive's sets its slow, safe power (`_AUTOPILOT_DRIVE_POWER`) and ends any override, so a plotted Course plus the Drive's autopilot gets the vessel moving.
A new Station's rule goes in `_steady_autopilots()` behind `autopilot(STATION_...)`.
A test that wants a Station to steady itself engages its autopilot (see Testing).
