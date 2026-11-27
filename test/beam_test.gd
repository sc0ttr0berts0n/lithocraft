# Navigation's Beam: its three widths and its own pulsing, tested at the
# simulation's interface. Assert relationships, never tuned constants
# (ADR 0001).
extends GdUnitTestSuite


## Test values only: one rock for the first 200 m, so a vessel under way in
## these tests crosses no Boundary, then it and a denser one by turns, a
## Boundary every 40 m to well past any pulse's reach, so how far a pulse
## returns from is how far it reaches.
func _banded() -> MediumLayout:
	var layers := [[0.0, _lighter()]]
	for i in 80:
		layers.append([200.0 + i * 40.0, _lighter() if i % 2 == 1 else _denser()])
	return MediumLayout.layered(layers)


func _lighter() -> Medium:
	return Medium.new(&"lighter", 2.0, 2.0, 0.3, 300.0, 1.0, {&"quartz": 1.0}, 0.5)


func _denser() -> Medium:
	return Medium.new(&"denser", 3.0, 2.0, 0.25, 300.0, 1.0, {&"quartz": 1.0}, 0.5)


## Engages Quiet Ship and waits until the vessel has stopped.
func _go_quiet(sim: DiveSimulation) -> void:
	sim.set_quiet_ship(true)
	for i in 600:
		sim.advance(0.1)
		if sim.speed() == 0.0 and sim.noise() == 0.0:
			return


## Sends a pulse by hand, lets it return and gives back the points it added.
func _pulse(sim: DiveSimulation) -> Array[ScanPoint]:
	var before := sim.pulses_sent()
	sim.pulse()
	sim.advance(0.1)
	return sim.points().filter(func(p: ScanPoint) -> bool: return p.pulse >= before)


## A quiet vessel's pulse at this width, straight down.
func _quiet_pulse(width: StringName) -> Array[ScanPoint]:
	var sim := DiveSimulation.new(_banded())
	_go_quiet(sim)
	sim.set_beam_width(width)
	return _pulse(sim)


func _furthest(points: Array[ScanPoint]) -> float:
	var most := 0.0
	for point in points:
		most = maxf(most, point.range)
	return most


## The mean angle, degrees, between straight down (the way the vessel points
## at the start) and where the points were heard from.
func _mean_angle(points: Array[ScanPoint], origin: Vector3) -> float:
	var total := 0.0
	for point in points:
		total += rad_to_deg((point.position - origin).angle_to(Vector3.DOWN))
	return total / maxf(points.size(), 1.0)


func _mean_confidence(points: Array[ScanPoint]) -> float:
	var total := 0.0
	for point in points:
		total += point.confidence
	return total / maxf(points.size(), 1.0)


func test_a_dive_starts_with_the_middle_width_and_the_switch_off() -> void:
	var sim := DiveSimulation.new(_banded())

	assert_str(sim.beam_width()).is_equal(DiveSimulation.BEAM_MIDDLE)
	assert_bool(sim.beam_pulsing()).is_false()
	assert_array(DiveSimulation.BEAM_WIDTHS).contains_exactly(
			[DiveSimulation.BEAM_WIDE, DiveSimulation.BEAM_MIDDLE, DiveSimulation.BEAM_NARROW])


func test_a_narrower_beam_returns_points_from_further_away() -> void:
	var wide := _quiet_pulse(DiveSimulation.BEAM_WIDE)
	var middle := _quiet_pulse(DiveSimulation.BEAM_MIDDLE)
	var narrow := _quiet_pulse(DiveSimulation.BEAM_NARROW)

	assert_int(wide.size()).is_greater(0)
	assert_float(_furthest(narrow)).is_greater(_furthest(middle))
	assert_float(_furthest(middle)).is_greater(_furthest(wide))


func test_a_narrower_beam_covers_a_smaller_angle() -> void:
	var origin := DiveSimulation.new(_banded()).head_position()
	var wide := _quiet_pulse(DiveSimulation.BEAM_WIDE)
	var middle := _quiet_pulse(DiveSimulation.BEAM_MIDDLE)
	var narrow := _quiet_pulse(DiveSimulation.BEAM_NARROW)

	assert_float(_mean_angle(narrow, origin)).is_less(_mean_angle(middle, origin))
	assert_float(_mean_angle(middle, origin)).is_less(_mean_angle(wide, origin))


func test_the_reach_and_the_angle_the_simulation_states_follow_the_width() -> void:
	var sim := DiveSimulation.new(_banded())
	var reach := {}
	var angle := {}
	for width in DiveSimulation.BEAM_WIDTHS:
		sim.set_beam_width(width)
		reach[width] = sim.beam_reach()
		angle[width] = sim.beam_half_angle()

	assert_float(reach[DiveSimulation.BEAM_NARROW]).is_greater(reach[DiveSimulation.BEAM_MIDDLE])
	assert_float(reach[DiveSimulation.BEAM_MIDDLE]).is_greater(reach[DiveSimulation.BEAM_WIDE])
	assert_float(angle[DiveSimulation.BEAM_NARROW]).is_less(angle[DiveSimulation.BEAM_MIDDLE])
	assert_float(angle[DiveSimulation.BEAM_MIDDLE]).is_less(angle[DiveSimulation.BEAM_WIDE])


func test_with_the_switch_on_a_moving_vessel_pulses_with_no_key_pressed() -> void:
	var sim := DiveSimulation.new(_banded())
	sim.set_power(1.0)
	sim.set_beam_pulsing(true)

	var events := []
	for i in 120:
		sim.advance(0.5)
		events.append_array(sim.take_events())

	assert_float(sim.distance()).is_greater(0.0)
	assert_int(sim.pulses_sent()).is_greater(1)
	var own := events.filter(func(e: Dictionary) -> bool: return e.type == &"pulse_sent" and e.by_itself)
	assert_int(own.size()).is_equal(sim.pulses_sent())


func test_with_the_switch_off_a_moving_vessel_sends_no_pulse_by_itself() -> void:
	var sim := DiveSimulation.new(_banded())
	sim.set_power(1.0)

	DiveTestKit.run(sim, 60.0, 0.5)

	assert_float(sim.distance()).is_greater(0.0)
	assert_int(sim.pulses_sent()).is_equal(0)


func test_it_pulses_by_ground_covered_so_faster_pulses_more_often() -> void:
	var slow := DiveSimulation.new(_banded())
	var fast := DiveSimulation.new(_banded())
	slow.set_power(0.3)
	fast.set_power(1.0)
	slow.set_beam_pulsing(true)
	fast.set_beam_pulsing(true)

	DiveTestKit.run(slow, 120.0, 0.5)
	DiveTestKit.run(fast, 120.0, 0.5)

	assert_float(fast.distance()).is_greater(slow.distance())
	assert_int(fast.pulses_sent()).is_greater(slow.pulses_sent())


func test_halted_the_switch_does_not_keep_pulsing() -> void:
	var sim := DiveSimulation.new(_banded())
	sim.set_power(1.0)
	sim.set_beam_pulsing(true)
	DiveTestKit.run(sim, 60.0, 0.5)
	_go_quiet(sim)
	assert_float(sim.speed()).is_equal(0.0)
	var halted_at := sim.pulses_sent()

	DiveTestKit.run(sim, 300.0, 0.5)

	assert_int(sim.pulses_sent()).is_equal(halted_at)


func test_a_pulse_by_itself_under_way_is_noisier_than_one_by_hand_at_quiet_ship() -> void:
	var quiet := DiveSimulation.new(_banded())
	quiet.set_power(1.0)
	DiveTestKit.run(quiet, 30.0, 0.5)
	_go_quiet(quiet)
	var clean := _pulse(quiet)
	# Under way with the switch on, its first pulse sent from no nearer the
	# Boundaries than the quiet one's.
	var under_way := DiveSimulation.new(_banded())
	under_way.set_power(1.0)
	under_way.set_beam_pulsing(true)
	while under_way.depth() < quiet.depth():
		under_way.advance(0.1)
	var before := under_way.pulses_sent()
	while under_way.pulses_sent() == before:
		under_way.advance(0.1)
	var noisy := under_way.points().filter(func(p: ScanPoint) -> bool: return p.pulse >= before)

	assert_float(under_way.speed()).is_greater(0.0)
	assert_float(_mean_confidence(clean)).is_greater(_mean_confidence(noisy))


func test_the_width_and_the_switch_are_settings_that_disengage_navigation_s_autopilot() -> void:
	for change in [func(sim: DiveSimulation) -> void: sim.set_beam_width(DiveSimulation.BEAM_NARROW),
			func(sim: DiveSimulation) -> void: sim.set_beam_pulsing(true)]:
		var sim := DiveSimulation.new(_banded())
		sim.set_autopilot(DiveSimulation.STATION_NAVIGATION, true)
		sim.take_events()

		change.call(sim)

		assert_bool(sim.autopilot(DiveSimulation.STATION_NAVIGATION)).is_false()
		assert_array(DiveTestKit.types(sim.take_events())).contains([&"autopilot_off"])


func test_a_pulse_by_hand_or_by_itself_is_a_reading_that_leaves_the_autopilot_engaged() -> void:
	var sim := DiveSimulation.new(_banded())
	sim.set_power(1.0)
	sim.set_beam_pulsing(true)
	sim.set_autopilot(DiveSimulation.STATION_NAVIGATION, true)

	sim.pulse()
	DiveTestKit.run(sim, 60.0, 0.5)

	assert_int(sim.pulses_sent()).is_greater(1)
	assert_bool(sim.autopilot(DiveSimulation.STATION_NAVIGATION)).is_true()


func test_a_pulse_costs_the_same_at_every_width() -> void:
	# The same energy in every width: Navigation draws the same whichever is set.
	var draws := []
	for width in DiveSimulation.BEAM_WIDTHS:
		var sim := DiveSimulation.new(_banded())
		sim.set_beam_width(width)
		_pulse(sim)
		DiveTestKit.run(sim, 5.0, 0.5)
		draws.append(sim.navigation_draw())

	assert_float(draws[0]).is_equal(draws[1])
	assert_float(draws[1]).is_equal(draws[2])


func test_pulsing_at_any_width_keeps_the_cloud_at_its_bound() -> void:
	# The scan's bound holds however many pulses go out, by hand and by the
	# switch: each sends the same rays at every width, and the cloud never
	# holds more than it may.
	for width in DiveSimulation.BEAM_WIDTHS:
		var sim := DiveSimulation.new(_banded())
		sim.set_beam_width(width)
		sim.set_power(1.0)
		sim.set_beam_pulsing(true)
		var most := 0
		for i in 150:
			sim.pulse()
			sim.advance(0.25)
			most = maxi(most, sim.point_count())

		assert_int(sim.pulses_sent()).is_greater_equal(150)
		assert_int(most).is_less_equal(sim.point_capacity())
