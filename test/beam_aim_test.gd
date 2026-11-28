# Navigation's Beam aimed off the vessel's axis (#120), tested at the
# simulation's interface. Assert relationships, never tuned constants
# (ADR 0001).
extends GdUnitTestSuite


## Test values only: one rock for the first `clear` metres, then it and a
## denser one by turns, a Boundary every 20 m to well past any pulse's reach.
func _banded(clear := 200.0) -> MediumLayout:
	var layers := [[0.0, _lighter()]]
	for i in 120:
		layers.append([clear + i * 20.0, _lighter() if i % 2 == 1 else _denser()])
	return MediumLayout.layered(layers)


## Boundaries every 20 m from the surface down, so there is rock above the
## vessel to return echoes from once it has started below some of them.
func _banded_from_the_surface() -> MediumLayout:
	return _banded(20.0)


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
	return _since(sim, before)


func _since(sim: DiveSimulation, pulse: int) -> Array[ScanPoint]:
	return sim.points().filter(func(p: ScanPoint) -> bool: return p.pulse >= pulse)


## How many of these points were heard from inside the cone dead ahead: within
## the Beam's half-angle of the way the Head points.
func _dead_ahead(sim: DiveSimulation, points: Array[ScanPoint], origin: Vector3) -> int:
	var half := deg_to_rad(sim.beam_half_angle())
	return points.filter(func(p: ScanPoint) -> bool: return (p.position - origin).angle_to(sim.heading()) < half).size()


## The mean way the points were heard from, unit length.
func _mean_way(points: Array[ScanPoint], origin: Vector3) -> Vector3:
	var total := Vector3.ZERO
	for point in points:
		total += (point.position - origin).normalized()
	return total.normalized()


## The vessel's right, as the views have it: level, square to its compass
## heading.
func _right(sim: DiveSimulation) -> Vector3:
	var b := deg_to_rad(sim.heading_degrees())
	return Vector3(cos(b), 0.0, sin(b))


# --- Where it points --------------------------------------------------------

func test_a_dive_starts_with_the_beam_aimed_dead_ahead() -> void:
	var sim := DiveSimulation.new(_banded())

	assert_vector(sim.beam_aim()).is_equal(Vector2.ZERO)
	assert_vector(sim.beam_axis()).is_equal_approx(sim.heading(), Vector3.ONE * 1e-5)


func test_an_aimed_pulse_returns_points_from_the_aimed_way_and_none_from_dead_ahead() -> void:
	var sim := DiveSimulation.new(_banded())
	_go_quiet(sim)
	sim.set_beam_width(DiveSimulation.BEAM_NARROW)
	var origin := sim.head_position()
	var ahead := _pulse(sim)
	assert_int(_dead_ahead(sim, ahead, origin)).is_greater(0)

	sim.set_beam_aim(45.0, 0.0)
	var aimed := _pulse(sim)

	assert_int(aimed.size()).is_greater(0)
	assert_int(_dead_ahead(sim, aimed, origin)).is_equal(0)
	# Toward the vessel's right, where it was aimed, and nearer the aim than
	# dead ahead.
	var way := _mean_way(aimed, origin)
	assert_float(way.dot(_right(sim))).is_greater(0.0)
	assert_float(way.angle_to(sim.beam_axis())).is_less(way.angle_to(sim.heading()))


func test_aimed_the_other_way_it_returns_points_from_the_other_side() -> void:
	var left := DiveSimulation.new(_banded())
	var up := DiveSimulation.new(_banded())
	for sim in [left, up]:
		_go_quiet(sim)
		sim.set_beam_width(DiveSimulation.BEAM_NARROW)
	left.set_beam_aim(-45.0, 0.0)
	up.set_beam_aim(0.0, 45.0)
	var origin := left.head_position()

	var to_the_left := _mean_way(_pulse(left), origin)
	var to_the_top := _mean_way(_pulse(up), origin)

	assert_float(to_the_left.dot(_right(left))).is_less(0.0)
	# The vessel's top, diving straight down at heading 0, is onward along
	# that heading: its right turned square to the way it points.
	var top := _right(up).cross(up.heading()).normalized()
	assert_float(to_the_top.dot(top)).is_greater(0.0)
	assert_float(absf(to_the_top.dot(_right(up)))).is_less(to_the_top.dot(top))


func test_the_beam_s_own_pulsing_uses_the_aim_it_is_given() -> void:
	var sim := DiveSimulation.new(_banded())
	sim.set_beam_width(DiveSimulation.BEAM_NARROW)
	sim.set_beam_aim(45.0, 0.0)
	sim.set_power(1.0)
	sim.set_beam_pulsing(true)
	while sim.pulses_sent() == 0:
		sim.advance(0.1)
	var origin := sim.head_position()

	var own := _since(sim, 0)

	assert_int(own.size()).is_greater(0)
	assert_int(_dead_ahead(sim, own, origin)).is_equal(0)
	assert_float(_mean_way(own, origin).dot(_right(sim))).is_greater(0.0)


func test_the_aim_is_relative_to_the_vessel_and_turns_with_the_head() -> void:
	var sim := DiveSimulation.new(_banded())
	sim.set_autopilot(DiveSimulation.STATION_THERMAL, true)
	sim.set_autopilot(DiveSimulation.STATION_REACTOR, true)
	sim.set_beam_aim(45.0, 0.0)
	var off_axis := sim.beam_axis().angle_to(sim.heading())
	var heading_before := sim.heading()
	var axis_before := sim.beam_axis()

	sim.set_power(1.0)
	sim.set_steering_effort(1.0)
	sim.set_course(90.0, 0.0)
	DiveTestKit.run(sim, 120.0)

	assert_float(sim.heading().angle_to(heading_before)).is_greater(deg_to_rad(10.0))
	assert_float(sim.beam_axis().angle_to(sim.heading())).is_equal_approx(off_axis, 1e-4)
	assert_float(sim.beam_axis().angle_to(axis_before)).is_greater(deg_to_rad(5.0))
	assert_vector(sim.beam_aim()).is_equal(Vector2(45.0, 0.0))


func test_the_aim_cannot_pass_square_across_the_vessel() -> void:
	var sim := DiveSimulation.new(_banded())
	for asked: Vector2 in [Vector2(200.0, 0.0), Vector2(0.0, -200.0), Vector2(135.0, 135.0),
			Vector2(-170.0, 60.0), Vector2(91.0, -91.0)]:
		sim.set_beam_aim(asked.x, asked.y)

		assert_float(sim.beam_axis().dot(sim.heading())).is_greater_equal(-1e-5)

	sim.set_beam_aim(200.0, 0.0)
	var furthest := sim.beam_aim()
	assert_float(sim.beam_axis().dot(sim.heading())).is_equal_approx(0.0, 1e-5)
	sim.set_beam_aim(300.0, 0.0)
	assert_vector(sim.beam_aim()).is_equal(furthest)


func test_nothing_is_returned_from_behind() -> void:
	# Started 100 m down with a Boundary every 20 m above and below it, the
	# widest Beam aimed square across: half its cone would reach behind the
	# vessel, back up the way it came.
	for aim: Vector2 in [Vector2(90.0, 0.0), Vector2(0.0, 90.0), Vector2(-90.0, -90.0)]:
		var sim := DiveSimulation.new(_banded_from_the_surface())
		sim.start_below(100.0)
		_go_quiet(sim)
		sim.set_beam_width(DiveSimulation.BEAM_WIDE)
		sim.set_beam_aim(aim.x, aim.y)
		var origin := sim.head_position()

		var heard := _pulse(sim)

		assert_int(heard.size()).is_greater(0)
		var behind := heard.filter(func(p: ScanPoint) -> bool: return p.position.y > origin.y + 5.0)
		assert_array(behind).override_failure_message("%d points from behind, aimed %s" % [behind.size(), aim]).is_empty()


func test_the_aim_is_a_setting_that_disengages_navigation_s_autopilot() -> void:
	var sim := DiveSimulation.new(_banded())
	sim.set_autopilot(DiveSimulation.STATION_NAVIGATION, true)
	sim.take_events()

	sim.set_beam_aim(30.0, 15.0)

	assert_bool(sim.autopilot(DiveSimulation.STATION_NAVIGATION)).is_false()
	assert_array(DiveTestKit.types(sim.take_events())).contains([&"autopilot_off"])


func test_aimed_back_to_nothing_off_the_axis_it_points_dead_ahead_again() -> void:
	var sim := DiveSimulation.new(_banded())
	sim.set_beam_aim(60.0, -30.0)

	sim.set_beam_aim(0.0, 0.0)

	assert_vector(sim.beam_aim()).is_equal(Vector2.ZERO)
	assert_vector(sim.beam_axis()).is_equal_approx(sim.heading(), Vector3.ONE * 1e-5)


# --- The look-ahead keeps to the Head's direction ----------------------------

func test_the_look_ahead_reads_along_the_head_however_the_beam_is_aimed() -> void:
	# Both scan the Boundary dead ahead; one then aims square across and pulses
	# again. The guess of the Wobble ahead and the countdown still read the
	# rock along the Head's direction.
	var ahead := DiveSimulation.new(_banded(40.0))
	var aside := DiveSimulation.new(_banded(40.0))
	for sim in [ahead, aside]:
		DiveTestKit.quiet_scan(sim)
	aside.set_beam_aim(90.0, 0.0)
	DiveTestKit.quiet_scan(aside)
	for sim in [ahead, aside]:
		sim.set_power(1.0)
		DiveTestKit.run(sim, 2.0, 0.5)

	assert_bool(is_nan(DiveTestKit.wobble_ahead(ahead).x)).is_false()
	assert_bool(is_nan(DiveTestKit.wobble_ahead(aside).x)).is_false()
	assert_float(DiveTestKit.wobble_ahead(aside).x).is_equal_approx(DiveTestKit.wobble_ahead(ahead).x,
			DiveTestKit.wobble_ahead(ahead).x * 0.05)
	assert_float(aside.boundary_countdown()).is_less(INF)
	assert_float(aside.boundary_countdown()).is_equal_approx(ahead.boundary_countdown(),
			ahead.boundary_countdown() * 0.2)


# --- At Navigation ------------------------------------------------------------

## Presses the key of `action` at Navigation (`index` which of its keys) in
## a staged Habitat, as the crew would.
func _press(habitat: Node3D, action: StringName, index := 0) -> void:
	for binding in KeyMap.bindings_at(DiveSimulation.STATION_NAVIGATION):
		if binding.action == action:
			var key := InputEventKey.new()
			key.physical_keycode = binding.keys[index]
			key.pressed = true
			habitat._unhandled_input(key)
			return
	fail("no key for %s at Navigation" % action)


func test_at_navigation_keys_swing_the_aim_and_one_key_brings_it_back_dead_ahead() -> void:
	var habitat := DiveTestKit.staged_habitat(self, Scenario.first_dive())
	var sim: DiveSimulation = habitat.simulation()
	habitat.seat_at(DiveSimulation.STATION_NAVIGATION)
	habitat._physics_process(1.0 / 60.0)

	_press(habitat, &"beam_aim_across", 1)
	_press(habitat, &"beam_aim_across", 1)
	_press(habitat, &"beam_aim_up", 1)
	assert_float(sim.beam_aim().x).is_greater(0.0)
	assert_float(sim.beam_aim().y).is_greater(0.0)
	_press(habitat, &"beam_aim_across", 0)
	_press(habitat, &"beam_aim_across", 0)
	_press(habitat, &"beam_aim_across", 0)
	assert_float(sim.beam_aim().x).is_less(0.0)
	assert_bool(sim.beam_axis().is_equal_approx(sim.heading())).is_false()

	_press(habitat, &"beam_aim_ahead")

	assert_vector(sim.beam_aim()).is_equal(Vector2.ZERO)
	assert_vector(sim.beam_axis()).is_equal_approx(sim.heading(), Vector3.ONE * 1e-5)


func test_the_cone_is_drawn_about_the_aim_and_the_label_names_it() -> void:
	var sim := DiveSimulation.new(_banded())
	var display: ScanDisplay = auto_free(ScanDisplay.new())
	display.sim = sim
	add_child(display)
	var dead_ahead := display.beam_label()

	for aim: Vector2 in [Vector2(45.0, 0.0), Vector2(0.0, -30.0), Vector2(-60.0, 75.0), Vector2(90.0, 90.0)]:
		sim.set_beam_aim(aim.x, aim.y)
		var b := deg_to_rad(sim.heading_degrees())
		var squares := ScanDisplay.aim_squares(sim.heading(), Vector3(cos(b), 0.0, sin(b)), sim.beam_aim())

		# The fans lie square to the aimed axis, and to each other.
		for square in squares:
			assert_float(square.dot(sim.beam_axis())).is_equal_approx(0.0, 1e-5)
		assert_float(squares[0].dot(squares[1])).is_equal_approx(0.0, 1e-5)
		assert_str(display.beam_label()).starts_with(dead_ahead)
		assert_str(display.beam_label()).contains(ScanDisplay.aim_words(sim.beam_aim()))
		assert_str(display.beam_label()).is_not_equal(dead_ahead)

	sim.set_beam_aim(0.0, 0.0)
	assert_str(display.beam_label()).is_equal(dead_ahead)


func test_the_aim_s_words_say_which_way() -> void:
	assert_str(ScanDisplay.aim_words(Vector2.ZERO)).is_equal("AHEAD")
	assert_str(ScanDisplay.aim_words(Vector2(30.0, 0.0))).contains("R")
	assert_str(ScanDisplay.aim_words(Vector2(-30.0, 0.0))).contains("L")
	assert_str(ScanDisplay.aim_words(Vector2(0.0, 15.0))).contains("U")
	assert_str(ScanDisplay.aim_words(Vector2(0.0, -15.0))).contains("D")
	assert_str(ScanDisplay.aim_words(Vector2(0.0, -15.0))).is_not_equal(ScanDisplay.aim_words(Vector2(0.0, 15.0)))
