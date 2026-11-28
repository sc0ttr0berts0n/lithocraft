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
