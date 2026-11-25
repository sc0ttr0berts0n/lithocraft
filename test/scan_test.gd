# Navigation's scan and Quiet Ship, tested at the simulation's interface.
# Assert relationships, never tuned constants (ADR 0001).
extends GdUnitTestSuite


## Test values only: a soft, open Medium over a hard, tight one, with a strong
## Boundary between them. Sound-carrying is given so tests can vary it.
func _clay(sound_carrying := 0.5) -> Medium:
	return Medium.new(&"clay", 1.0, 0.5, 0.4, 300.0, 1.0, {&"kaolinite": 1.0}, sound_carrying)


func _basalt() -> Medium:
	return Medium.new(&"basalt", 4.0, 1.0, 0.02, 320.0, 10.0,
			{&"pyroxene": 0.5, &"plagioclase": 0.5}, 0.8)


func _layout(boundary_depth: float, sound_carrying := 0.5) -> MediumLayout:
	return MediumLayout.layered([[0.0, _clay(sound_carrying)], [boundary_depth, _basalt()]])


## Sends a pulse and lets it return.
func _pulse(sim: DiveSimulation) -> Array[ScanPoint]:
	var before := sim.points().size()
	sim.pulse()
	sim.advance(0.1)
	return sim.points().slice(before)


## Engages Quiet Ship and waits until the vessel has stopped.
func _go_quiet(sim: DiveSimulation) -> void:
	sim.set_quiet_ship(true)
	for i in 600:
		sim.advance(0.1)
		if sim.speed() == 0.0 and sim.noise() == 0.0:
			return


func _mean_confidence(points: Array[ScanPoint]) -> float:
	var total := 0.0
	for point in points:
		total += point.confidence
	return total / maxf(points.size(), 1)


func _total_confidence(points: Array[ScanPoint]) -> float:
	var total := 0.0
	for point in points:
		total += point.confidence
	return total


func test_a_boundary_ahead_shows_in_the_scan_before_it_is_reached() -> void:
	var sim := DiveSimulation.new(_layout(60.0))
	_go_quiet(sim)

	var points := _pulse(sim)

	assert_float(sim.depth()).is_less(60.0)
	assert_str(sim.medium().name).is_equal(&"clay")
	assert_int(points.size()).is_greater(0)
	# The echoes lie ahead, round the Boundary's depth (world +Y is up).
	var near_boundary := 0
	for point in points:
		if absf(-point.position.y - 60.0) < 10.0:
			near_boundary += 1
	assert_int(near_boundary).is_greater(points.size() / 2)


func test_a_uniform_medium_returns_no_echoes() -> void:
	var sim := DiveSimulation.new(MediumLayout.uniform(_clay()))
	_go_quiet(sim)

	assert_int(_pulse(sim).size()).is_equal(0)


func test_point_confidence_falls_with_range() -> void:
	var near := DiveSimulation.new(_layout(30.0))
	var far := DiveSimulation.new(_layout(90.0))
	_go_quiet(near)
	_go_quiet(far)

	var near_points := _pulse(near)
	var far_points := _pulse(far)

	assert_int(near_points.size()).is_greater(far_points.size())
	assert_float(_mean_confidence(near_points)).is_greater(_mean_confidence(far_points))


func test_a_medium_that_carries_sound_better_scans_further() -> void:
	var muffled := DiveSimulation.new(_layout(60.0, 0.3))
	var clear := DiveSimulation.new(_layout(60.0, 0.9))
	_go_quiet(muffled)
	_go_quiet(clear)

	var muffled_points := _pulse(muffled)
	var clear_points := _pulse(clear)

	assert_int(clear_points.size()).is_greater(muffled_points.size())
	assert_float(_mean_confidence(clear_points)).is_greater(_mean_confidence(muffled_points))


func test_a_pulse_under_quiet_ship_is_more_confident_than_one_under_way() -> void:
	var quiet := DiveSimulation.new(_layout(80.0))
	quiet.set_power(1.0)
	for i in 100:
		quiet.advance(0.1)
	_go_quiet(quiet)
	# Under way, pulsing from no further from the Boundary than the quiet one.
	var under_way := DiveSimulation.new(_layout(80.0))
	under_way.set_power(1.0)
	while under_way.depth() < quiet.depth():
		under_way.advance(0.1)
	assert_float(under_way.speed()).is_greater(0.0)

	var quiet_points := _pulse(quiet)
	var noisy_points := _pulse(under_way)

	assert_float(_total_confidence(quiet_points)).is_greater(_total_confidence(noisy_points))
	assert_float(_mean_confidence(quiet_points)).is_greater(_mean_confidence(noisy_points))


func test_quiet_ship_halts_the_vessel_and_idles_the_head() -> void:
	var sim := DiveSimulation.new(_layout(500.0))
	sim.set_power(1.0)
	sim.advance(1.0)
	var under_way_noise := sim.noise()

	_go_quiet(sim)
	var halted_at := sim.depth()
	sim.advance(10.0)

	assert_float(under_way_noise).is_greater(0.0)
	assert_bool(sim.quiet_ship()).is_true()
	assert_float(sim.speed()).is_equal(0.0)
	assert_float(sim.noise()).is_less(under_way_noise)
	assert_float(sim.depth()).is_equal(halted_at)


func test_leaving_quiet_ship_gets_under_way_again() -> void:
	var sim := DiveSimulation.new(_layout(500.0))
	sim.set_power(1.0)
	_go_quiet(sim)
	var halted_at := sim.depth()

	sim.set_quiet_ship(false)
	for i in 100:
		sim.advance(0.1)

	assert_bool(sim.quiet_ship()).is_false()
	assert_float(sim.depth()).is_greater(halted_at)


func test_the_point_cloud_persists_and_pulses_add_to_it() -> void:
	var sim := DiveSimulation.new(_layout(50.0))
	_go_quiet(sim)

	var first := _pulse(sim)
	var after_one := sim.points().size()
	_pulse(sim)

	assert_int(first.size()).is_greater(0)
	assert_int(sim.points().size()).is_greater(after_one)
	# Earlier points are still there, unchanged.
	assert_vector(sim.points()[0].position).is_equal(first[0].position)


func test_the_points_handed_out_are_a_copy() -> void:
	var sim := DiveSimulation.new(_layout(50.0))
	_go_quiet(sim)
	_pulse(sim)
	var count := sim.points().size()

	sim.points().clear()

	assert_int(sim.points().size()).is_equal(count)


func test_a_pulse_sounds_only_once() -> void:
	var sim := DiveSimulation.new(_layout(50.0))
	_go_quiet(sim)
	_pulse(sim)
	var count := sim.points().size()

	sim.advance(1.0)
	sim.advance(1.0)

	assert_int(sim.points().size()).is_equal(count)


func test_stretches_recorded_under_quiet_ship_are_shuttered_and_worth_less() -> void:
	var sim := DiveSimulation.new(MediumLayout.uniform(_clay()))
	sim.set_power(1.0)
	for i in 300:
		sim.advance(0.1)
	_go_quiet(sim)
	sim.set_quiet_ship(false)
	for i in 600:
		sim.advance(0.1)

	var shuttered: Array[SurveyStretch] = []
	var open: Array[SurveyStretch] = []
	for stretch in sim.survey():
		(shuttered if stretch.shuttered else open).append(stretch)
	assert_int(shuttered.size()).is_greater(0)
	assert_int(open.size()).is_greater(0)
	for stretch in shuttered:
		for clear in open:
			assert_float(stretch.quality).is_less(clear.quality)


func test_without_quiet_ship_nothing_is_shuttered() -> void:
	var sim := DiveSimulation.new(MediumLayout.uniform(_clay()))
	sim.set_power(1.0)
	sim.pulse()
	for i in 100:
		sim.advance(1.0)

	assert_int(sim.survey().size()).is_greater(0)
	for stretch in sim.survey():
		assert_bool(stretch.shuttered).is_false()


func test_navigation_draws_power() -> void:
	var sim := DiveSimulation.new(_layout(50.0))

	assert_float(sim.navigation_draw()).is_greater(0.0)
