# The plasma and the Shift

**The plasma and the Shift** (`sim/plasma.gd`, `Plasma`): stability, tuning, the Shift's window and grade, the autopilot Shift, the heat spike and lurch of a poor Shift, Head wear, losing the plasma.
`Plasma.tend()` runs once a step at the start of `_step()`, before the power is shared; `open_window()` is called on crossing a Boundary.
New plasma, Shift and Head behaviour goes here.
A relight (`relight(target, roll)`) strikes a lost plasma at `relight_chance()`, which falls with Head wear; the roll comes from `DiveSimulation._relight_random` (kept between dives) and the pulse is paid from the store first.
A relit Head keeps its wear.
Head wear reaches the Shift in one place, `_narrowing()` (1 fresh, smaller when worn), which scales the window (`window_length()`, read as `shift_window_length()`), the grading tolerance and the lateness falloff; whether the plasma still holds (`due()`) does not narrow.
A worn Head's lower power is its unsteadiness term in `stability()`.
How closely a Shift's frequency matches the wobble is one rule, `match_to()` (read as `shift_match(frequency)`): the grade is that match times lateness, and the Reactor screen's MATCH meters read it (ACTIVE against the wobble now, STANDBY against `wobble_ahead()`), so what the crew sees is what the Shift is graded on.
A poor Shift loses the plasma two ways, both in `_make_shift()`: a disruption (its roughness times the wear already on the Head reaches `_DISRUPTION`), which leaves the Head with only that Shift's own wear, or wearing the Head through (its wear takes the Head to 1).
A clean Shift adds no wear, so it can do neither, whatever the wear: that is why a relit Head worn through holds through clean Shifts.
So a plasma lost by a Shift can leave any wear from about half up, and the relight rolls at that real wear.
`Plasma.frequency_in(medium)` is the wobble's frequency.

**The Shift dial** is two channels, like an airliner radio's active and standby frequencies, both held by `Plasma` and read through the simulation: ACTIVE is `plasma_tuning()`, the tuning that holds the plasma now; STANDBY is `standby_tuning()`, staged by `set_standby_tuning()` and changing nothing until `shift()` swaps the two (on the next step).
The swap is the Shift, graded as any Shift (`_make_shift()`: the new active's match to the wobble at that moment, then lateness), and the old active drops to standby, so a second `shift()` swaps back and is graded too.
The Reactor's autopilot Shifts through the same path (`Plasma._shift_to()`, on the wobble, not STANDBY), so its old active drops to standby as well, replacing any pretune.
There is no Shift straight to a frequency at the seam; tests use `DiveTestKit.shift_to(sim, frequency)` (pretune, then swap).
STANDBY's preview is `wobble_ahead()`, the wobble in the Medium beyond the Boundary last announced (`&"boundary_approaching"`), NAN before the first such call, then held through the crossing (when STANDBY is swapped in, or back) until the next is announced; `standby_match()` reads STANDBY against it (NAN, drawn "—", before the call).
Exact for now; a projection the scan sharpens replaces it there, and the view and the Checklist follow.
The Checklist's "Pretune standby" steps read `standby_tuning()` (`Scenario.standby_pretuned_for()`).
Tuning STANDBY is a selector, not a setting: it leaves the Reactor's autopilot engaged; the swap is a command and disengages it.
Step states reach the view and tests as `DiveSimulation.STEP_*`, as Station names do.
