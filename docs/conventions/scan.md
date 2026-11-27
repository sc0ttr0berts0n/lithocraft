# The scan: the point cloud and Inferred Boundaries

**The point cloud.**
`points()` is bounded: at most `point_capacity()`, the oldest giving way first, and a return within `point_resolution()` of a point an earlier pulse returned replaces it (echoes of one pulse never replace each other).
`_add_point()` finds the points near a return through `_point_cells`, a grid of cubes twice the resolution on a side, looking in only eight cells, and `_send_pulse()` sweeps the replaced and the evicted out once per pulse, so a pulse costs the same however long the dive or however hard the crew mash P.
A point's age is `point_age(point)`, counted on `dive_time()` (seconds simulated this dive, stranded time included); the view fades by it.
Anything that adds points goes through `_add_point()` and the sweep.
An echo comes from where its ray meets a Boundary's surface (`_echoes_along()`, through `MediumLayout.meets()`), so on a wavy Boundary the points lie on its folds; a new tool that sounds the rock (the Sweep, an aimed Beam) casts its rays the same way.

**The Beam.**
A pulse is the Beam's: `Beam` (`sim/beam.gd`, a subsystem owned as `_beam`) holds its width (`set_beam_width()`, one of `BEAM_WIDTHS`: wide, middle, narrow), its switch (`set_beam_pulsing()`) and the ground covered since its last pulse, and knows nothing of the layout.
All three widths send the same rays with the same energy, so `Beam.gain()` goes as one over the cone's solid angle and a narrower Beam's echoes are stronger and heard from further (`beam_reach()`); its noise is the vessel's, as a hand pulse's is.
`_send_pulse()` casts `Beam.rays(axis, random)` through `_echoes_along()`, which fades each echo by `Beam.fading()` and hears it by `Beam.strength()`; the axis is `heading()` today, and an aimed Beam (#120) hands it another axis, nothing else.
With the switch on, `_step()` hands the Beam the ground covered (`Beam.covered()`), and it pulses by itself once per stretch of it: by ground, never by the clock, so a halted vessel (Quiet Ship included) sends none.
Every pulse, by hand or by itself, raises `&"pulse_sent"` with its `width` and `by_itself`, goes through `_add_point()` and the sweep, and costs the same at every width.
A new tool that sounds the rock (the Sweep) is a class of its own beside `Beam` that hands its rays to the same `_echoes_along()`.

**Drawing the scan.**
Navigation's scan display (`ScanDisplay`) draws the cloud as one of three candidate views (see `docs/conventions/screen-navigation.md`, "Navigation's point cloud").
Every view is a flat drawing through one static function from a place's offset from the Head to its place on the screen (`scope_place()`, `plan_place()`, `section_place()`, `world_up_place()`: metres, x right, y down), and `_draw_scan()` draws the same things through whichever it is given.
A mark every candidate must show goes in `_draw_scan()` (the Beam's cone, `_draw_beam()`: two faint cyan fans to `beam_reach()`) or, for words, `_draw_over()` (the caption, and `beam_label()` in the lower left); a view's own scale marks go in its `_draw_*_marks()`.
The forward scope's range steps between `SCOPE_RANGES_M` (`ScanDisplay.scope_range()` of `BoundaryFit.ahead()` along the heading), worked out only when `pulses_sent()` changes, so it never zooms between pulses.
No view may read a clock or the layout (`scan_display_test.gd` checks the source): a place is a function of the simulation's state alone, so a view turns only as the vessel does.
The points and patches are fetched only when `pulses_sent()` changes (never `points()` each frame); their fade is worked out at each redraw.
A point is white as it is certain, the legend's grey as it is a guess, larger the surer, and never fades out altogether; a patch is its outline, its face filled faintly unless edge-on.

**Inferred Boundaries.**
`inferred_boundaries()` is the one query for the Boundaries as the scan suggests them: `BoundaryPatch`es fitted by `BoundaryFit.fit(points)` (`sim/boundary_fit.gd`), a static, plain function of `ScanPoint`s alone that never sees a Medium, the layout or the simulation (`boundary_fit_test.gd` checks its source).
The fit grids the ground into square cells, splits each cell's points into layers at a height gap and fits a plane to each layer with enough points, so a patch's `confidence` rises with how many points support it and how confident they are, and its `returned_at` is its points' (confidence-weighted) mean, so it fades with them (`patch_age(patch)`).
The simulation refits lazily, inside the query, only once `pulses_sent()` has changed, so a view may call it every frame and the fit costs nothing per step.
Any view showing Boundaries as inferred (the point cloud, Navigation's moving map) reads this, never `MediumLayout.boundary_depths()`; `BoundaryPatch.corners()` gives each patch's four world corners.
A test enforces it: `test_scan_side_code_never_names_the_layout` (`test/convention_test.gd`) keeps the list of scan-side files (`SCAN_SIDE`) and fails when one names the layout (`MediumLayout`, `_layout`, `medium_at`, `boundary_depth`, `next_meet`).
It also fails when a file in `sim/` or `view/` that takes scan points or patches (`ScanPoint`, `BoundaryPatch`, `BoundaryFit`, `points()`, `inferred_boundaries()`) is not on the list.
A new view or subsystem that reads the scan is added to `SCAN_SIDE`; only `DiveSimulation`, which owns the layout and makes the points from it, is excused (`SCAN_AND_LAYOUT`).
`BoundaryFit.ahead(patches, origin, direction)` is the one place the Inferred Boundary ahead of the Head is found: the distance along a line to the patches it meets and their confidence, from patches alone.
STANDBY's guess of the Wobble ahead and the Boundary countdown read it (see `plasma-and-shift.md`); anything else that asks "how far to the Boundary, as far as the scan knows" does too.
Hazards, when they come, get a fit of their own beside it.

**The projected path.**
`projected_path()` is the one query for where this turn takes the vessel: world places (the frame of `head_position()` and `points()`), the Head's first, joined by straight pieces, through the turn and one straight stretch beyond; any view that shows it reads this and draws it in `StationTheme.PROJECTED_PATH_COLOUR`.
It lives in `ProjectedPath` (`sim/projected_path.gd`, a subsystem with no state): `ProjectedPath.ahead()` is the turning rule itself (`ProjectedPath.turned()`, which a step's `_steer()` also runs) run forward, so a change to how the vessel turns goes there and the projection follows.
The simulation hands it the Head as it is (`_turning()`), what the Drive steers for, the steering effort and `_speed_while_steering` to ask the speed by; when the path is only the Head's place (stopped, stranded, the dive over) stays the simulation's to decide.
It holds the Drive's power setting, the Reactor's supply, the steering effort, what the Drive steers for and the Medium the Head is in, and knows nothing of the rock ahead: only the vessel's own state, never the layout.
It ends at the surface on a climb, is cut short (no straight stretch) for a turn too wide to finish, and is the Head's place alone while the vessel is stopped or the dive is over.
It steps by distance (five metres a step, whatever the speed), so a call costs at most a few hundred turning steps and no more as the vessel slows; a view still calls it a few times a second, never every frame (`ScanDisplay.PROJECTED_PATH_FRAMES`, the moving map's `REDRAW_S`).
With no steering at all it is one straight stretch the way the Head points, since the vessel never comes round.
A step's bend is that of its mean steering, so a test's one-second steps and the game's sixtieths cut the same arc.
