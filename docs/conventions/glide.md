# The Glide

The Glide (ticket #123) is `Glide` (`sim/glide.gd`), a subsystem `DiveSimulation` owns and steps; it knows nothing of the layout, the scan or the Stations, and is handed how far the scan reaches, where the Head is and what it may draw.
Its choices and their reasons are in the design record, "The Glide (#123)" (`docs/design-record.md` names the file).

## The interface

- Commands: `plot_glide(metres)` (Navigation; held to `glide_reach()`, 0 clears), `start_glide()` and `drop_out_of_glide()` (the Drive). `set_course()` gives up a plot; `set_quiet_ship(true)` drops out; `shift()` ends the idle after a Glide.
- Queries: `gliding()`, `glide_state()` (`GLIDE_NONE`, `GLIDE_GLIDING`, `GLIDE_DROPPING_OUT`, `GLIDE_IDLE`), `glide_plotted()`, `glide_reach()`, `glide_refusal()`, `glide_range_left()`, `glide_end()`, `glided_stretches()`, `column_absent(behind_head)`, `wobble_on_plasma()`, `heat_carried_aft()`.
- Events: `glide_plotted {length}`, `glide_started {length, distance}`, `glide_ended {by, distance, glided}`; `pulse_sent` gains `drowned`.
- Calls: the Drive's `glide_ending` and the Reactor's `head_at_idle` are reports (`_REPORTS`): they never drop the time rate.

## Where it meets the rest

- **The step.** `_step()` runs `_glide_on()` in place of `_crawl()` while `gliding()`; everything after the move (the link, surfacing, pulses, autopilots, stranding, calls) is shared.
  A Glide moves in pieces of `Glide.piece()` metres through `_glided()`, so a long step at a raised time rate meets both surfaces of a thin layer, and never past its end.
- **What it was shown.** `glide_reach()` reads the scan alone, `BoundaryFit.furthest()` along the Course's line from the Head, worked out again only when the fit, the line or the Course changes; never read the layout for it.
- **The Wobble.** Everything that reads the Wobble on the plasma goes through `_wobble_on_plasma()`: false in a Glide and at the idle after it, so `out_of_band()` is false, `tend_off_rock()` replaces `Plasma.tend()`, `wobble_frequency()` reads 0 and ACTIVE's Residual is NAN (the Reactor screen says NO WOBBLE ON THE PLASMA).
  A new reading of the Wobble on the plasma uses `_felt_wobble()`, not `_wobble()`, which stays the rock's for what the rock does (a relight, the guess).
- **The Column.** `column_absent()` is the one test of whether a place in the Bore has a Column; `_in_column()`, the Bore Station's lines and `ColumnStrip` follow it. A glided stretch records nothing and its features are marked found and never added.
- **Power and heat.** In a Glide `_share_power()` gives Navigation its draw and Thermal its base draw and the Drive the rest of an output that builds with the jet's thrust; `Heat.step()`'s `aft_share` carries all but `Glide.hull_share()` of the heat away, none into the Column.
- **Halts.** `_strand()`, `_die()` and `_rest_at_surface()` call `Glide.halt()` (no idle); self-destruct drops out and spins the Head up.

## Seams left for later tickets

- **#125, the Glide's tunnel**: `glided_stretches()` marks each glided stretch by path distance; `_glided()` runs `_update_tunnel()` as the Crawl does, which is where a glided stretch's own tunnel rule goes.
- **#126, flown by hand**: `Glide.spin()` and `_glide_on()` hold the line and wear nothing; a hand-flown Glide steers there. FlightDisplay's bottom-right corner and its one reserved ball marker stay free for it.
- **#127, the look and sound**: the view only leaves out a Column that is not there and has the Bore Station say so; the jet, the sheath and the roar are #127's. `noise()` already carries `Glide.jet_noise()`.
- **#128, the Checklist**: no Scenario's Checklist knows the Glide; the events above are what its triggers would read.

## Testing

- `test/glide_test.gd` holds the rules at the simulation's interface, each with its inversion; `test/glide_screens_test.gd` stages a Habitat for what the screens say.
- `_surveyed()` there starts a dive with the survey's soundings: a Glide needs a scan, and `start_surveyed()` gives one at once.
