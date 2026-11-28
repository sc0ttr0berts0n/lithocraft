# A target's region narrowed by points alone (TargetRegion.narrowed()), as
# the Inferred Boundaries are fitted to points alone: the region learns only
# from the Orders' place and from points, never from a body, so a test can
# put points where no body is and the region follows them. Assert
# relationships, never tuned constants (ADR 0001).
extends GdUnitTestSuite

## The Orders' place, as the survey gives it: wide and uncertain.
const REPORT_CENTRE := Vector3(0.0, -300.0, 0.0)
const REPORT_HALF := Vector3(30.0, 45.0, 30.0)


func _report() -> TargetRegion:
	return TargetRegion.new(&"A", REPORT_CENTRE, REPORT_HALF)


## A patch of `count` points of this confidence on a small cap round `at`,
## as an echo off a body's near surface would leave them.
func _cap(at: Vector3, count: int, confidence := 0.9, surveyed := false) -> Array[ScanPoint]:
	var points: Array[ScanPoint] = []
	var random := RandomNumberGenerator.new()
	random.seed = 5
	for i in count:
		var place := at + Vector3(random.randf_range(-4.0, 4.0), random.randf_range(-1.0, 1.0),
				random.randf_range(-4.0, 4.0))
		points.append(ScanPoint.new(place, confidence, 60.0, 0, 0.0, surveyed))
	return points


func test_with_no_points_the_region_is_the_orders_place() -> void:
	var none: Array[ScanPoint] = []
	var region := TargetRegion.narrowed(_report(), none)
	assert_vector(region.centre).is_equal(REPORT_CENTRE)
	assert_vector(region.half_size).is_equal(REPORT_HALF)
	assert_float(region.support).is_equal(0.0)


func test_points_inside_the_orders_place_narrow_it_round_them_even_with_no_body_there() -> void:
	var at := REPORT_CENTRE + Vector3(15.0, 20.0, -10.0)
	var region := TargetRegion.narrowed(_report(), _cap(at, 40))
	assert_float(region.volume()).is_less(_report().volume())
	# Moved toward the points, not left at the Orders' place.
	assert_float(region.centre.distance_to(at)).is_less(REPORT_CENTRE.distance_to(at))
	assert_bool(region.holds(at)).is_true()
	assert_float(region.support).is_greater(0.0)


func test_points_outside_the_orders_place_narrow_nothing() -> void:
	var region := TargetRegion.narrowed(_report(), _cap(REPORT_CENTRE + Vector3(80.0, 0.0, 0.0), 40))
	assert_float(region.volume()).is_equal_approx(_report().volume(), 0.001)
	assert_vector(region.centre).is_equal(REPORT_CENTRE)


func test_surface_controls_own_points_narrow_nothing() -> void:
	var region := TargetRegion.narrowed(_report(), _cap(REPORT_CENTRE, 40, 0.9, true))
	assert_float(region.volume()).is_equal_approx(_report().volume(), 0.001)


func test_more_and_surer_points_narrow_it_further() -> void:
	var few := TargetRegion.narrowed(_report(), _cap(REPORT_CENTRE, 3, 0.3))
	var many := TargetRegion.narrowed(_report(), _cap(REPORT_CENTRE, 60, 0.9))
	assert_float(few.volume()).is_less(_report().volume())
	assert_float(many.volume()).is_less(few.volume())


func test_points_spread_wider_leave_a_wider_region() -> void:
	var tight := _cap(REPORT_CENTRE, 60)
	var wide: Array[ScanPoint] = []
	for point in tight:
		var off := point.position - REPORT_CENTRE
		wide.append(ScanPoint.new(REPORT_CENTRE + Vector3(off.x * 3.0, off.y, off.z * 3.0), point.confidence,
				point.range, point.pulse, point.returned_at))
	assert_float(TargetRegion.narrowed(_report(), wide).volume()) \
			.is_greater(TargetRegion.narrowed(_report(), tight).volume())


func test_the_region_never_grows_past_the_orders_place() -> void:
	# Points spread right across it, as wide as it is.
	var points: Array[ScanPoint] = []
	for x in [-25.0, 25.0]:
		for y in [-40.0, 40.0]:
			for z in [-25.0, 25.0]:
				points.append(ScanPoint.new(REPORT_CENTRE + Vector3(x, y, z) * 0.5, 0.2, 300.0, 0, 0.0))
	var region := TargetRegion.narrowed(_report(), points)
	assert_bool(region.half_size.x <= REPORT_HALF.x and region.half_size.y <= REPORT_HALF.y
			and region.half_size.z <= REPORT_HALF.z).is_true()


func test_the_region_never_names_the_layout_or_a_body() -> void:
	var source := FileAccess.get_file_as_string("res://sim/target_region.gd")
	for name in ["MediumLayout", "TargetBody", "_layout"]:
		assert_bool(source.contains(name)).override_failure_message("target_region.gd names %s" % name).is_false()
