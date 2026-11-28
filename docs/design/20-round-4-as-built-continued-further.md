# Round 4, as built, continued further

The tickets of round 4 (spec #113), as built, continuing 19-round-4-as-built-continued.md once it was full.


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
- **The screens**: Navigation gains a status line after the rock's (the plot against what the scan shows, or the range left) and a bar down the Course for the Glide, cyan plotted and green running.
  The Drive gains a third line (plotted and the key, why it cannot start, the range left, dropping out, the Head at idle) and a GLIDE power box; Thermal a line that the jet carries the heat away.
  The view leaves a melted Column out of the Column strip; the look and sound are #127's.
- **The cost budget** plays a Glide as its second condition.

## Targets (#124; agent's choices, the developer away)

- **One kind: a lens of hematite breccia in the granite.**
  Granite shattered and cemented by iron oxide, with a little copper sulphide; the survey sees a dense, magnetic body and cannot say what it is.
  Real basis: Olympic Dam, hosted in granite under cover, was found in 1975 by boring into a coincident gravity and magnetic high; what it was became known only from the rock that came up.
  It is stiffer than granite (acoustic impedance about 1.6 times: some 4 g/cc at 6 km/s against 2.65 at 5.5), so its surface returns echoes, weaker than the Boundaries'.
- **Its size: a flattened lens 18 m across and 10 m tall.**
  Wider than the Column, so a cut through it fills the Column all round; about as tall as the vessel is long, so a crawl through it takes the Bore Station's time to record.
- **A body in its host, not a Medium.**
  Cutting through it leaves the Wobble the granite's and raises no Boundary: the spec makes it a feature of interest of its own kind, and a Medium of its own would ask a Shift into and out of every target.
  Its points still make Inferred Boundary patches over its top, as any reflector's do, and carry the contrast #122 gave echoes: going in it is stiffer than the granite, so the rock beyond its top reads harder; coming out the sign turns.
- **The first error: a share of its depth, wider in depth than across.**
  The Orders' place is an ellipsoid with half-extents of 4% of the depth across the ground and 6% in depth (at least 15 m), the true middle within half of each: at 780 m, 31 m across and 47 m deep against a body 9 m and 5 m.
  Real basis: a gravity or magnetic anomaly places a buried body across the ground better than in depth, both to a share of the depth (the half-width rule); tuned tighter for play.
- **How it narrows: round the points, as sure as they are.**
  The vessel's own points inside the Orders' place are taken as the body's near surface; their middle is where it is, their widest spread how wide, and the body is taken as about as deep as it is wide, plus how far its points may stray.
  Few and faint points barely move it; it never grows past the Orders' place, and it never sees the body, so a reflector that is not the target would pull it too: honest, never snapped to the truth.
- **What it pays: 400, several features' worth, as a line of its own** ("Targets identified: A, worth 400"), once its record is up the link or brought home.
- **Found when the Head cuts into it**, placed where it met it and as long as a straight cut through it; a target passed by, glided through (melted with the Column, #123), or crawled through and not recorded in full, achieves nothing and pays nothing.
  Since it is found only by the Column, a Glide (#123), which has none, never finds it.
- **Drawn as a fuzzy cyan region** in every scan view, cyan being what the crew aims for: the region's outline filled faintly at four sizes, so it is densest in its middle, with a faint rim and "TARGET A" beside it.
- **The Prospecting drill, third on the start menu.**
  Nothing placed a target before #128 reworks the First dive, so the drill gives the screenshots their state and the developer the loop to play now, without the Glide: halted at Quiet Ship 60 m into the granite, target A 120 m below and 12 m east, off the straight line down.
  Its Checklist: narrow the region, aim the Beam, plot the Course one step off straight down, crawl in on the Drive's autopilot (whose gentle turns reach it from there), observe and record it.
  The Sweep begins at the Beam's edge, so a target nearly ahead is the Beam's to narrow and one off to the side the Sweep's; the drill's lies inside the Beam's cone.
- **For #128.** Place the body with `MediumLayout.first_dive().with_targets([TargetBody.hematite_breccia(&"A", centre)])` in the Scenario, name it in the Orders with `Scenario.identify_target(&"A")`, keep `start_surveyed()` in `prepare`, and tick steps on `Scenario.target_narrowed()`, `target_in_column()`, `observing_target()` and `target_identified()`.
  Keep its Orders' place clear of the Boundaries' folds; reaching it on the Drive's autopilot from a Course plotted in 15-degree steps needs a long approach, which is the Glide's.
