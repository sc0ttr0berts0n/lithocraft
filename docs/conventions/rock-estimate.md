# The rock beyond a Boundary, as the scan estimates it

What sound can know of the rock (#122): harder or softer, denser or more porous, and never a mineral's name.
Read with `scan.md`, which is at its size.

**What an echo carries.**
`_echoes_along()` gives each echo the contrast across the Boundary it came from, the rock beyond against the rock the ray came through (`DiveSimulation._contrast()`: the signed contrast in acoustic impedance, hardness times solid fraction standing in for impedance, the share of sound reflected being its size), which Boundary it is (`_boundary_seed()`) and which side is below.
`_heard()` turns that into `ScanPoint.contrast`, the rock below the surface against the rock above, as heard at the point's confidence (`Echoes.contrast_heard()`).
So what an echo says of the rock travels on the point, as its strength does; the scan side reads only that, never the layout.
A body that is not a layer (a target, #124) returns its echoes through `_echoes_along()` with a contrast of its own, or NAN for one that says nothing; nothing assumes every echo is a layer's.
Surface control's survey points carry the contrast too, heard as faintly as the survey hears (`start_surveyed()`).

**How wrong it is.**
`Echoes.contrast_heard()` puts the contrast off the truth by a share of it that shrinks with the square of the point's doubt, as STANDBY's guess of the Wobble is off by its confidence (`WobbleGuess`).
Which way it errs is the guess's way for the same Boundary (`WobbleGuess.error_of()`, the first draw of the guess's own seed): where the guess puts the Wobble beyond higher, so the rock harder, the estimate puts it harder too, so the two never disagree on which way they are wrong (`rock_estimate_test.gd`).
The share is under one, so an unsure scan misjudges how much harder or softer, never which way: polarity is the surest thing an echo carries, and a crew must never see "softer" beside a guess that says harder.
A new source of error in the estimate keeps that pairing with the guess, or changes both.

**From points to patches to the Boundary ahead.**
`BoundaryFit.fit()` gives each patch `contrast`, its points' contrasts weighted by their confidence (NAN when none says); `BoundaryPatch.beyond(place)` reads it from a side, turned about from below.
`BoundaryFit.ahead()` returns a Vector3: the distance, the confidence, and the estimate beyond as seen from the origin's side, weighted like the distance.
The look-ahead holds it with its sighting (`LookAhead.rock_ahead()`, `sighting_confidence()`), so `DiveSimulation.rock_ahead()` and `rock_ahead_confidence()` cost nothing and are as sure as the Inferred Boundary ahead; both clear through a crossing as the countdown does.

**Names.**
The scan never names a rock: no point or patch carries a name.
`expected_rocks()` is surface control's expectation, made once in `start_surveyed()` with the survey (the rock below each Boundary and the survey's depth for it, as wrong as the survey), each `confirmed` once the Bore Station's record (`_close_stretch()`) has a stretch of that rock.
A view writes a name only from it, marked as a guess until confirmed (`ScanDisplay.expected_label()`), and `scan_display_test.gd` keeps every other way to a name out of the display's source.

**How it is drawn and said.**
Every candidate view draws, for each patch, a band `ROCK_BAND_PX` deep on the screen on the far side from the Head (`_draw_rock_beyond()`, called from the patch loop of `_draw_scan()`).
It has strokes through it for harder rock and dots for softer, as a geological section draws hard rock and sand, more of them the stronger the contrast (`rock_degree()`, `rock_marks()`), none for much the same.
It is drawn in the points' colours, white as the patch is sure and the legend's grey as it is a guess, faded with age, so it stays inside the colour language and never reads as a caution; seen end-on (the plan) a stroke is a short slant, so it still differs from a dot.
Surface control's names are written at the right of the pane, just into the rock below the Boundary at its surveyed depth, on a backdrop (`_draw_expected()`), shortened to "GRANITE?" where the pane is narrow; the plan shows none, having no depth.
Navigation's sixth status line is `ScanDisplay.rock_label()`: "Beyond: MUCH HARDER, DENSER  71% sure", in the words the bands use (`rock_words()`).
