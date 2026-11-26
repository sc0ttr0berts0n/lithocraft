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
STANDBY's preview is `wobble_ahead_frequency()` and `wobble_ahead_amplitude()`, the Wobble in the Medium beyond the Boundary last announced (`&"boundary_approaching"`), NAN before the first such call, then held through the crossing (when STANDBY is swapped in, or back) until the next is announced.
STANDBY's Residual queries and waves are read against it (NAN, drawn "—", before the call; its Counter-wave alone is still drawn).
Exact for now; a projection the scan sharpens replaces it there, and the view and the Checklist follow.
The Checklist's "Pretune standby" steps hold while STANDBY's Counter-wave would leave that Medium's Wobble a Residual inside the Band (`Scenario.standby_pretuned_for()`), its "Shift" steps tick on `&"shift_result"` in that Medium, and the phase after a Boundary begins once the Residual is inside the Band there (`Scenario.settled_in()`), however it got there.
Step states reach the view and tests as `DiveSimulation.STEP_*`, as Station names do.
