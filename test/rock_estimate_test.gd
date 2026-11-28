# The scan's estimate of the rock beyond a Boundary (#122): harder or softer,
# denser or more porous, as far as sound can know, and surface control's
# expectation of the rock by name. Tested at the simulation's interface.
# Assert relationships, never tuned constants (ADR 0001).
extends GdUnitTestSuite


## A layout of `upper` over `lower`, the Boundary `depth` metres down.
static func _layout(upper: Medium, lower: Medium, depth := 40.0) -> MediumLayout:
	return MediumLayout.layered([[0.0, upper], [depth, lower]])


## Test values only: two rocks that sound nearly alike, the second a little
## the harder.
static func _near_alike() -> Array[Medium]:
	return [DiveTestKit.rock(2.0), DiveTestKit.rock(2.3)]


## Engages Quiet Ship and waits until the vessel has stopped.
static func _go_quiet(sim: DiveSimulation) -> void:
	sim.set_quiet_ship(true)
	for i in 600:
		sim.advance(0.1)
		if sim.speed() == 0.0 and sim.noise() == 0.0:
			return


## A sure scan: halted at Quiet Ship, a few clean pulses.
static func _sure(layout: MediumLayout) -> DiveSimulation:
	var sim := DiveSimulation.new(layout)
	_go_quiet(sim)
	for i in 3:
		sim.pulse()
		sim.advance(0.1)
	return sim


## An unsure scan: under way at full power, the vessel's own noise loud, a
## few pulses sent as it goes.
static func _unsure(layout: MediumLayout) -> DiveSimulation:
	var sim := DiveSimulation.new(layout)
	sim.set_power(1.0)
	sim.advance(2.0)
	for i in 3:
		sim.pulse()
		sim.advance(0.2)
	return sim


func test_a_sure_scan_says_harder_into_harder_rock_and_softer_into_softer() -> void:
	var pair := _near_alike()
	for rocks: Array in [[DiveTestKit.soft(), DiveTestKit.hard()], [pair[0], pair[1]]]:
		var into_harder := _sure(_layout(rocks[0], rocks[1]))
		var into_softer := _sure(_layout(rocks[1], rocks[0]))

		assert_float(into_harder.rock_ahead()).is_greater(0.0)
		assert_float(into_softer.rock_ahead()).is_less(0.0)
		# As sure as the Inferred Boundary ahead.
		assert_float(into_harder.rock_ahead_confidence()).is_greater(0.0)
	# The stronger contrast reads the stronger.
	assert_float(_sure(_layout(DiveTestKit.soft(), DiveTestKit.hard())).rock_ahead()) \
			.is_greater(_sure(_layout(pair[0], pair[1])).rock_ahead())


func test_a_less_sure_scan_is_further_from_the_truth() -> void:
	# Mirrored Boundaries at one depth: their true estimates are equal and
	# opposite, and both are heard alike, so half their difference is the
	# truth and half their sum how far the scan is out.
	for rocks: Array in [[DiveTestKit.soft(), DiveTestKit.hard()], _near_alike()]:
		var harder := _layout(rocks[0], rocks[1])
		var softer := _layout(rocks[1], rocks[0])
		var sure := [_sure(harder), _sure(softer)]
		var unsure := [_unsure(harder), _unsure(softer)]
		var truth: float = (sure[0].rock_ahead() - sure[1].rock_ahead()) * 0.5
		var sure_out: float = absf(sure[0].rock_ahead() - truth)
		var unsure_out: float = absf(unsure[0].rock_ahead() - truth)

		assert_float(unsure[0].rock_ahead_confidence()).is_less(sure[0].rock_ahead_confidence())
		assert_float(unsure_out).is_greater(sure_out)
		# Wrong: off the truth by more than a sure scan's error, either way.
		assert_float(absf(unsure[1].rock_ahead() + truth)).is_greater(absf(sure[1].rock_ahead() + truth))
		# Wrong in how much, never which way: polarity is the surest thing
		# an echo carries.
		assert_float(unsure[0].rock_ahead()).is_greater(0.0)
		assert_float(unsure[1].rock_ahead()).is_less(0.0)


func test_the_estimate_errs_the_way_standby_guess_does() -> void:
	# Several Boundaries, so their errors go both ways.
	var ways := {}
	for depth in [40.0, 43.0, 47.0, 52.0, 58.0]:
		for rocks: Array in [[DiveTestKit.soft(), DiveTestKit.hard()], [DiveTestKit.hard(), DiveTestKit.soft()]]:
			var layout := _layout(rocks[0], rocks[1], depth)
			var sure := _sure(layout)
			var unsure := _unsure(layout)
			var rock_off := unsure.rock_ahead() - sure.rock_ahead()
			var guess_off := unsure.wobble_ahead_frequency() - sure.wobble_ahead_frequency()

			# Where the guess puts the rock beyond harder than a surer scan
			# does (a higher Wobble), so does the estimate.
			assert_float(signf(rock_off)).is_equal(signf(guess_off))
			ways[signf(rock_off)] = true
	assert_int(ways.size()).is_equal(2)


func test_the_first_dive_never_reads_softer_beside_a_guess_that_says_harder() -> void:
	var sim := DiveSimulation.new(MediumLayout.first_dive())
	sim.start_surveyed()
	sim.set_power(1.0)
	sim.set_autopilot(DiveSimulation.STATION_REACTOR, true)
	sim.set_autopilot(DiveSimulation.STATION_THERMAL, true)
	sim.set_beam_pulsing(true)
	var read := 0
	for second in 600:
		sim.advance(1.0)
		if is_nan(sim.rock_ahead()) or is_nan(sim.wobble_ahead_frequency()) or sim.settling_in():
			continue
		read += 1
		# The guess's Wobble beyond is higher than the rock's now just when
		# the estimate says the rock beyond is harder.
		assert_float(signf(sim.rock_ahead())) \
				.is_equal(signf(sim.wobble_ahead_frequency() - sim.wobble_frequency()))
	assert_int(read).is_greater(0)


func test_the_estimate_comes_from_the_points_alone() -> void:
	var layout := _layout(DiveTestKit.soft(), DiveTestKit.hard())
	# No scan, no estimate, though the Boundary is there.
	var unscanned := DiveSimulation.new(layout)
	unscanned.advance(1.0)
	assert_bool(is_nan(unscanned.rock_ahead())).is_true()
	assert_float(unscanned.rock_ahead_confidence()).is_equal(0.0)

	var sim := _sure(layout)
	# Every echo carries what it says of the rock either side...
	assert_int(sim.points().size()).is_greater(0)
	for point in sim.points():
		assert_bool(is_nan(point.contrast)).is_false()
	# ...and the estimate ahead is what the patches fitted to them say.
	var found := BoundaryFit.ahead(BoundaryFit.fit(sim.points()), sim.head_position(), sim.heading())
	assert_float(sim.rock_ahead()).is_equal_approx(found.z, 1e-6)


func test_surface_control_names_the_rock_it_expects_as_a_guess_until_the_column_confirms_it() -> void:
	var layout := MediumLayout.first_dive()
	var plain := DiveSimulation.new(layout)
	assert_array(plain.expected_rocks()).is_empty()

	var sim := DiveSimulation.new(layout)
	sim.start_below(layout.boundary_depths()[0] - 3.0)
	sim.start_surveyed()
	var expected := sim.expected_rocks()
	var depths := layout.boundary_depths()
	assert_int(expected.size()).is_equal(depths.size())
	for i in depths.size():
		# The rock below each Boundary, by name, near where it lies.
		assert_str(String(expected[i].name)).is_equal(String(layout.medium_at(depths[i] + 1.0).name))
		for other in depths.size():
			if other != i:
				assert_float(absf(expected[i].depth - depths[i])).is_less(absf(expected[i].depth - depths[other]))
		assert_bool(expected[i].confirmed).is_false()
	# The survey's points and patches name no rock: only the expectation does.
	assert_bool(sim.points()[0].get_property_list().any(
			func(p: Dictionary) -> bool: return p.name == "name")).is_false()

	sim.set_power(0.6)
	sim.set_autopilot(DiveSimulation.STATION_REACTOR, true)
	sim.set_autopilot(DiveSimulation.STATION_THERMAL, true)
	var into: StringName = layout.medium_at(depths[0] + 1.0).name
	for second in 900:
		sim.advance(1.0)
		if sim.survey().any(func(s: SurveyStretch) -> bool: return s.medium_name == into):
			break
	# The Column has shown the rock below the first Boundary: that name is
	# confirmed, the deeper ones are still surface control's guess.
	assert_bool(sim.expected_rocks()[0].confirmed).is_true()
	for i in range(1, depths.size()):
		assert_bool(sim.expected_rocks()[i].confirmed).is_false()
