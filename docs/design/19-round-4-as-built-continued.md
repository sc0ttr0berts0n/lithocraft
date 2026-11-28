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

## The rock beyond a Boundary (#122; agent's choices, the developer away)

The developer's question: "with all of the pulsing, there is no real visual or indication of rock type."
The answer as built, each choice until the developer rules.

- **One number, read two ways.**
  An echo's polarity and strength give one thing, the contrast in acoustic impedance across the Boundary; the estimate carries that and nothing else, the rock beyond against the rock before, from -1 to 1.
  The crew reads it as "harder, denser" or "softer, more porous" together: sound cannot pull hardness apart from porosity, and in the layouts built so far the stiffer rock is always the less open one.
  Its size gives a degree: "A LITTLE" under 0.15, "MUCH" from 0.4, "MUCH THE SAME" under 0.05; the First dive's Boundaries both read "MUCH HARDER, DENSER" going down (true contrasts about 0.54 and 0.42).
- **Wrong in how much, never which way.**
  Each echo is off the truth by a share of its contrast that shrinks with the square of its doubt, up to 60% with no confidence, and errs the way STANDBY's guess errs for the same Boundary.
  So an unsure scan can call the rock beyond much harder when it is a little harder, or the reverse, but never softer when it is harder: that would put "softer ahead" beside a guess whose Wobble is higher than the rock's now.
  Real basis: polarity is the surest thing an echo carries; its strength is known only as well as the losses on the way, which a noisy echo tells worse.
  The error follows each echo's own confidence, not how many echoes there are: a pile of noisy echoes under way stays as far out as each, and a halted, quiet scan is how to read the rock well.
- **Drawn as a geological section draws it.**
  In all three views, a band 16 px deep on the far side of each patch from the Head: strokes through it for harder rock, dots for softer (hard rock and sand in a section's convention), 3, 5 or 7 marks by degree, in the points' colours (white sure, grey a guess) so it reads as no caution.
  A fixed depth on the screen, not in metres, so it reads at every range; on the plan, looking straight down, a stroke is a short slant against dots.
- **Navigation's words.**
  A sixth status line, "Beyond: MUCH HARDER, DENSER  71% sure", or "Beyond: no Boundary ahead in the scan"; a line over the picture was tried first, and the display is too narrow to hold it beside the caption.
- **Names only as surface control's.**
  The survey names the rock below each Boundary it surveyed, at the survey's depth for it; the views write "GRANITE EXPECTED" (or "GRANITE?" where the pane is narrow) in grey at the pane's right just under that depth, and "GRANITE" in white once the Bore Station's record has a stretch of it.
  The depth is where the name is written rather than a figure beside it, so the words fit the scan views at their size.
