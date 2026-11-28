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
- **Turns**: a Glide starts only with the Head within 1 degree of the Course and the Drive not overriding; in it, the Course changes nothing and nudges only hold it on its line (#126, below). `glide_refusal()` says why one cannot start.
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


## The Glide flown by hand (#126)

Agent's choices, the developer away ("It is flown by hand, and wear comes from being off its line", 17-glide-and-scan-round-3.md). How it meets the code is `docs/conventions/glide.md`, "Flown by hand (#126)".

- **What pushes it, and how hard.** Three things, each as a sideways slope of the way the vessel runs, worked out per metre along the line so a raised time rate flies the same Glide:
  the melt sheath's own unsteadiness (about a degree at most, changing smoothly over a couple of hundred metres, seeded per Glide so a dive flown the same drifts the same);
  rock harder on one side (felt a hull's radius either side of the Head, pushing toward the softer side: a kick where a folded Boundary crosses the line obliquely);
  and being off the line at all, which pushes further off (a body in its bubble is unstable), capped at the sheath's own push so a long careless Glide runs away linearly, not exponentially.
  Real basis: a supercavitating body is unstable in its cavity and is steered the whole way; a face harder on one side melts slower there and turns the vessel away from it.
- **How the crew corrects: a Drive nudge in a Glide is far finer.** A nudge of the Crawl's 15 degrees would be wild at a Glide's speed, so in a Glide the same keys (Z / X, J / L) turn it a quarter of a degree a press on the ball's own axes, vertical or not (no lean), held until nudged back.
  What the Drive steers for is untouched and no override begins. A nudge is a command: it disengages the Drive's autopilot.
  The glossary avoids "trim" for a Nudge, so it is still a Nudge, its Glide sense added to the term; the Glide's Line is a new term.
- **How wear grows.** Nothing within a metre of the line (the sheath is a little wider than the hull). Past that, the Head's one wear and the hull's one wear (no third) grow per metre glided in proportion to how far past, up to hard against the wall four metres further, beyond which it wears no faster.
  A Head slapped through loses the plasma as a Residual would; a hull slapped through fails as heat's creep would. The hull's sparks and shake play while it slaps (`hull_taking_damage()`).
- **How loosely the autopilot holds.** It does nothing until the Glide is 1.25 m off, then nudges back in proportion to how far past that, not knowing the push: safe but mediocre, it rides just past the slack and wears a little.
  Measured in the test layout (hard rock, 300 m vertical): no hand, the Head wears about 0.054 and the hull 0.027; on the autopilot about 0.014 and 0.007; held, nothing. Over 800 m: no hand 0.35 and 0.18, the autopilot 0.035 and 0.018.
- **The call.** Off the line past the slack the Drive warns, `&"off_glide_line"`, more urgent the harder against the wall; as a warning it drops the time rate (it puts the vessel at risk). On the autopilot it may begin and end as the Glide wanders across the slack; a Glide lasts seconds, so the dropped rate costs little.
- **The ball.** The line to hold is a hollow cyan diamond at where the line is 50 m ahead: on it the Glide rejoins its line, so it shows both the line and the way back; the bottom right corner reads OFF LINE in metres, green within the slack, amber wearing, red half way to hard against the wall.
- **Where it ends.** A Glide still halts at its plotted length measured along its line, and never past what the scan has shown along it; only its offset across the line differs. Halted, the vessel settles along its line again, so the next Glide may start without crawling straight.
- **For #128.** A 300 m Glide left to the Drive's autopilot wears about a hundredth of the Head and less of the hull, and may sound `off_glide_line`; the Checklist-follower test should engage the Drive's autopilot after starting a Glide (starting one disengages it) and acknowledge.
