# The Inferred Boundary fit, tested on points alone: plain ScanPoints in,
# BoundaryPatches out, no simulation and no layout. Assert relationships,
# never tuned constants (ADR 0001).
extends GdUnitTestSuite


## Test values only: points over a square of ground `across` metres on a side
## centred on the origin, `spacing` apart, at height y = `height` plus
## `slope_x` metres per metre eastward, each nudged a little (deterministic)
## so they are not perfectly flat.
func _sheet(height: float, across := 60.0, spacing := 4.0, confidence := 0.6,
		returned_at := 0.0, slope_x := 0.0) -> Array[ScanPoint]:
	var points: Array[ScanPoint] = []
	var half := across * 0.5
	var i := 0
	var x := -half
	while x <= half:
		var z := -half
		while z <= half:
			var wobble := sin(float(i) * 12.9898) * 0.3
			points.append(ScanPoint.new(Vector3(x, height + slope_x * x + wobble, z),
					confidence, 60.0, 0, returned_at))
			i += 1
			z += spacing
		x += spacing
	return points


func _mean_confidence(patches: Array[BoundaryPatch]) -> float:
	var total := 0.0
	for patch in patches:
		total += patch.confidence
	return total / maxf(patches.size(), 1)


func _mean_support(patches: Array[BoundaryPatch]) -> float:
	var total := 0.0
	for patch in patches:
		total += patch.support
	return total / maxf(patches.size(), 1)


func test_with_no_points_there_is_no_surface() -> void:
	assert_int(BoundaryFit.fit([] as Array[ScanPoint]).size()).is_equal(0)


func test_one_lone_point_is_not_a_surface() -> void:
	var lone: Array[ScanPoint] = [ScanPoint.new(Vector3(0, -60, 0), 1.0, 60.0, 0, 0.0)]
	assert_int(BoundaryFit.fit(lone).size()).is_equal(0)


func test_the_surface_lies_where_the_points_are() -> void:
	var patches := BoundaryFit.fit(_sheet(-60.0))

	assert_int(patches.size()).is_greater(0)
	for patch in patches:
		assert_float(patch.centre.y).is_between(-61.0, -59.0)
		# Level points make a level surface.
		assert_float(patch.normal.dot(Vector3.UP)).is_greater(0.99)


func test_the_patches_cover_the_points_and_no_further() -> void:
	var patches := BoundaryFit.fit(_sheet(-60.0, 60.0))

	assert_int(patches.size()).is_greater(0)
	for patch in patches:
		assert_int(patch.corners().size()).is_equal(4)
		for corner in patch.corners():
			assert_float(absf(corner.x)).is_less_equal(30.001)
			assert_float(absf(corner.z)).is_less_equal(30.001)


func test_more_supporting_points_give_higher_confidence() -> void:
	var sparse := BoundaryFit.fit(_sheet(-60.0, 60.0, 6.0))
	var dense := BoundaryFit.fit(_sheet(-60.0, 60.0, 3.0))

	assert_float(_mean_support(dense)).is_greater(_mean_support(sparse))
	assert_float(_mean_confidence(dense)).is_greater(_mean_confidence(sparse))
	for patch in dense:
		assert_float(patch.confidence).is_between(0.0, 1.0)


func test_more_confident_points_give_higher_confidence() -> void:
	var doubtful := BoundaryFit.fit(_sheet(-60.0, 60.0, 4.0, 0.2))
	var sure := BoundaryFit.fit(_sheet(-60.0, 60.0, 4.0, 0.9))

	assert_float(_mean_confidence(sure)).is_greater(_mean_confidence(doubtful))


func test_two_boundaries_make_two_surfaces_and_nothing_between() -> void:
	var points := _sheet(-40.0)
	points.append_array(_sheet(-90.0))

	var patches := BoundaryFit.fit(points)

	var upper := 0
	var lower := 0
	for patch in patches:
		if absf(patch.centre.y + 40.0) < 1.0:
			upper += 1
		elif absf(patch.centre.y + 90.0) < 1.0:
			lower += 1
		else:
			fail("a surface at y = %.1f, where no points are" % patch.centre.y)
	assert_int(upper).is_greater(0)
	assert_int(lower).is_greater(0)


func test_a_sloping_sheet_of_points_makes_a_sloping_surface() -> void:
	# Deeper to the east (+X): a surface falling eastward faces up and east.
	var patches := BoundaryFit.fit(_sheet(-60.0, 60.0, 3.0, 0.8, 0.0, -0.3))

	assert_int(patches.size()).is_greater(0)
	for patch in patches:
		assert_float(patch.normal.x).is_greater(0.05)
		assert_float(patch.normal.y).is_greater(0.0)


func test_a_steeper_sheet_of_points_makes_a_steeper_surface() -> void:
	var gentle := BoundaryFit.fit(_sheet(-60.0, 60.0, 3.0, 0.8, 0.0, -0.1))
	var steep := BoundaryFit.fit(_sheet(-60.0, 60.0, 3.0, 0.8, 0.0, -0.5))

	var gentle_tilt := 0.0
	var steep_tilt := 0.0
	for patch in gentle:
		gentle_tilt += patch.normal.x / gentle.size()
	for patch in steep:
		steep_tilt += patch.normal.x / steep.size()
	assert_float(steep_tilt).is_greater(gentle_tilt)


func test_a_surface_is_as_old_as_its_points() -> void:
	var older := BoundaryFit.fit(_sheet(-60.0, 60.0, 4.0, 0.6, 5.0))
	var newer := BoundaryFit.fit(_sheet(-60.0, 60.0, 4.0, 0.6, 50.0))

	assert_float(older[0].returned_at).is_less(newer[0].returned_at)
	for patch in older:
		assert_float(patch.returned_at).is_equal_approx(5.0, 0.001)


# --- The Inferred Boundary ahead ------------------------------------------------

## A level patch of ground `depth` metres down, centred under the origin.
func _level_patch(depth: float, confidence: float, centre_x := 0.0) -> BoundaryPatch:
	return BoundaryPatch.new(Vector3(centre_x, -depth, 0.0), Vector3.UP, Vector2(12.0, 12.0), 10,
			confidence, 0.0)


func test_the_boundary_ahead_is_found_along_the_line_and_only_ahead() -> void:
	var patches: Array[BoundaryPatch] = [_level_patch(50.0, 0.6)]

	var down := BoundaryFit.ahead(patches, Vector3.ZERO, Vector3.DOWN)
	var slanted := BoundaryFit.ahead(patches, Vector3.ZERO, Vector3(0.1, -1.0, 0.0).normalized())

	assert_float(down.x).is_equal_approx(50.0, 1e-4)
	assert_float(down.y).is_equal_approx(0.6, 1e-6)
	assert_float(slanted.x).is_greater(down.x)
	# Behind the Head, or well off to the side of the line: no Boundary ahead.
	assert_bool(is_inf(BoundaryFit.ahead(patches, Vector3.ZERO, Vector3.UP).x)).is_true()
	assert_bool(is_inf(BoundaryFit.ahead(patches, Vector3(200.0, 0.0, 0.0), Vector3.DOWN).x)).is_true()
	assert_float(BoundaryFit.ahead(patches, Vector3.ZERO, Vector3.UP).y).is_equal(0.0)
	assert_bool(is_inf(BoundaryFit.ahead([] as Array[BoundaryPatch], Vector3.ZERO, Vector3.DOWN).x)).is_true()


func test_a_few_stray_echoes_short_of_a_well_supported_surface_are_not_the_boundary_ahead() -> void:
	var stray := _level_patch(30.0, 0.1)
	var surface := _level_patch(60.0, 0.8)

	var found := BoundaryFit.ahead([stray, surface] as Array[BoundaryPatch], Vector3.ZERO, Vector3.DOWN)

	assert_float(found.x).is_equal_approx(60.0, 1e-4)
	assert_float(found.y).is_equal_approx(0.8, 1e-6)
	# A nearer surface about as sure is the one ahead.
	var nearer := BoundaryFit.ahead([_level_patch(30.0, 0.7), surface] as Array[BoundaryPatch],
			Vector3.ZERO, Vector3.DOWN)
	assert_float(nearer.x).is_equal_approx(30.0, 1e-4)


func test_neighbouring_patches_of_one_surface_are_read_together() -> void:
	var patches: Array[BoundaryPatch] = [_level_patch(58.0, 0.5, -5.0), _level_patch(62.0, 0.5, 5.0)]

	var found := BoundaryFit.ahead(patches, Vector3.ZERO, Vector3.DOWN)

	assert_float(found.x).is_equal_approx(60.0, 1e-4)


func test_the_fit_never_reads_the_layout() -> void:
	# The fit is given points and nothing else: no Medium, no layout, no
	# simulation is named anywhere in it.
	for path in ["res://sim/boundary_fit.gd", "res://sim/boundary_patch.gd"]:
		var source: String = (load(path) as GDScript).source_code
		for word in ["MediumLayout", "Medium", "DiveSimulation", "_layout"]:
			assert_bool(source.contains(word)) \
					.override_failure_message("%s names %s" % [path, word]) \
					.is_false()
