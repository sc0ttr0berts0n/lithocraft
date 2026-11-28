# Steering at the Drive Station, tested at the simulation's interface: power
# and the Course (heading and pitch) in, the Drive steering as hard as it
# can; the Lithocraft's path, depth and heat out.
# Assert relationships, never tuned constants (ADR 0001).
extends GdUnitTestSuite


## A Lithocraft under power, steering hard, that has turned from its dive to
## travel level, heading 0, and has had all the time it needs to get there.
## Thermal's autopilot keeps the hull whole at full power.
func _travelling_level(power := 1.0, layout: MediumLayout = null) -> DiveSimulation:
	var sim := DiveSimulation.new(layout if layout else MediumLayout.uniform(DiveTestKit.rock(1.0)))
	sim.set_power(power)
	sim.set_autopilot(DiveSimulation.STATION_THERMAL, true)
	sim.set_course(0.0, 0.0)
	DiveTestKit.run(sim, 3000.0)
	return sim


## Compass heading in degrees, -180 to 180, so headings either side of 0 compare.
func _heading(sim: DiveSimulation) -> float:
	return wrapf(sim.heading_degrees(), -180.0, 180.0)


func test_travelling_level_keeps_depth_while_distance_grows() -> void:
	var sim := _travelling_level()
	var depth := sim.depth()
	var distance := sim.distance()

	DiveTestKit.run(sim, 100.0)

	assert_float(sim.pitch()).is_equal_approx(0.0, 0.01)
	assert_float(sim.distance()).is_greater(distance)
	assert_float(sim.depth()).is_equal_approx(depth, 0.01)


func test_climbing_brings_the_lithocraft_shallower() -> void:
	var sim := _travelling_level()
	var depth := sim.depth()

	sim.set_course(sim.course_heading(), -45.0)
	DiveTestKit.run(sim, 1000.0)

	assert_float(sim.depth()).is_less(depth)


func test_a_heading_change_takes_effect_gradually_not_instantly() -> void:
	var sim := _travelling_level()
	assert_float(_heading(sim)).is_equal_approx(0.0, 0.01)

	sim.set_course(90.0, sim.course_pitch())
	sim.advance(1.0)
	var after_a_second := _heading(sim)
	DiveTestKit.run(sim, 30.0)
	var after_half_a_minute := _heading(sim)
	DiveTestKit.run(sim, 3000.0)

	assert_float(after_a_second).is_greater(0.0)
	assert_float(after_a_second).is_less(1.0)
	assert_float(after_half_a_minute).is_greater(after_a_second)
	assert_float(after_half_a_minute).is_less(90.0)
	assert_float(_heading(sim)).is_equal_approx(90.0, 0.01)


## Asks for an about-turn and follows it, step by step, until it is done:
## returns the sharpest bend any step made (radians per metre of path), the
## widest the turn swung sideways from where it began (metres), and the
## minimum turn radius the simulation reports.
func _about_turn(power: float, step: float) -> Array[float]:
	var sim := _travelling_level(power)
	var start := sim.head_position()
	sim.set_course(180.0, sim.course_pitch())
	var sharpest := 0.0
	var widest := 0.0
	for i in int(6000.0 / step):
		var before := sim.heading()
		var distance := sim.distance()
		sim.advance(step)
		var moved := sim.distance() - distance
		if moved > 0.0:
			sharpest = maxf(sharpest, before.angle_to(sim.heading()) / moved)
		widest = maxf(widest, absf(sim.head_position().x - start.x))
	assert_float(absf(_heading(sim))).is_equal_approx(180.0, 0.01)
	return [sharpest, widest, sim.minimum_turn_radius()]


func test_the_lithocraft_cannot_turn_tighter_than_its_minimum_arc() -> void:
	for power in [0.2, 1.0]:
		for step in [0.1, 5.0]:
			var turn := _about_turn(power, step)
			var radius := turn[2]

			assert_float(turn[0]).is_less_equal(1.0 / radius * 1.001)
			# An about-turn on the tightest arc swings one diameter sideways.
			assert_float(turn[1]).is_greater_equal(2.0 * radius * 0.99)


func test_a_stopped_lithocraft_cannot_turn() -> void:
	var sim := _travelling_level()
	var heading := sim.heading()
	sim.set_power(0.0)

	sim.set_course(90.0, sim.course_pitch())
	DiveTestKit.run(sim, 600.0)

	assert_float(sim.heading().angle_to(heading)).is_less(0.0001)


func test_turning_makes_more_heat_than_going_straight_at_the_same_power() -> void:
	var straight := _travelling_level(0.5)
	var turning := _travelling_level(0.5)

	turning.set_course(90.0, turning.course_pitch())
	DiveTestKit.run(straight, 20.0)
	DiveTestKit.run(turning, 20.0)

	assert_float(turning.heat_produced()).is_greater(straight.heat_produced())


func test_once_on_its_heading_the_extra_heat_dies_away() -> void:
	var sim := _travelling_level(0.5)
	var straight_heat := sim.heat_produced()
	# A gentle turn: a hard one heats the hull to a warning, and Thermal's
	# autopilot then keeps its raised split, which draws more for good.
	sim.set_steering_effort(0.25)

	sim.set_course(90.0, sim.course_pitch())
	DiveTestKit.run(sim, 3000.0)

	assert_float(sim.heat_produced()).is_equal_approx(straight_heat, 0.0001)


func test_no_command_moves_the_lithocraft_backward() -> void:
	var sim := _travelling_level()
	var commands := [
		func(): sim.set_power(-1.0),
		func(): sim.set_power(0.0),
		func(): sim.set_power(1.0); sim.set_course(180.0, sim.course_pitch()),
		func(): sim.set_course(sim.course_heading(), -90.0),
		func(): sim.set_course(-45.0, 200.0),
		func(): sim.set_quiet_ship(true),
		func(): sim.set_quiet_ship(false); sim.set_power(0.4),
	]
	for command: Callable in commands:
		command.call()
		for i in 300:
			var ahead := sim.heading()
			var at := sim.head_position()
			var distance := sim.distance()
			sim.advance(1.0)
			var moved := sim.head_position() - at

			assert_float(sim.distance()).is_greater_equal(distance)
			assert_float(moved.dot(ahead + sim.heading())).is_greater_equal(0.0)
			assert_float(moved.length()).is_less_equal(sim.distance() - distance + 0.001)


func test_the_column_and_survey_follow_the_path_not_the_distance_travelled() -> void:
	# A Boundary deeper than a dive that levels off at once ever reaches.
	var layout := MediumLayout.layered([[0.0, DiveTestKit.rock(1.0)], [400.0, Medium.granite()]])
	var sim := DiveSimulation.new(layout)
	sim.set_attended(DiveSimulation.STATION_DRIVE, true)
	sim.set_power(1.0)
	sim.set_course(sim.course_heading(), 0.0)
	while sim.distance() < 1000.0:
		sim.advance(1.0)

	assert_float(sim.depth()).is_less(400.0)
	assert_str(sim.medium().name).is_equal(&"rock")
	assert_str(sim.column_at(500.0).name).is_equal(&"rock")
	for stretch in sim.survey():
		assert_str(stretch.medium_name).is_equal(&"rock")
