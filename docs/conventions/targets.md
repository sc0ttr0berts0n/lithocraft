# Targets

A target (`GLOSSARY.md`) is a body in the rock that surface control's survey has seen and cannot identify, and a place the Orders send the Lithocraft to (#124).

**The body is the layout's truth.**
`TargetBody` (`sim/target_body.gd`) is plain data: a `label` (`&"A"`), the `kind` it turns out to be in the Column, a `centre` and `half_size` in the world frame (an ellipsoid along the world's axes), a `stiffness` on the Media's echo scale (hardness times solid fraction) and a `worth`.
A Scenario places it in its layout with `MediumLayout.with_targets([...])` (read back with `targets()`), never in `MediumLayout.first_dive()` itself; the first slice's one kind is `TargetBody.hematite_breccia(label, centre)`.
It is a body in its host rock, not a Medium: cutting through it leaves the Wobble the host's, and no Boundary is raised.
`crossings(from, to)` is where a straight piece passes in and out of it, and `chord(place, direction)` how long a straight cut through it is.

**The Orders name it.**
`Scenario.identify_target(label)` is the goal: its `target` is the label, its text names it ("Find target A, crawl through it and record it in the Column"), and it is achieved once the target is identified.
The Scenario's `prepare` calls `start_surveyed()`, the one place the survey is made from the layout: for each target inside the survey's square it makes the Orders' fuzzy place, a `TargetRegion` about the body far wider than it.
Its half-extents are `_TARGET_ACROSS_ERROR` and `_TARGET_DEPTH_ERROR`, shares of the depth, at least `_TARGET_LEAST_ERROR_M`; its middle is off the body's by up to half of that, seeded with the survey.
Without the survey the Orders have no place to give: `target_regions()` is empty.
Place a target's body so that its whole fuzzy place lies clear of every Boundary's folds: the region takes every point inside it as the body's (below).
Conditions for steps and messages beside the goal: `Scenario.target_identified()`, `target_narrowed()` (the vessel's own points have narrowed it), `target_in_column()` and `observing_target()`.

**The scan learns of it from the Orders' place and from points alone.**
`TargetRegion` (`sim/target_region.gd`) is scan side (`test/convention_test.gd`'s `SCAN_SIDE`; `TargetBody` is among the names it may not use).
`TargetRegion.narrowed(report, points)` takes the vessel's own points inside the report as the body's near surface: their confidence-weighted middle is where it is, their widest spread how wide it is, the body taken as about as deep as it is wide, plus how far the points may stray by their range and doubt; the fewer and fainter, the more the report still counts, and it never grows past the report.
It never sees the body, so points from anything else inside the report narrow it just the same (`target_region_test.gd` puts points where no body is).
`target_regions()` narrows each report against `points()` only once `scan_revision()` has changed, so a view may call it every frame; `narrowed_targets()` lists the labels whose region the vessel's points have narrowed.

**Every tool hears it.**
`_echoes_along()` asks `_reflectors_along()`, which merges the layout's `meets()` with each body's `crossings()`, nearest first; a body's surface reflects by `_target_contrast()`, the contrast of its stiffness with the host's: positive going in, the sign turned coming out, so its echoes carry a contrast as a Boundary's do (#122) and the rock beyond its top reads harder.
So the Beam, an aimed pulse and the Sweep all return points off it, and the Inferred Boundaries fit its points as they fit any (a patch over its top is as true as the scan can be).

**Identified in the Column.**
`_find_targets()` runs in `_follow_the_head()` beside `_find_features()`: when a step's piece of path passes into a body, the body becomes a `ColumnFeature` of its own kind, its `target` the label, placed where the Head met it and as long as a straight cut through it from there; a body passed by is never found.
A Glide, having no Column, finds none: `_glided()` (#123) never calls it, so a body glided through melts unseen (`target_test`).
A Glide that ends inside a body leaves it unfound; the first Crawl step out of it finds it where that step ends, as long as the rest of it, so crawling out through it identifies it and the glided part is never seen (#159, the orchestrator's ruling, awaiting the developer's word).
From then it is a feature of interest like any: observed (`set_observed_feature()`), recorded at `_recording_quality()`, called for, sent up the link as a `SurveyStretch.feature_record()` whose `target` is the label.
`identified_targets()` lists the labels whose feature is recorded in full; the goal reads it.
`&"paid"` carries `targets` (the labels) and `target_worth` as a line of its own, not among `features`; the outcome's breakdown writes "Targets identified: A, worth ...".

**How it is drawn.**
Every scan view draws each region through `ScanDisplay._draw_targets()` from `_draw_scan()`, under the patches and points: `region_outline()` is the convex hull of the ellipsoid sampled and put through the view's own `place`, drawn at each of `TARGET_SHARES` of its size, filled faintly in cyan (what the crew aims for), so it builds toward its middle, with a faint rim and "TARGET A" beside it.
The Bore Station's screen names it "Target A: Hematite Breccia"; `FeatureLook.LOOKS` has its look (wider than the Column, so it fills it all round).
No key was added: the Beam's aim, the Sweep and the Course's keys prospect for it.

**The Prospecting drill.**
`Scenario.prospecting_drill()`, fourth on the start menu: halted at Quiet Ship in the granite of the First dive's ground with target A below and east, off the straight line down and on the line one pitch step off it (#161); its Checklist asks to narrow the region, aim the Beam, plot the Course one step off straight down toward it, crawl into it on the Drive's autopilot and record it.
`prospecting_drill_test.gd` finishes it that way, and a dive straight down passes the target by.
The recipes show it: `navigation.txt`'s "target before / after prospecting", `column.txt`'s "target A" and `checklist.txt`'s "prospecting drill".

**The First dive's target.**
The First dive's Orders name target A too (#128): a hematite breccia in the granite on the line straight down, so the crew finds it by crawling on, halts, Sweeps and crawls through it; `first_dive_and_glide_drill_test.gd` holds where it lies.
