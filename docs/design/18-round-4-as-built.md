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


## The Beam (#117)

- **Three widths, one energy.**
  Wide is a 110 degree cone, middle 70 degrees (round 3's pulse, unchanged) and narrow 30 degrees; each sends the same 300 rays.
  The same energy over a smaller cone makes each echo stronger as one over the cone's solid angle, so the narrow Beam's echoes are about five times the middle's and the wide's under half; how far an echo is heard grows with the log of that, so in the First dive's sand the Beam reaches about 190 m wide, 230 m middle and 310 m narrow.
  A stronger echo is also a surer point against the vessel's noise, so the narrow Beam's points are cleaner as well as further: the same physics, not a second rule.
  A dive starts on the middle width with the switch off.
- **Its own pulsing is by ground: one pulse per 15 m covered.**
  The spec says "about once per stretch of new ground", and round 2's "steady interval" (16-glide-and-scan.md) is overtaken by it: counted by ground, a halted vessel (Quiet Ship included) sends none, and a faster one pulses more often.
  15 m is one and a half survey stretches, a pulse every several seconds at full power; any pulse, by hand or by itself, starts the count afresh.
  Its pulses are the same pulse as P's, so under way they are as noisy as a hand pulse under way; Quiet Ship stays the clean scan.
- **The width and the switch are settings; a pulse is a reading.**
  By the conventions' rule (a command that changes a held setting disengages its Station's autopilot), B / N and O switch Navigation's autopilot off, as Quiet Ship does; P, and the pulses the switch sends, do not.
- **Keys.** At Navigation: B / N the Beam one width wider / narrower, stopping at each end; O the switch (on its own); P stays one pulse by hand, so the First dive's Checklist reads as before.
- **How the width shows.**
  Every scan view draws the Beam's cone as two faint cyan fans from the Head out to its reach (the vessel's vertical plane and the plane square across it, so the scope and section show one and the plan the other), and writes "BEAM NARROW 30 deg" in the display's lower left; Navigation's status lines gain a fifth, the Beam's width, cone, reach and "pulses as it goes" or "by hand only".
- **The forward scope's ranges.**
  It steps between 60 m, 120 m and 260 m (rings every 10, 25 and 50 m), the nearest that holds the nearest Inferred Boundary ahead along the heading within three quarters of its range, or 260 m with none ahead; it is worked out only when a pulse changes the scan.
  The vessel's heading line is about an eighth of the range, so at 60 m a Boundary 30 m off is drawn well clear of it; the world-up view keeps its one scale, as the spec says.

## The Sweep (#121)

Agent's choices, the developer away, each until the developer rules; the shape (a spiral from the Beam's edge to square across, equal turns, nothing behind, one to three minutes by range, smeared under way) is round 3's.

- **The spiral.**
  It starts at the Beam's half-angle at the moment it begins (15 degrees narrow, 35 middle, 55 wide), so it covers what that Beam does not, and winds out to 90 degrees in 20 turns of 60 rays each, its angle off the axis rising evenly.
  So a turn's rays are spread round a wider circle the further out it is, and the points per unit of solid angle go as one over the sine of the angle: about twice as thick at 30 degrees as at 80.
  Its axis is the way the Head pointed as it began.
- **Timings follow range, by the time sound takes.**
  Each ray listens for its echo for as long as sound takes to go out to the range and back, reckoned at 4 km/s (real rock carries sound at about 2 to 6 km/s), so 1200 rays take 60 s at 100 m, 120 s at 200 m and 180 s at 300 m: the spec's one to three minutes, and a longer range takes longer because the scanner must wait longer for each echo, not by a rule of its own.
  The three ranges are 100, 200 and 300 m, 200 m when a dive starts; the range is chosen before a Sweep starts and cannot change while one runs.
- **Its beam.**
  One narrow beam of 5 degrees half-angle, heard at that beam's gain by the same rule as the Beam's widths (the same energy in a smaller cone is louder), so it hears out to its range in the First dive's sand and its points are surer than the Beam's at the same range.
  How an echo fades and is heard is now one class, `Echoes`, both tools handing it their gain, rather than the Sweep borrowing the Beam's.
  It draws no more power than the Beam: Navigation's draw is unchanged.
- **The smear is the true one: a picture drawn as if the scanner stood still.**
  Each ray leaves from where the Head then is, along the spiral turned with the vessel as it then points, and its echo is placed as if heard from where the Sweep began about its first axis.
  So diving toward a Boundary its echoes are drawn short of it, by half the way the vessel went during the Sweep on average; a turn smears it sideways; halted at Quiet Ship nothing differs and the picture is clean (and quiet, the points surer).
  Quiet Ship is not required to start one.
- **Points as it goes.**
  The echoes are handed into the one cloud a batch each second of the Sweep's time and as it ends, each batch counted as one change of the cloud (`scan_revision()`, which the views and the Boundary fit now follow in place of `pulses_sent()`), so the picture builds several times a turn while the fit runs at most once a second.
  A Sweep's points all carry one number (-1 for the dive's first, counting down), so they never replace each other but do replace the Beam's, and the cloud's capacity holds as for pulses.
  The Beam and the Sweep may run together.
- **Readings and settings, and keys.**
  Starting and stopping a Sweep are readings and leave Navigation's autopilot engaged; its range is a setting and disengages it, as the Beam's width does.
  At Navigation V starts a Sweep or cuts the running one short (what it heard stays), G / T set the next one's range shorter / longer: free letters at Navigation, T and G already meaning more and less at the Drive.
  Stranded, a Sweep ends and none may start.
- **How it shows.**
  Every scan view draws a running Sweep in green (the colour language's engaged and working), as the Beam's cone is drawn in the same two planes: a faint band each side of its axis from where it started to where its spiral has reached, out to its range, from where it began, and a strong leading edge that swings outward as it goes.
  Over the Beam's label in the lower left, "SWEEP 200 m  45%  1:06 left" while one runs, else "SWEEP 200 m  2:00  [V] start"; both labels sit on a dark backdrop so points never hide them.
  Navigation's status lines are unchanged, keeping the display's size.
