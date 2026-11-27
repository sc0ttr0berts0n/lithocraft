# Stranding, self-destruct and how a dive ends

**Stranding, rescue and death** (`sim/stranding.gd`, `Stranding`): what losing the plasma or the hull comes to (`check()` once a step, stranded steps included: `DIED` when the hull fails, whatever the plasma, so the stranding clock running out is the same death as any other hull failure; `STRANDED` sealed in;
`BROUGHT_HOME` with the tunnel open), whether the Lithocraft is stranded or its crew dead, the repair bills (hull and Head), the rescue (its time from the open and sealed lengths, `call_rescue()` at the stranding, `wait_for_rescue()` each stranded step, its cost), the rebuy.
`DiveSimulation._check_stranded()` carries the outcome out on the survey, the link and the vessel's place (`_die()`, `_strand()`, `_bring_home()`, and `_rescue()` when the rescue arrives), since those are the simulation's.
It holds the emergency store (see "The emergency store" below).
The tunnel's sealed length is counted on `DiveSimulation` (`_sealed_metres`, added to in `_update_tunnel()` as the Tail leaves dense rock; O(1) a step) and handed in.
A stranding keeps the survey aboard (the link can still send it, on the store); the rescue brings it home and sells it, death loses it (`_lose_unsold()`).
`stranding_clock()` and `rescue_time()` are live estimates at any time: stranded, running live; under way, what they would be if the plasma went now.
New stranding behaviour goes here; the simulation applies what it decides.
The reset itself (`new_dive()`, `_start_fresh()`) stays on `DiveSimulation`, because it resets every part of it.

**The emergency store.**
One store of energy (`Stranding`, read as `emergency_store()`) for everything that runs once the plasma is lost (`on_emergency_store()`).
A consumer that can run on less (the link, cooling) takes `_stranding.draw(energy)` each step and scales its effect by what it got (cooling draws first, then the link); what each draws a second is reckoned once (`_cooling_draw()`, `_link_draw()`), for both `_step_stranded()` and `stranding_clock()`, so the clock and the death it predicts cannot drift;
a new consumer gets its own such method and is added to both; one that needs all at once (a relight's pulse) calls `_stranding.pay(energy)` and is refused on false.
It is full at the start of every dive and is not drawn while the plasma holds.
Energy is in the units of `set_power()` times seconds.

**Self-destruct.**
Held commands are counted in the simulation, not the view: the view reports whether the key is held each frame (`hold_self_destruct(held)`) and `advance()` counts the hold in real seconds (its `dt`, before the time rate) at an attended Station, so the hold is testable at the seam.
While `self_destructing()` the Stations are off the crew: Station commands return early on `_off_the_crew()` (the Bore Station's stay the crew's, so the link can still send), the Reactor's Shifts go to its autopilot whatever its switch, `_steady_autopilots()` does nothing, the autopilots' switches (but the Bore Station's) are ignored and calls do not hold down the time rate.
Under way `_mismanage()` sets the settings each step; stranded it is one more store consumer, `_dump_draw()`, drawn first and counted in `stranding_clock()` (passed to `Heat.soak()` / `time_to_fail()` as `dumped` power).
`&"hull_failed"` carries `cause` (`&"heat"` or `&"self_destruct"`), and `cause_of_death()` keeps it after death, so every screen names the same cause.
It is not a one-way door: `_start_self_destruct()` keeps the crew's settings (`_crew_settings`: power, heat split, Quiet Ship) and `cancel_self_destruct()` puts them back; only the wear and the store spent stay.
A plasma lost meanwhile strands it into the dump, and `_strand()` zeroes the kept heat split too, since the pumps stopped with the Head.
A setting self-destruct comes to touch goes in `_crew_settings`.
A hold that could do nothing (stranded with the store empty) does not count: `can_self_destruct()`.

**How a dive ended.**
`outcome()` is the one query for it: `ending` (`&"under_way"`, `&"surfaced"`, `&"brought_home"`, `&"rescued"`, `&"dead"`), `cause` (dead: as `cause_of_death()`; brought home or rescued: why the plasma was lost), `plasma_lost_by` (`Plasma.lost_by()`:
`&"disrupted"`, `&"worn_through"`, `&"scenario"`, `&"debug"`, also carried as the `&"plasma_lost"` event's `cause`), `stranded_for` and `depth`.
It is set in the two places a dive ends, `_die()` and `_come_home()`, into the per-dive `_outcome`, so a new ending goes through one of them and a new way to lose the plasma passes its cause to `Plasma._lose()`.

**New dives.**
`new_dive()` (after surfacing, being brought home through the tunnel or a rescue, or after death: the rebuy) calls `_start_fresh()`, which resets every script variable to a fresh simulation's except `_KEPT_BETWEEN_DIVES`.
There is no `recover()`: a stranding ends in a relight, the rescue (automatic, `rescue_time()` after the stranding) or death.
A new per-dive variable needs nothing.
A variable that must survive (what was paid, where the crew is) goes in that list; a test in `stranding_test.gd` checks the list against the script's variables.
The subsystems (`_heat`, `_plasma`, `_stranding`) are replaced whole by a fresh simulation's, so a new variable inside one starts over with no work; one that must survive into the next dive lives on `DiveSimulation`, not in the subsystem.
Station settings return to their start, and the view never re-sends its own: the dive over, its key goes back to the start menu (`habitat.gd::_key_new_dive`), and a fresh Habitat reads its copies of the settings from the simulation as it starts (`_ready()`).
