# The projected path (ticket #66): where this turn takes the Lithocraft, the
# simulation's own turning rule run forward at its present speed and steering.
# Tested at the simulation's interface: commands and time in, projected_path()
# and the path actually flown out. The moving map's share (the projection
# unrolled into its cross-section) is plain static code, tested directly.
# Assert relationships, never tuned constants (ADR 0001).
extends GdUnitTestSuite


## A Lithocraft diving straight down under power, some way into its dive.
## Thermal's autopilot keeps the hull whole.
func _diving(power := 1.0, effort := 1.0) -> DiveSimulation:
	var sim := DiveSimulation.new(MediumLayout.uniform(DiveTestKit.rock(1.0)))
	sim.set_power(power)
	sim.set_steering_effort(effort)
	sim.set_autopilot(DiveSimulation.STATION_THERMAL, true)
	DiveTestKit.run(sim, 100.0)
	return sim


## How far a place lies from a path given as points joined by straight pieces.
func _off_path(place: Vector3, path: PackedVector3Array) -> float:
	var nearest := INF
	for i in range(1, path.size()):
		var closest := Geometry3D.get_closest_point_to_segment(place, path[i - 1], path[i])
		nearest = minf(nearest, place.distance_to(closest))
	return nearest


func _length(path: PackedVector3Array) -> float:
	var length := 0.0
	for i in range(1, path.size()):
		length += path[i - 1].distance_to(path[i])
	return length


func _deepest(path: PackedVector3Array) -> float:
	var deepest := -INF
	for point in path:
		deepest = maxf(deepest, -point.y)
	return deepest


## How far below the Head the projection's deepest point lies: the room the
## turn takes.
func _room_below(sim: DiveSimulation) -> float:
	return _deepest(sim.projected_path()) - sim.depth()


func test_the_projected_path_starts_at_the_head() -> void:
	var sim := _diving()

	var path := sim.projected_path()

	assert_int(path.size()).is_greater(1)
	assert_float(path[0].distance_to(sim.head_position())).is_less(0.001)


## Whether the test steps a second at a time or the game a sixtieth.
func test_flown_unchanged_the_vessel_stays_on_its_projected_path() -> void:
	for step in [1.0, 1.0 / 60.0]:
		var sim := _diving()
		sim.set_course(90.0, 20.0)
		sim.advance(step)
		var path := sim.projected_path()
		var start := sim.distance()
		var turned_from := sim.heading()

		var furthest_off := 0.0
		# Up to the last step that ends short of the projection's end.
		while sim.distance() - start < _length(path) - 2.0 * sim.speed():
			sim.advance(step)
			furthest_off = maxf(furthest_off, _off_path(sim.head_position(), path))

		# It flew the whole turn and on down the straight, never off the line.
		assert_float(rad_to_deg(turned_from.angle_to(sim.heading()))).is_greater(60.0)
		assert_float(sim.heading().angle_to(sim.course_direction())).is_less(0.001)
		assert_float(furthest_off).is_less(0.5)


func test_the_projection_runs_through_the_turn_then_straight_along_what_the_drive_steers_for() -> void:
	var sim := _diving()
	sim.set_course(90.0, 20.0)
	sim.advance(1.0)

	var path := sim.projected_path()

	var last := (path[path.size() - 1] - path[path.size() - 2]).normalized()
	assert_float(last.angle_to(sim.course_direction())).is_less(0.01)
	assert_float(path[path.size() - 1].distance_to(path[path.size() - 2])).is_greater(
			path[1].distance_to(path[0]))


func test_on_its_course_the_projection_is_a_straight_line_ahead() -> void:
	var sim := _diving()

	var path := sim.projected_path()

	for point in path:
		assert_float((point - sim.head_position()).cross(sim.heading()).length()).is_less(0.001)
	assert_float(_deepest(path)).is_greater(sim.depth())


func test_turning_from_a_dive_to_a_climb_the_projection_bottoms_out_where_the_turn_then_does() -> void:
	var sim := _diving()
	sim.set_course(0.0, -45.0)
	sim.advance(1.0)

	var projected := _deepest(sim.projected_path())

	assert_float(projected).is_greater(sim.depth())
	var reached := sim.depth()
	while sim.pitch() > -40.0:
		sim.advance(1.0)
		reached = maxf(reached, sim.depth())
	assert_float(reached).is_greater(sim.minimum_turn_radius() * 0.5)
	assert_float(projected).is_equal_approx(reached, 0.5)


func test_less_steering_effort_projects_a_wider_turn() -> void:
	var hard := _diving(1.0, 1.0)
	var gentle := _diving(1.0, 0.4)
	hard.set_course(0.0, -45.0)
	gentle.set_course(0.0, -45.0)
	hard.advance(1.0)
	gentle.advance(1.0)

	assert_float(_room_below(gentle)).is_greater(_room_below(hard))


func test_more_speed_projects_a_wider_turn() -> void:
	var slow := _diving(0.3)
	var fast := _diving(1.0)
	slow.set_course(0.0, -45.0)
	fast.set_course(0.0, -45.0)
	slow.advance(1.0)
	fast.advance(1.0)

	assert_float(fast.speed()).is_greater(slow.speed())
	assert_float(_room_below(fast)).is_greater(_room_below(slow))


func test_a_climb_is_projected_no_further_than_the_surface() -> void:
	var sim := _diving()
	sim.set_course(0.0, -90.0)
	DiveTestKit.fly_until(sim, func(s: DiveSimulation) -> bool: return s.pitch() < -80.0)
	sim.advance(1.0)
	assert_float(sim.depth()).is_greater(0.0)

	var path := sim.projected_path()

	for point in path:
		assert_float(point.y).is_less_equal(0.001)
	assert_float(path[path.size() - 1].y).is_equal_approx(0.0, 0.01)


func test_a_stopped_lithocraft_projects_no_path() -> void:
	var sim := _diving()
	sim.set_power(0.0)
	sim.advance(1.0)

	var path := sim.projected_path()

	assert_int(path.size()).is_equal(1)
	assert_float(path[0].distance_to(sim.head_position())).is_less(0.001)


func test_looking_ahead_changes_nothing() -> void:
	var looked := _diving()
	var unlooked := _diving()
	looked.set_course(90.0, 0.0)
	unlooked.set_course(90.0, 0.0)

	for i in 200:
		looked.projected_path()
		looked.advance(1.0)
		unlooked.advance(1.0)

	assert_vector(looked.head_position()).is_equal(unlooked.head_position())
	assert_vector(looked.heading()).is_equal(unlooked.heading())
	assert_float(looked.steering()).is_equal(unlooked.steering())
