# Round 4, as built, continued

The tickets of round 4 (spec #113), as built, continuing 18-round-4-as-built.md, which had reached its size.

## The Beam aimed (#120; agent's choices, the developer away)

- **Two directions relative to the vessel.**
  The aim is two angles, toward the vessel's right and toward its top, each held between square across one way and the other (`set_beam_aim(across, up)`, `beam_aim()`), so whatever is asked the Beam never points behind the vessel.
  The vessel does not roll, so its top is its right (level, square to its compass heading) turned square to the way the Head points: up travelling level, onward along the compass heading diving, as the attitude ball and the forward scope have it.
  The aim is held relative to the vessel, so it turns with the Head; `beam_axis()` is where it points in the world.
- **Nothing from behind.**
  A wide cone aimed square across would put half its rays behind the vessel; those are not sent, since the vessel and its tunnel lie there (as the Sweep's design has it: nothing is taken behind).
  Real basis: an array mounted in the Head faces forward and is shadowed by the hull behind it.
- **A setting.**
  By the conventions' rule the aim holds and changes where every later pulse sounds, the Beam's own pulsing included, so it is a setting and disengages Navigation's autopilot, as the width and the switch do.
- **Keys.** At Navigation: F / H aim left / right, K / I down / up (toward the vessel's underside / top), 15 degrees a press, as a Course step; R brings it back dead ahead.
  None was free among the Course's, the Beam's and the Sweep's own keys (G / T went to the Sweep's range); I above K reads as up above down.
- **How it shows.**
  Every scan view draws the cone about the aim, its fans flattened where they would pass square across, and a small hollow cyan diamond a fixed few pixels along the aim, so it reads at any view's scale; dead ahead the diamond is not drawn, the heading line saying the same.
  The label reads "BEAM NARROW 30 deg  AIM R45 U15" and Navigation's Beam line gains "aim R45 U15", both only while aimed.
- **What stays on the Head's line.**
  The look-ahead (the Boundary countdown and STANDBY's guess) and the forward scope's range read along the Head's direction however the Beam is aimed: an aimed pulse adds points and patches, and the Boundary ahead is still found along the Head's line through them.
  The Sweep winds about the heading and starts at the Beam's half-angle whatever the aim (#121).
- **For targets (#124).** A body off the vessel's axis is sounded by `set_beam_aim()` toward it and a pulse; `beam_axis()` gives the aimed direction in the world.


## The Glide (#123)

Agent's choices, the developer away. The class is `Glide` (`sim/glide.gd`); how it meets the code is `docs/conventions/glide.md`.

- **The keys.** Navigation: - / = shorten / lengthen the Glide's plot by 50 m, M a Glide of all the scan shows (V, G and T there are the Sweep's, F, H, K, I and R the Beam's aim). The Drive: V starts the plotted Glide, or drops out of a running one. Plotting is Navigation's, as the Course is; starting and stopping is the Drive's, as power is.
- **The speed multiple: about 64 times the Crawl's best in the same rock**, the developer's "maybe 64x" (16-glide-and-scan.md).
  Speed is the jet's power over the rock's hardness times the energy to melt a metre of the whole face, set at twice the Crawl's per metre (it melts the Column too), so harder rock is slower in a Glide as in the Crawl.
  The Reactor's output in a Glide builds with the jet's thrust to 128 units against the Crawl's 1.1. Real basis: melting a metre of rock costs the same energy at any speed, so many times the speed is many times the power; supercavitation is why the drag does not grow to match.
  The Crawl's output is held down by the Wobble of solid rock on the plasma, which a Glide's plasma, touching only melt, does not feel (ADR 0001: a constant tuned for play behind a true relationship).
- **Spin-up 3 s, spin-down 2 s**, the thrust building and dying evenly: felt, not waited on.
  Run to its plotted length, the jet begins to die when half its speed times its spin-down time would carry it to the end, and is then held to the thrust that still arrives there (harder rock entered on the way raises it), never under 5% until it is there; so a Glide halts at its length, and a long step at a raised time rate stops at it, never past.
- **What the scan has shown: the distance to the furthest Inferred Boundary along the Course's line, less 15 m** (`BoundaryFit.furthest()`, from the patches alone).
  An echo from that far means the rock on the way was sounded; beyond the furthest echo nothing is shown, and 15 m is about a worked scan's error and a little more than the vessel.
  A further Boundary heard (a narrower Beam, a pulse at Quiet Ship, a better fit) allows a longer Glide; the survey's soundings count, so a First dive can Glide from the surface to about 585 m.
  The plot is held to it when plotted and again at the start; plotting a new Course gives the plot up.
- **The heat numbers: the hull takes 0.2% of the Glide's heat, the jet carries the rest aft.**
  At full thrust that is a little over three times the heat of standing still with the Head running, a quarter of a Crawl at full power: modestly hotter. Real basis: a rocket's exhaust carries most of its heat away.
  There is no Column, so Thermal's split does nothing in a Glide: none goes into the Column, whatever it is set to, and its pumps draw only their base load.
- **Time rate**: the two multiply. A Glide moves in 1 m pieces, so a long step meets both surfaces of a thin layer, and never past its end.
- **Turns**: a Glide starts only with the Head within 1 degree of the Course and the Drive not overriding; in it, nudges and the Course change nothing (the Drive steers again after it). `glide_refusal()` says why one cannot start.
- **The Reactor**: in a Glide and at the idle after it no Wobble reaches the plasma; nothing wears and nothing is out of the Band, its autopilot holds nothing, and a worn Head is as unsteady as ever (less output).
  Its screen's first line says "Head GLIDE: no Wobble", ACTIVE's Residual reads "—" and its verdict NO WOBBLE ON THE PLASMA; at the idle, "Head AT IDLE: tune STANDBY here, [R] spins up".
- **Calls**: no Boundary is announced in a Glide, so no Boundary call. The Drive reports "glide_ending" within 10 s of the end, or while dropping out; the Reactor reports "head_at_idle" at the idle. Both are reports: they keep the time rate.
- **Power**: the jet takes all of the output but the base loads: Navigation keeps its draw (its screens; it is deaf all the same) and Thermal its base draw, so neither is starved or calls. Giving them nothing would have dimmed Navigation's screen, which must show the range left.
- **Survey and features**: the stretch being recorded closes as the Glide starts and the record begins again where it ends; a glided stretch records nothing, and a feature in it is melted unseen, never found then or later. The Bore Station's observing ends, and its screen says "No Column in the Bore: melted by the Glide".
- **The Sweep**: a Glide is deaf to it as to a pulse: starting a Glide ends a running Sweep, what it heard handed in, and none starts in a Glide (`start_sweep()` is ignored). At the idle after it a Sweep may run.
- **Pulses**: a pulse sent in a Glide is drowned by the jet: it is sent and counted, and nothing returns (`pulse_sent`'s `drowned`). The Beam's own pulsing counts no ground in a Glide.
- **Link and tunnel**: unchanged; a glided stretch's tunnel is a crawled one's until #125, and `glided_stretches()` marks where.
- **Emergency store, stranding and self-destruct**: the Glide never wears the Head, so its plasma cannot be lost by the Glide; lost by other means (a debug command), the vessel halts with no idle and strands or is brought home as ever. Self-destruct drops out of a Glide and spins the Head up out of its idle, so it runs hot against the rock.
- **Surface**: a climbing Glide ends 20 m below the surface (held there by its reach): breaking the surface at that speed would throw the vessel out, and the crew crawl the rest.
- **The idle and Quiet Ship**: the idle after a Glide is halted and silent like Quiet Ship, but its flag is not set.
  STANDBY reads against the scan's guess of the rock the Glide entered last (or, crossing none, the rock it began in, which ACTIVE was cutting); R, the Shift, swaps it in and spins the Head up, and the Crawl begins as the Head spins up. If Quiet Ship is set, it still holds the Head at idle, the Wobble now felt.
  Quiet Ship set in a Glide drops out of it.
- **The Arm and the ring of Stations**: unchanged.
- **The screens**: Navigation gains a sixth status line (the plot against what the scan shows, or the range left) and a bar down the Course for the Glide, cyan plotted and green running.
  The Drive gains a third line (plotted and the key, why it cannot start, the range left, dropping out, the Head at idle) and a GLIDE power box; Thermal a line that the jet carries the heat away.
  The view leaves a melted Column out of the Column strip; the look and sound are #127's.
- **The cost budget** plays a Glide as its second condition.
