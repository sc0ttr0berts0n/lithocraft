# The plasma and the Shift

**The plasma and the Shift** (`sim/plasma.gd`, `Plasma`): the Wobble, the two Counter-waves, the Residual, the Band, Head wear, steadiness and its causes, the grinding, the Reactor's autopilot, losing and relighting the plasma.
`Plasma.tend()` runs once a step at the start of `_step()`, before the power is shared, and is handed the Wobble now (`DiveSimulation._wobble()`, from `Plasma.wobble_in(medium)`); nothing is called on crossing a Boundary, the Wobble handed in simply changes.
New plasma, Shift and Head behaviour goes here.
Waves are `Vector2(frequency in hertz, amplitude)` inside `Plasma`; the simulation's queries give the two parts apart (`wobble_frequency()`, `wobble_amplitude()`, `counter_wave_frequency(channel)`, `counter_wave_amplitude(channel)`).
The Wobble's frequency rises with the Medium's hardness and its amplitude with its strength; amplitudes have no unit, about 1 at the biggest.
The Residual is the Wobble summed with a Counter-wave, and is one model in one place: the Counter-wave is the Wobble's inverse with its phase locked to the Wobble's, swinging about it by `Plasma._swing()` (nothing on frequency, a half turn each way at `_LOCK_RANGE` and beyond) at the difference of the two frequencies.
So a wrong amplitude leaves a steady Residual (`residual_steady(channel)`), a wrong frequency a beating one (`residual_beat(channel)`, coming `residual_beat_frequency(channel)` times a second), and `residual(channel)` is the two together, the Residual at its fullest.
The screens draw the same model through `wobble_wave(channel, seconds)`, `counter_wave(channel, seconds)` and `residual_wave(channel, seconds)` (seconds from now, negative for the past), so what the crew sees is what wears the Head.
The Band (`band()`, in the Wobble's units, as of the last step) is set in one place, `Plasma._band_of(wear, hull_heat_share)`: narrower as the Head wears and as the hull runs hot, easing live as it cools.
`band_widest()` is a fresh Head's with the hull cool, what the screen shows the Band has narrowed from.
`out_of_band()` is ACTIVE's Residual at its fullest against the Band, read against the Wobble now, so it is true from the step a Boundary is crossed; the Reactor calls `&"out_of_band"`, louder the further out.
Each step `tend()` samples the Residual along its swing across the step: its mean distance outside the Band wears the Head (`_WEAR_PER_S`) and unsteadies the plasma, its furthest sets the grinding's roughness (extra heat, `Plasma.grind_heat()`, and the shudder, `shudder()`, felt through `felt_acceleration()`).
Inside the Band nothing wears, however long; the swap itself costs nothing.
`plasma_stability()` is one rule, `Plasma._steadiness(wear, outside)`: a worn Head's own unsteadiness times what the Residual outside the Band takes.
`steadiness_causes()` names each cause pulling it down now (`CAUSE_WORN`, `CAUSE_HOT`, `CAUSE_OUT_OF_BAND`), for the Reactor's Caution lamps (`CautionLamps`): worn and hot are each found by asking what the steadiness would be without that cause, so hot is named only while the Band it narrowed is costing something.
It is worked out on the state as it stands, with the Residual at its fullest, so a lamp neither waits for a step nor flickers with the beats.
The plasma is lost two ways, both in `tend()`: `&"disrupted"`, when the Residual's roughness at its fullest times the Head's wear has stayed at `_DISRUPTION` or more for `_DISRUPTION_S` seconds (a fresh Head never; a badly worn one rides out only the few seconds a swap takes), or `&"worn_through"`, when wear outside the Band takes the Head to 1.
A relit Head worn through therefore holds for as long as its Residual stays inside the Band.
A relight (`relight(wobble, roll)`) strikes a lost plasma at `relight_chance()`, which falls with Head wear, with ACTIVE set to cancel the Wobble; the roll comes from `DiveSimulation._relight_random` (kept between dives) and the pulse is paid from the store first.
A relit Head keeps its wear.

**The Shift dial** is two channels, like an airliner radio's active and standby frequencies, each holding a Counter-wave, both held by `Plasma` and read through the simulation by channel (`CHANNEL_ACTIVE`, `CHANNEL_STANDBY`): ACTIVE's cancels the Wobble now; STANDBY's is prepared for the Medium ahead and changes nothing until `shift()` swaps the two (on the next step).
The Reactor's two controls, `tune_frequency(hertz)` and `tune_amplitude(amplitude)`, tune the channel `select_channel(channel)` chose (`selected_channel()`): STANDBY as each dive begins, and a swap leaves the selection where it was.
Tuning ACTIVE moves the live plasma's Residual at once, with no Shift made.
The swap is the Shift: the old ACTIVE drops to STANDBY, so a second `shift()` swaps back.
It raises `&"shift_result"` `{clean, residual, band}`, `clean` when the new ACTIVE's Residual at its fullest is inside the Band at that moment; nothing is charged at the swap, so a swap made early or late costs only the time its Residual spends outside the Band.
The Reactor's autopilot makes no Shift: engaged, `tend()` moves ACTIVE's frequency and amplitude toward the Wobble at `_AUTOPILOT_FREQUENCY_PER_S` and `_AUTOPILOT_AMPLITUDE_PER_S`, slowly, so it wears the Head through each Boundary (less than leaving it, more than a prepared swap) and engaging it can never be a jump in wear.
STANDBY is left as the crew set it.
Selecting and tuning are selectors, not settings: they leave the Reactor's autopilot engaged (it goes on tuning ACTIVE under the crew's hands); the swap is a command and disengages it.
There is no command straight to a Counter-wave at the seam; tests use `DiveTestKit.tune(sim, channel, wave)` (select, tune both controls, select back), `DiveTestKit.shift_to(sim, wave)` (prepare STANDBY, then swap) and `DiveTestKit.cancel_wobble(sim)` (ACTIVE onto the Wobble now).
`DiveTestKit.wear_head_gently()` and `lose_plasma()` wear the Head and lose the plasma through the Residual, as a crew would.
**The look-ahead** (`sim/look_ahead.gd`, `LookAhead`, a subsystem owned as `_look`): the Inferred Boundary ahead along the Head's direction, the Boundary countdown and the scan's guess of the Wobble beyond, looked at after each move and each pulse (`DiveSimulation._look_ahead()`).
It is handed the patches (`BoundaryFit.ahead()`, see `scan.md`), where the Head is and how far it has come, and never the layout: where a Boundary is, when it comes and how sure that is are functions of the points alone, so a scan that puts a Boundary where none is misleads the countdown and the guess alike.
It is told two things besides, both of which the crew have by other means: that a crossing was felt (`felt_crossing()`, from `_watch_boundaries()`), and the Wobble the echoes carry (`_wobble_beyond()`: the Medium's beyond the next Boundary in the way the depth is changing, or the Medium's the Head is in when none lies ahead).
A test scans its source for any name of the layout (`look_ahead_test.gd`), and it is tested on patches alone, as the fit is on points alone; new look-ahead behaviour goes there.
STANDBY's preview is that guess (`sim/wobble_guess.gd`, `WobbleGuess`): a sum of sines, the Wobble the echoes carry placed off the truth in frequency and amplitude, and spurious sines beside it.
Both shrink as `wobble_ahead_confidence()` rises, the error faster than the spurious sines; which way a Boundary's guess errs and its spurious sines are fixed by the Boundary, so a guess sharpens or blurs and never jitters.
That confidence is the Inferred Boundary's ahead, whether or not a Boundary truly lies there.
`wobble_ahead_frequency()` and `wobble_ahead_amplitude()` are the guess's true component (NAN with no Inferred Boundary ahead: no call or nearness ever tells it), `wobble_ahead_spurious()` the spurious sines' amplitudes summed, and `wobble_wave(CHANNEL_STANDBY, seconds)` the whole sum, never NAN.
STANDBY's predicted Residual (`residual*(CHANNEL_STANDBY)`) is its Counter-wave against the true component as guessed, so it reads flat on a guess that is wrong and the truth arrives at the Boundary; NAN, drawn "—", with no scan.
`residual_wave(CHANNEL_STANDBY, seconds)` keeps the spurious sines in it, a ripple no tuning removes and only a better scan does.
The guess is held as it was from a crossing until ACTIVE's Residual is inside the Band in the Medium entered (so STANDBY reads against the rock it was prepared for when it is swapped in), then looks to the next Boundary.
A crossing felt also spends whatever the scan put just ahead of it (`LookAhead._SCAN_OUT_M`): that was this Boundary, placed a little deep, not another.
`settling_in()` is true for that stretch and no other: a Residual outside the Band with no Boundary just crossed is a mistuned ACTIVE, not a crossing.
The Boundary countdown is `boundary_countdown()` and `boundary_countdown_doubt()`, seconds: the distance to the Inferred Boundary ahead over the speed now, and a plus-or-minus that shrinks with its confidence.
It reads only the scan, never the layout, and is INF ("> 5 min", `boundary_countdown_cap()`) with no Inferred Boundary ahead, when stopped, or beyond the cap.
Once the Head has come to where the scan put a Boundary with no crossing felt it reads 0, due, its plus-or-minus growing by every metre run past; run `_SCAN_OUT_M` past, the scan was wrong, and the countdown and the guess fall back to whatever patches lie further ahead.
The Checklist's "Pretune standby" steps hold while STANDBY's predicted Residual is inside the Band (`Scenario.standby_pretuned()`): they read the guess, which is what the crew can see, so they tick on a misleading guess and never with no scan.
A Scenario whose Checklist asks for a pretune therefore gives the crew a scan first: a pulse step before it, or a pulse sent in `prepare` (the Shift drill).
In the First dive that step is "Pulse until Navigation shows the Boundary ahead" (`Scenario.scan_shows_boundary_ahead()`: a guess exists, however many pulses it took), ticking at once when an earlier scan already shows it.
A Shift lets the Reactor's autopilot go and may leave the Residual outside the Band, so each Shift step of the First dive and the Shift drill is followed by "Select active and tune it until the Residual is inside the Band" (`Scenario.settled_in()`), which ticks at once after a Shift that left it inside.
Its "Shift" steps tick on `&"shift_result"` in that Medium, and the phase after a Boundary begins once the Residual is inside the Band there (`Scenario.settled_in()`), however it got there.
Step states reach the view and tests as `DiveSimulation.STEP_*`, as Station names do.
