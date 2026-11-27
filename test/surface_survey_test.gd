# Surface control's survey in the scan as a dive begins (start_surveyed()),
# tested at the simulation's interface. Assert relationships, never tuned
# constants (ADR 0001).
extends GdUnitTestSuite


func _surveyed(below := 0.0) -> DiveSimulation:
	var sim := DiveSimulation.new(MediumLayout.first_dive())
	if below > 0.0:
		sim.start_below(below)
	sim.start_surveyed()
	return sim


static func _survey(points: Array[ScanPoint]) -> Array[ScanPoint]:
	return points.filter(func(p: ScanPoint) -> bool: return p.surveyed)


static func _own(points: Array[ScanPoint]) -> Array[ScanPoint]:
	return points.filter(func(p: ScanPoint) -> bool: return not p.surveyed)


## Sends one pulse, lets it return and gives back the points it added.
static func _pulse(sim: DiveSimulation) -> Array[ScanPoint]:
	var before := sim.pulses_sent()
	sim.pulse()
	sim.advance(0.1)
	return sim.points().filter(func(p: ScanPoint) -> bool: return p.pulse >= before)


## The survey points lying near any of `returns`: within `ground` metres
## across the ground and `height` metres up or down.
static func _near(survey: Array[ScanPoint], returns: Array[ScanPoint], ground: float,
		height: float) -> Array[ScanPoint]:
	return survey.filter(func(s: ScanPoint) -> bool: return _is_near(s, returns, ground, height))


static func _is_near(point: ScanPoint, returns: Array[ScanPoint], ground: float, height: float) -> bool:
	for r in returns:
		if Vector2(point.position.x - r.position.x, point.position.z - r.position.z).length() < ground \
				and absf(point.position.y - r.position.y) < height:
			return true
	return false


static func _mean_confidence(patches: Array[BoundaryPatch]) -> float:
	var total := 0.0
	for patch in patches:
		total += patch.confidence
	return total / maxf(patches.size(), 1)


## The patches lying within `metres` of depth of `depth`.
static func _at_depth(patches: Array[BoundaryPatch], depth: float, metres: float) -> Array[BoundaryPatch]:
	return patches.filter(func(p: BoundaryPatch) -> bool: return absf(-p.centre.y - depth) < metres)


## How far, on average, these points lie off the true surface of the nearest
## Boundary under each, metres of depth.
static func _mean_error(points: Array[ScanPoint], layout: MediumLayout) -> float:
	var total := 0.0
	for point in points:
		var best := INF
		for index in layout.boundary_depths().size():
			var truth := layout.boundary_depth_at(index, point.position.x, point.position.z)
			best = minf(best, absf(-point.position.y - truth))
		total += best
	return total / maxf(points.size(), 1)


func test_a_surveyed_dive_starts_with_points_and_a_faint_guess_before_any_pulse() -> void:
	var plain := DiveSimulation.new(MediumLayout.first_dive())
	var sim := _surveyed()

	assert_int(sim.pulses_sent()).is_equal(0)
	assert_int(plain.point_count()).is_equal(0)
	assert_bool(is_nan(plain.wobble_ahead_frequency())).is_true()
	# Surface control's points are in the scan, marked as the survey's...
	assert_int(sim.survey_point_count()).is_greater(0)
	assert_int(sim.point_count()).is_equal(0)
	assert_int(_survey(sim.points()).size()).is_equal(sim.survey_point_count())
	assert_int(sim.points().size()).is_equal(sim.survey_point_count())
	assert_int(sim.inferred_boundaries().size()).is_greater(0)
	# ...and STANDBY has a guess from them, with a countdown, but a faint one.
	assert_bool(is_nan(sim.wobble_ahead_frequency())).is_false()
	assert_float(sim.wobble_ahead_confidence()).is_greater(0.0)
	assert_float(sim.wobble_ahead_confidence()).is_less(0.5)
	assert_float(sim.wobble_ahead_spurious()).is_greater(0.0)


func test_the_survey_is_made_once_and_only_as_the_dive_begins() -> void:
	var sim := _surveyed()
	var held := sim.survey_point_count()
	sim.start_surveyed()
	assert_int(sim.survey_point_count()).is_equal(held)

	var late := DiveSimulation.new(MediumLayout.first_dive())
	late.advance(1.0)
	late.start_surveyed()
	assert_int(late.survey_point_count()).is_equal(0)


func test_the_surveys_inferred_boundaries_are_less_sure_than_the_vessels_own_over_the_same_rock() -> void:
	var boundary := MediumLayout.first_dive().boundary_depths()[0]
	var surveyed := _surveyed(boundary - 40.0)
	var own := DiveSimulation.new(MediumLayout.first_dive())
	own.start_below(boundary - 40.0)
	# One pulse under way: the vessel's poorest ordinary scan.
	own.set_power(1.0)
	DiveTestKit.run(own, 5.0, 0.1)
	_pulse(own)

	var survey_patches := _at_depth(surveyed.inferred_boundaries(), boundary, 20.0)
	var own_patches := _at_depth(own.inferred_boundaries(), boundary, 20.0)

	assert_int(survey_patches.size()).is_greater(0)
	assert_int(own_patches.size()).is_greater(0)
	var surest_survey := 0.0
	for patch in survey_patches:
		surest_survey = maxf(surest_survey, patch.confidence)
	assert_float(surest_survey).is_less(_mean_confidence(own_patches))
	# So the guess the vessel's own pulse gives is the surer too.
	assert_float(own.wobble_ahead_confidence()).is_greater(surveyed.wobble_ahead_confidence())


func test_the_survey_lies_further_off_the_true_boundaries_than_a_clean_scan() -> void:
	var layout := MediumLayout.first_dive()
	var sim := _surveyed(layout.boundary_depths()[0] - 40.0)
	var survey := _survey(sim.points())

	DiveTestKit.quiet_scan(sim, 3)
	var own := _own(sim.points())

	assert_int(own.size()).is_greater(0)
	assert_float(_mean_error(survey, layout)).is_greater(_mean_error(own, layout))


func test_the_vessels_own_points_replace_survey_points_near_them() -> void:
	var sim := _surveyed(MediumLayout.first_dive().boundary_depths()[0] - 40.0)
	var survey_before := _survey(sim.points())
	sim.set_quiet_ship(true)
	DiveTestKit.run(sim, 30.0, 0.1)

	var returns := _pulse(sim)
	var survey_after := _survey(sim.points())

	assert_int(returns.size()).is_greater(0)
	# Where the vessel heard the Boundary itself, most of the survey gave way...
	var near_before := _near(survey_before, returns, 2.0, 20.0)
	var near_after := _near(survey_after, returns, 2.0, 20.0)
	assert_int(near_before.size()).is_greater(0)
	assert_int(near_after.size()).is_less(near_before.size() / 2)
	# ...and away from what it heard, all of the survey is still held.
	var away_before := survey_before.filter(func(s: ScanPoint) -> bool: return not _is_near(s, returns, 40.0, 1000.0))
	var away_after := survey_after.filter(func(s: ScanPoint) -> bool: return not _is_near(s, returns, 40.0, 1000.0))
	assert_int(away_before.size()).is_greater(0)
	assert_int(away_after.size()).is_equal(away_before.size())


func test_a_few_faint_echoes_far_off_leave_the_survey_where_they_fall() -> void:
	var layout := MediumLayout.first_dive()
	var sim := _surveyed(layout.boundary_depths()[1] - 300.0)
	var survey_before := _survey(sim.points())
	sim.set_power(1.0)
	DiveTestKit.run(sim, 5.0, 0.1)

	var returns := _pulse(sim).filter(func(p: ScanPoint) -> bool:
		return absf(-p.position.y - layout.boundary_depths()[1]) < 30.0)
	var near_before := _near(survey_before, returns, 2.0, 30.0)
	var near_after := _near(_survey(sim.points()), returns, 2.0, 30.0)

	assert_int(returns.size()).is_greater(0)
	assert_int(near_before.size()).is_greater(0)
	# A faint echo here and there does not outweigh the survey: most of it
	# stays, and the guess of the granite ahead with it.
	assert_int(near_after.size()).is_greater(near_before.size() / 2)
	assert_bool(is_nan(sim.wobble_ahead_frequency())).is_false()


func test_a_long_dives_own_points_fill_the_cloud_beside_the_survey_which_stays_where_unscanned() -> void:
	var sim := _surveyed(MediumLayout.first_dive().boundary_depths()[0] - 40.0)
	var survey_start := _survey(sim.points()).size()
	sim.set_power(1.0)
	var most_own := 0

	for i in 1000:
		sim.pulse()
		sim.advance(0.1)
		most_own = maxi(most_own, _own(sim.points()).size())

	# The survey never crowds out the vessel's own points: they fill the cloud
	# to its bound...
	assert_int(most_own).is_equal(sim.point_capacity())
	assert_int(sim.point_count()).is_equal(sim.point_capacity())
	assert_int(sim.points().size()).is_equal(sim.point_count() + sim.survey_point_count())
	# ...and the oldest of them gave way, not the survey, which is held where
	# the vessel has not heard the rock itself.
	var survey_left := _survey(sim.points()).size()
	assert_int(survey_left).is_greater(0)
	assert_int(survey_left).is_less(survey_start)


func test_standby_pretuned_to_the_survey_alone_shifts_further_off_than_after_a_clean_scan() -> void:
	var boundary := MediumLayout.first_dive().boundary_depths()[0]
	var survey_only := _surveyed(boundary - 40.0)
	var scanned := _surveyed(boundary - 40.0)
	DiveTestKit.quiet_scan(scanned, 6)

	var after := []
	for sim: DiveSimulation in [survey_only, scanned]:
		DiveTestKit.tune(sim, DiveSimulation.CHANNEL_STANDBY, DiveTestKit.wobble_ahead(sim))
		sim.set_power(0.3)
		assert_dict(DiveTestKit.run_until(sim, &"boundary_crossed", 600.0, [], 0.1)).is_not_empty()
		sim.shift()
		sim.advance(0.1)
		after.append(sim.residual(DiveSimulation.CHANNEL_ACTIVE))

	# Pretuned to the survey's faint guess the Shift misleads; a clean scan's
	# guess shifts inside the Band.
	assert_float(after[0]).is_greater(after[1])
	assert_float(after[0]).is_greater(survey_only.band())
	assert_float(after[1]).is_less_equal(scanned.band())


func test_a_surveys_faint_guess_does_not_quiet_the_boundary_call_for_a_crew_that_has_done_nothing() -> void:
	var sim := Scenario.first_dive().start()
	sim.set_power(0.3)

	assert_dict(DiveTestKit.run_until(sim, &"boundary_approaching", 3000.0, [], 0.1)).is_not_empty()
	sim.advance(0.1)

	assert_bool(is_nan(sim.wobble_ahead_frequency())).is_false()
	assert_float(sim.residual(DiveSimulation.CHANNEL_STANDBY)).is_greater(sim.band())
	assert_str(String(sim.call_reason(DiveSimulation.STATION_REACTOR))).is_equal("boundary_approaching")
