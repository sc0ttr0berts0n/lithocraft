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


## The Glide's tunnel (#125)

Agent's choices, the developer away. How it meets the code is `docs/conventions/glide.md`, "The tunnel and the link (#125)".

- **One rule for both ways of moving.** Each metre of tunnel the Tail leaves is sealed if the rock is dense, whoever cut it (the melt has to go somewhere, ADR 0001), and open if porous: glass where the Head crawled, rough where it glided. The wall is what the Head made of the rock as it passed, so the last vessel length of a glided stretch is rough even though the Tail leaves it crawling.
  So the seal's call and event, the sealed metres, the rescue and the stranding rules are the Crawl's, unchanged; a rough open tunnel is open to a rescue as a glass one is.
- **The light, how the loss adds.** The link up an open tunnel carries the glass rate times the share of light that arrives: each separate run of rough wall passes 90% of the light reaching it, and along rough wall the light falls by a factor of e every 4 km.
  Real basis: a rough-walled light guide loses light where the smooth guide gives way to it and along its length. So one Glide of a few hundred metres leaves about 80 to 87% (the developer's "80% quality vs 100% glass perfection"), a longer one less, and each Glide more a little less again: two of 60 m are worse than one of 120 m.
  Glides with no glass between them are one run. Light is the whole of the open link however dim it gets; it never falls back to sound while the tunnel is open (a dive would need tens of Glides to dim it to sound's trickle).
- **How much slower** follows from that: about a tenth slower after a short Glide, a fifth after one of 500 m; the rate falls as the Tail leaves the glided stretch, through the Glide and the vessel length after it.
- **The call in one step.** At the top time rate a Glide can carry the Tail into dense rock within the step the Head entered it; the Bore Station's "tunnel about to seal" is then still made, once, at its most urgent, and drops the time rate as any warning does.
- **The screen.** The Bore Station's tunnel panel, which showed the link, says why: "Link fast, glass tunnel  2.00 m/s", "Link 87%, 1 rough stretch  1.74 m/s", or "Link slow, through rock". The header stays TUNNEL OPEN in green: a rough tunnel is open, only dimmer. The stations recipe has the tile "Bore Station, after a Glide".
- **For the look (#127).** `tunnel_walls()` lists the tunnel behind as pieces of glass, rough or sealed wall by path distance; the view draws a glided tunnel from it.
- **A Glide home up the First dive's climb (#128).** The way down already sealed the tunnel in the granite, so the link is sound all the way home, glided or crawled, and the rough sandstone and sand change nothing for it. A rescue counts the glided climb as the crawled one: sealed through the granite, open through the sandstone and sand.
