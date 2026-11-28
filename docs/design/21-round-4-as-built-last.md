# Round 4, as built, last

The tickets of round 4 (spec #113), as built, continuing 20-round-4-as-built-continued-further.md once it was full.


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
