# The Glide

The Glide (ticket #123) is `Glide` (`sim/glide.gd`), a subsystem `DiveSimulation` owns and steps; it knows nothing of the layout, the scan or the Stations, and is handed how far the scan reaches, where the Head is and what it may draw.
Its choices and their reasons are in the design record, "The Glide (#123)" (`docs/design-record.md` names the file).

## The interface

- Commands: `plot_glide(metres)` (Navigation; held to `glide_reach()`, 0 clears), `start_glide()` and `drop_out_of_glide()` (the Drive). `set_course()` gives up a plot; `set_quiet_ship(true)` drops out; `shift()` ends the idle after a Glide.
- Queries: `gliding()`, `glide_state()`, `glide_thrust()` (`GLIDE_NONE`, `GLIDE_GLIDING`, `GLIDE_DROPPING_OUT`, `GLIDE_IDLE`), `glide_plotted()`, `glide_reach()`, `glide_refusal()`, `glide_range_left()`, `glide_end()`, `glided_stretches()`, `column_absent(behind_head)`, `wobble_on_plasma()`, `heat_carried_aft()`.
  The tunnel's (#125): `link_light_share()`, `rough_tunnel_metres()`, `rough_tunnel_runs()`, `tunnel_walls()`, `tunnel_wall_count()`.
- Events: `glide_plotted {length}`, `glide_started {length, distance}`, `glide_ended {by, distance, glided}`; `pulse_sent` gains `drowned`.
- Calls: the Drive's `glide_ending` and the Reactor's `head_at_idle` are reports (`_REPORTS`): they never drop the time rate.
- `start_glide()` leaves the Drive's autopilot as it is (#161), the one Drive command that does; `drop_out_of_glide()` and a nudge disengage it.

## Where it meets the rest

- **The step.** `_step()` runs `_glide_on()` in place of `_crawl()` while `gliding()`; everything after the move (the link, surfacing, pulses, autopilots, stranding, calls) is shared.
  A Glide moves in pieces of `Glide.piece()` metres through `_glided()`, so a long step at a raised time rate meets both surfaces of a thin layer, and never past its end.
- **What it was shown.** `glide_reach()` reads the scan alone, `BoundaryFit.furthest()` along the Course's line from the Head, worked out again only when the fit, the line or the Course changes; never read the layout for it.
  `glide_refusal()` and `start_glide()` ask along the Head's line instead: each way keeps its own `ReachWorked`, so polling both costs no more than one (`glide_reach_workings()` counts the workings for the tests; #159).
- **The rock it ends in.** `start_glide()` hands `Glide.began_in()` what the crew knows of the rock it starts in: the guess held (at a Glide's idle, or settling after a crossing), else the Wobble felt on the plasma. Each crossing replaces it (`Glide.crossed()`) and `_end_glide()` holds the last; the layout's Wobble is never handed to the scan side (#159).
  In a Glide `_watch_boundaries()` looks ahead again at each crossing, so two Boundaries met in one long step hand on the guess of the rock beyond the second.
- **The Wobble.** Everything that reads the Wobble on the plasma goes through `_wobble_on_plasma()`: false in a Glide and at the idle after it, so `out_of_band()` is false, `tend_off_rock()` replaces `Plasma.tend()`, `wobble_frequency()` reads 0 and ACTIVE's Residual is NAN (the Reactor screen says NO WOBBLE ON THE PLASMA).
  A new reading of the Wobble on the plasma uses `_felt_wobble()`, not `_wobble()`, which stays the rock's for what the rock does (a relight, the guess).
- **The Column.** `column_absent()` is the one test of whether a place in the Bore has a Column; `_in_column()`, the Bore Station's lines and `ColumnStrip` follow it. A glided stretch records nothing and its features are marked found and never added.
- **Power and heat.** In a Glide `_share_power()` gives Navigation its draw and Thermal its base draw and the Drive the rest of an output that builds with the jet's thrust; `Heat.step()`'s `aft_share` carries all but `Glide.hull_share()` of the heat away, none into the Column.
- **The scan.** A Glide is deaf: `_send_pulse()` counts a drowned pulse and returns nothing (no `scan_revision()` change), `start_glide()` ends a running Sweep (`_end_sweep(false)`) and `start_sweep()` is ignored while `Glide.active()`.
- **Halts.** `_strand()`, `_die()` and `_rest_at_surface()` call `Glide.halt()` (no idle); the last two also end a running Sweep (`_end_sweep(false)`, #159), as a stranded step does; self-destruct drops out and spins the Head up.

## Flown by hand (#126)

- **The drift is per metre, not per second.** Each piece `_glide_on()` hands `Glide.fly(piece, _rock_push(), autopilot(STATION_DRIVE))` the rock's push and moves the Head by what it returns; the slope it runs at is where the nudges hold it, the rock's push, the sheath's seeded wander (`_wander()`, knots drawn as the Glide reaches them) and the instability (being off pushes further off, capped).
  So a raised time rate flies the same Glide, and the same dive drifts the same.
- **Off the line is measured across it.** `Glide.left()` and `_along` run along the line, so a Glide still halts at its plotted length and never past what the scan showed; the offset (`glide_off_line()`, Vector2(right, steeper), the ball's own axes worked out at `start()` from the Head's heading) is perpendicular to it.
  At the halt `_end_glide()` sets the Head back along the line, so the next Glide may start without crawling straight first.
- **The rock's push** reads the true rock: `_rock_push()` asks `medium_at_point()` at `Glide.sides()` (either side of the Head on both axes) and `Glide.rock_push()` pushes toward the softer side; it is felt only where a Boundary crosses the line obliquely.
- **Wear** is the two wears there are: past `Glide.slack()` each piece's `slapped()` goes to `Plasma.slap()` (worn through loses the plasma, as a Residual would) and `Heat.slap()` (the hull's one wear, so `Heat.failed()` and stranding follow). `hull_taking_damage()` includes a step that slapped.
- **Correcting.** In a Glide `_nudge()` calls `Glide.nudge()` after disengaging the Drive's autopilot and returns: no override, no lean. The autopilot's rule is in `Glide.fly()`: nothing until `_AUTOPILOT_LOOSE_M` off, then nudge back in proportion; it sets the hold (`_held`), which stays where it left it when disengaged.
- **The call.** `&"off_glide_line"` is the Drive's call while past the slack (urgency by `glide_contact()`): flown by hand a warning, dropping the time rate as any warning; while `autopilot(STATION_DRIVE)` holds the Glide, a report (#161), shown on the Drive's screen and light alike and wearing alike, and a warning again, sounding anew, once the autopilot lets go.
- **The ball.** `FlightDisplay` draws the line to hold at `glide_aim()` (a cyan diamond) and the bottom right figure from `FlightDisplay.glide_line_figure()`.

## The tunnel and the link (#125)

- `_update_tunnel()` decides each metre the Tail leaves by one rule for both ways of moving: dense rock seals it, whoever cut it; porous rock leaves it open, glass where the Head crawled and rough where it glided (`Glide.glided_within()`, which looks back only over Glides past the Tail).
  So the seal's call, event, sealed metres, rescue and stranding are the Crawl's, untouched; only the light up the open tunnel knows a Glide.
- `_lay_wall()` lays each piece into `tunnel_walls()` (`TUNNEL_GLASS`, `TUNNEL_ROUGH`, `TUNNEL_SEALED`, a new piece only where the wall changes) and counts the open rough metres and runs (`rough_tunnel_metres()`, `rough_tunnel_runs()`), O(1) a step.
- `link_light_share()` is the light that arrives, falling with each rough run and each rough metre; `link_capacity()` open is the glass rate times it, so the link, payment and surface control's messages all follow.
- A Glide can carry the Tail into dense rock within the step the Head entered it; `_seal_called` makes the Bore Station's `tunnel_about_to_seal` call all the same, once, at its most urgent.
- The view: the Bore Station's `TunnelPanel.link_line()` says the share and the rough runs; #127 draws the walls from `tunnel_walls()`, read again when `tunnel_wall_count()` changes (`TunnelLook`, `glide-look.md`).

## Seams left for later tickets

- **#127, the look and sound**: built; see `glide-look.md`. It added the one query `glide_thrust()`. `noise()` carries `Glide.jet_noise()`.
- **#128, the Checklist** (done): the First dive's way home is a Glide (its phases "Glide home" and "Out of the Glide") and the Glide drill practises one; their steps tick on `Scenario.gliding()`, `&"glide_ended"`, `Scenario.crawling()` and `DiveSimulation.straight_on_course()` (`scenarios-and-checklist.md`).

## Testing

- `test/glide_test.gd` holds the rules at the simulation's interface, each with its inversion, and `test/glide_tunnel_test.gd` the tunnel's; `test/glide_screens_test.gd` stages a Habitat for what the screens say.
- `_surveyed()` there starts a dive with the survey's soundings: a Glide needs a scan, and `start_surveyed()` gives one at once.
- `test/glide_flying_test.gd` holds #126's rules. A Glide nobody holds now drifts and wears, so a test that wants none flies it with `DiveTestKit.fly_glide(sim, true)`, a careful hand reading only `glide_off_line()` and `glide_range_left()` (with `off`, it holds a line beside the Glide's); keep its steps about 0.02 s of simulated time, shorter at a raised rate.
