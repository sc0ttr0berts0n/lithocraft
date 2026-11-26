# The scan: the point cloud and Inferred Boundaries

**The point cloud.**
`points()` is bounded: at most `point_capacity()`, the oldest giving way first, and a return within `point_resolution()` of a point an earlier pulse returned replaces it (echoes of one pulse never replace each other).
`_add_point()` finds the points near a return through `_point_cells`, a grid of cubes twice the resolution on a side, looking in only eight cells, and `_send_pulse()` sweeps the replaced and the evicted out once per pulse, so a pulse costs the same however long the dive or however hard the crew mash P.
A point's age is `point_age(point)`, counted on `dive_time()` (seconds simulated this dive, stranded time included); the view fades by it.
Anything that adds points goes through `_add_point()` and the sweep.

**Inferred Boundaries.**
`inferred_boundaries()` is the one query for the Boundaries as the scan suggests them: `BoundaryPatch`es fitted by `BoundaryFit.fit(points)` (`sim/boundary_fit.gd`), a static, plain function of `ScanPoint`s alone that never sees a Medium, the layout or the simulation (`boundary_fit_test.gd` checks its source).
The fit grids the ground into square cells, splits each cell's points into layers at a height gap and fits a plane to each layer with enough points, so a patch's `confidence` rises with how many points support it and how confident they are, and its `returned_at` is its points' (confidence-weighted) mean, so it fades with them (`patch_age(patch)`).
The simulation refits lazily, inside the query, only once `pulses_sent()` has changed, so a view may call it every frame and the fit costs nothing per step.
Any view showing Boundaries as inferred (the point cloud, Navigation's moving map) reads this, never `MediumLayout.boundary_depths()`; `BoundaryPatch.corners()` gives each patch's four world corners.
Hazards, when they come, get a fit of their own beside it.
