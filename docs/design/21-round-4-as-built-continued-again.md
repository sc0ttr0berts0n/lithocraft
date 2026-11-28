# Round 4, as built, continued again

The tickets of round 4 (spec #113), as built, continuing 20-round-4-as-built-continued-further.md once it was full.


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
