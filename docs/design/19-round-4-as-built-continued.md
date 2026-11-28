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

## Targets (#124; agent's choices, the developer away)

- **One kind: a lens of hematite breccia in the granite.**
  Granite shattered and cemented by iron oxide, with a little copper sulphide; the survey sees a dense, magnetic body and cannot say what it is.
  Real basis: Olympic Dam, hosted in granite under cover, was found in 1975 by boring into a coincident gravity and magnetic high; what it was became known only from the rock that came up.
  It is stiffer than granite (acoustic impedance about 1.6 times: some 4 g/cc at 6 km/s against 2.65 at 5.5), so its surface returns echoes, weaker than the Boundaries'.
- **Its size: a flattened lens 18 m across and 10 m tall.**
  Wider than the Column, so a cut through it fills the Column all round; about as tall as the vessel is long, so a crawl through it takes the Bore Station's time to record.
- **A body in its host, not a Medium.**
  Cutting through it leaves the Wobble the granite's and raises no Boundary: the spec makes it a feature of interest of its own kind, and a Medium of its own would ask a Shift into and out of every target.
  Its points still make Inferred Boundary patches over its top, as any reflector's do; telling a body's echoes from a layer's is #122's.
- **The first error: a share of its depth, wider in depth than across.**
  The Orders' place is an ellipsoid with half-extents of 4% of the depth across the ground and 6% in depth (at least 15 m), the true middle within half of each: at 780 m, 31 m across and 47 m deep against a body 9 m and 5 m.
  Real basis: a gravity or magnetic anomaly places a buried body across the ground better than in depth, both to a share of the depth (the half-width rule); tuned tighter for play.
- **How it narrows: round the points, as sure as they are.**
  The vessel's own points inside the Orders' place are taken as the body's near surface; their middle is where it is, their widest spread how wide, and the body is taken as about as deep as it is wide, plus how far its points may stray.
  Few and faint points barely move it; it never grows past the Orders' place, and it never sees the body, so a reflector that is not the target would pull it too: honest, never snapped to the truth.
- **What it pays: 400, several features' worth, as a line of its own** ("Targets identified: A, worth 400"), once its record is up the link or brought home.
- **Found when the Head cuts into it**, placed where it met it and as long as a straight cut through it; a target passed by, or crawled through and not recorded in full, achieves nothing and pays nothing.
  Since it is found only by the Column, a Glide (#123), which has none, never finds it.
- **Drawn as a fuzzy cyan region** in every scan view, cyan being what the crew aims for: the region's outline filled faintly at four sizes, so it is densest in its middle, with a faint rim and "TARGET A" beside it.
- **The Prospecting drill, third on the start menu.**
  Nothing placed a target before #128 reworks the First dive, so the drill gives the screenshots their state and the developer the loop to play now, without the Glide: halted at Quiet Ship 60 m into the granite, target A 120 m below and 12 m east, off the straight line down.
  Its Checklist: narrow the region, aim the Beam, plot the Course one step off straight down, crawl in on the Drive's autopilot (whose gentle turns reach it from there), observe and record it.
  The Sweep begins at the Beam's edge, so a target nearly ahead is the Beam's to narrow and one off to the side the Sweep's; the drill's lies inside the Beam's cone.
- **For #128.** Place the body with `MediumLayout.first_dive().with_targets([TargetBody.hematite_breccia(&"A", centre)])` in the Scenario, name it in the Orders with `Scenario.identify_target(&"A")`, keep `start_surveyed()` in `prepare`, and tick steps on `Scenario.target_narrowed()`, `target_in_column()`, `observing_target()` and `target_identified()`.
  Keep its Orders' place clear of the Boundaries' folds; reaching it on the Drive's autopilot from a Course plotted in 15-degree steps needs a long approach, which is the Glide's.
