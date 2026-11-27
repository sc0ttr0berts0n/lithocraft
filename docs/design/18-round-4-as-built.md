# Round 4, as built

The tickets of round 4 (spec #113), as built, continuing 17-glide-and-scan-round-3.md, which had reached its size.

- **The attitude ball, as built (#119; agent's choices, the developer away).**
  Kerbal's navball is the reference for how such a ball works (a sphere marked in pitch and heading, read through a fixed mark, with markers for targets), not for its look: it is drawn flat in the Station screens' colour language, the surface's blue above the horizon and the rock's brown below, in the attitude's old place.
  Up on the ball is the surface's way along the Head's own meridian, as an aircraft's ball with no bank: the Lithocraft does not roll, so nothing else could be up, and it keeps the flat display's rule that steeper lies lower.
  Straight down the Head's last heading points up from the pole; it is continuous through vertical, so the ball has no dead spot, and a tilt toward the lean slides the pole down the lean's meridian.
  It is drawn as the crew would see a ball (the half facing them, squeezed toward the rim); a mark behind it is pinned to the rim on its side, as a tape pins a bug.
  The lean is an arrow from the pole along its meridian, with LEAN 030 in a corner; the pitch, the Course's pitch and the lean are corner figures, and the bottom right corner and one more marker are left for the Glide's line (#126).
  The deviation keeps CourseDeviation's words, "OFF COURSE" over them on a row of their own, so the longest reads whole (#133 found the flat display's cut off); the foot says FOLLOWS THE COURSE in green otherwise.
  The flat display's chevrons at the Course's pitch went with the ladder: the cross on the ball and the COURSE figure say the same.
- **Surface control's survey, as built (#118; agent's choices, the developer away).**
  The Scenario decides: its `prepare` calls `start_surveyed()`, and the simulation, which owns the layout, makes the survey's points then, once; the scan side sees only points marked as the survey's.
  All three Scenarios start surveyed, since all three are on the First dive's ground and a survey belongs to the place, not the lesson; the Shift drill keeps its opening pulse (the drill is a pretune against a good scan), and Stranded in the granite, once lit and pointed up, has a faint guess of the Boundary above before any pulse.
  Coverage: every Boundary of the layout, sounded every 8 m (half the fit's cell, so every cell of ground has a patch) over a square 256 m on a side about where the Head begins, the ground the First dive cuts straight down and the drills start in: 2048 points on the First dive's layout. The First dive's turn for home (250 m turning radius) climbs outside it.
  How wrong: each Boundary flat at its mean depth (the folds, 6 m either side, are not seen; from the surface gentle folds blur away) and off by 1% to 2% of its depth, one way, the same all across, each sounding scattered about a metre.
  Real basis: a seismic survey turns echo times into depths through a guessed speed of sound, good to a few percent, and averages over a footprint wider than these folds.
  How sure: each sounding 0.05, under any ordinary echo (the First dive's under-way echoes ran 0.1 to 0.3, Quiet Ship's 0.5 to 0.7), so its patches are about 0.05 against one under-way pulse's 0.13 to 0.38, and STANDBY pretuned to its guess alone Shifts outside the Band, where one pretuned after a clean scan Shifts inside.
  How replaced: a sounding gives way once the vessel's own echoes within 8 m across and 25 m up or down sum to a confidence of 0.5, so a clean pulse replaces the survey under its cone and a faint echo here and there leaves it standing; it is held apart from the cloud's capacity, so a long dive's own points never give way to it and it never goes by age.
  How it looks: in all three scan views a hollow square of the legend's grey, 5 px, at 0.45 opacity, never filled; its patches are drawn as any patch, as faint as they are.
  The Checklist follower still finishes the First dive (Head worn 7.6%, paid 4833): "Pulse until Navigation shows the Boundary ahead" for the sandstone was already ticked by the sand's pulses, and the granite's now ticks at once on the survey's faint guess, so the granite is pretuned against the survey and the Shift finished by tuning ACTIVE, until #128 reworks the Checklist.
  The Boundary call (#115) still comes as soon as it is announced for a crew that has done nothing: STANDBY begins on the Wobble of the rock it is in, which the faint guess of the rock beyond does not put inside the Band.
