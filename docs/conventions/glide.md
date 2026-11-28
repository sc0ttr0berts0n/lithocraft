# The Glide

The Glide (ticket #123) is `Glide` (`sim/glide.gd`), a subsystem `DiveSimulation` owns and steps; it knows nothing of the layout, the scan or the Stations, and is handed how far the scan reaches, where the Head is and what it may draw.
Its choices and their reasons are in the design record, "The Glide (#123)" (`docs/design-record.md` names the file).

## The interface

- Commands: `plot_glide(metres)` (Navigation; held to `glide_reach()`, 0 clears), `start_glide()` and `drop_out_of_glide()` (the Drive). `set_course()` gives up a plot; `set_quiet_ship(true)` drops out; `shift()` ends the idle after a Glide.
- Queries: `gliding()`, `glide_state()`, `glide_thrust()` (`GLIDE_NONE`, `GLIDE_GLIDING`, `GLIDE_DROPPING_OUT`, `GLIDE_IDLE`), `glide_plotted()`, `glide_reach()`, `glide_refusal()`, `glide_range_left()`, `glide_end()`, `glided_stretches()`, `column_absent(behind_head)`, `wobble_on_plasma()`, `heat_carried_aft()`.
  The tunnel's (#125): `link_light_share()`, `rough_tunnel_metres()`, `rough_tunnel_runs()`, `tunnel_walls()`, `tunnel_wall_count()`.
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
- **The scan.** A Glide is deaf: `_send_pulse()` counts a drowned pulse and returns nothing (no `scan_revision()` change), `start_glide()` ends a running Sweep (`_end_sweep(false)`) and `start_sweep()` is ignored while `Glide.active()`.
- **Halts.** `_strand()`, `_die()` and `_rest_at_surface()` call `Glide.halt()` (no idle); self-destruct drops out and spins the Head up.

## The tunnel and the link (#125)

- `_update_tunnel()` decides each metre the Tail leaves by one rule for both ways of moving: dense rock seals it, whoever cut it; porous rock leaves it open, glass where the Head crawled and rough where it glided (`Glide.glided_within()`, which looks back only over Glides past the Tail).
  So the seal's call, event, sealed metres, rescue and stranding are the Crawl's, untouched; only the light up the open tunnel knows a Glide.
- `_lay_wall()` lays each piece into `tunnel_walls()` (`TUNNEL_GLASS`, `TUNNEL_ROUGH`, `TUNNEL_SEALED`, a new piece only where the wall changes) and counts the open rough metres and runs (`rough_tunnel_metres()`, `rough_tunnel_runs()`), O(1) a step.
- `link_light_share()` is the light that arrives, falling with each rough run and each rough metre; `link_capacity()` open is the glass rate times it, so the link, payment and surface control's messages all follow.
- A Glide can carry the Tail into dense rock within the step the Head entered it; `_seal_called` makes the Bore Station's `tunnel_about_to_seal` call all the same, once, at its most urgent.
- The view: the Bore Station's `TunnelPanel.link_line()` says the share and the rough runs; #127 draws the walls from `tunnel_walls()`, read again when `tunnel_wall_count()` changes (`TunnelLook`, `glide-look.md`).

## Seams left for later tickets

- **#126, flown by hand**: `Glide.spin()` and `_glide_on()` hold the line and wear nothing; a hand-flown Glide steers there. FlightDisplay's bottom-right corner and its one reserved ball marker stay free for it.
- **#127, the look and sound**: built; see `glide-look.md`. It added the one query `glide_thrust()`. `noise()` carries `Glide.jet_noise()`.
- **#128, the Checklist**: no Scenario's Checklist knows the Glide; the events above are what its triggers would read.

## Testing

- `test/glide_test.gd` holds the rules at the simulation's interface, each with its inversion, and `test/glide_tunnel_test.gd` the tunnel's; `test/glide_screens_test.gd` stages a Habitat for what the screens say.
- `_surveyed()` there starts a dive with the survey's soundings: a Glide needs a scan, and `start_surveyed()` gives one at once.
