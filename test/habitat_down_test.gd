# Tests at the one seam: the vessel's pitch and the acceleration felt in
# the Habitat. Directions are in the Habitat frame the simulation documents:
# DiveSimulation.TOWARD_HEAD along the Bore, DiveSimulation.TOWARD_UNDERSIDE
# the outer wall that is underneath when the vessel is level.
extends GdUnitTestSuite

## Long enough for any pitch change to finish, however it is tuned.
const SETTLE := 600.0


func _sand_dive() -> DiveSimulation:
	return DiveSimulation.new(MediumLayout.uniform(Medium.sand()))


## Under way, since the Lithocraft turns only by cutting its path round, with
## the Drive attended so it steers onto the Course as hard as it can.
func _settled_at(pitch: float) -> DiveSimulation:
	var sim := _sand_dive()
	sim.set_attended(DiveSimulation.STATION_DRIVE, true)
	sim.set_power(1.0)
	sim.set_course(sim.course_heading(), pitch)
	sim.advance(SETTLE)
	return sim


func _felt_toward(sim: DiveSimulation, direction: Vector3) -> float:
	return sim.felt_acceleration().normalized().dot(direction)


func test_diving_nose_down_the_felt_acceleration_points_toward_the_head() -> void:
	var sim := _settled_at(90.0)

	assert_float(_felt_toward(sim, DiveSimulation.TOWARD_HEAD)).is_greater(0.99)


func test_travelling_level_the_felt_acceleration_points_toward_the_outer_wall() -> void:
	var sim := _settled_at(0.0)

	assert_float(_felt_toward(sim, DiveSimulation.TOWARD_UNDERSIDE)).is_greater(0.99)
	assert_float(absf(_felt_toward(sim, DiveSimulation.TOWARD_HEAD))).is_less(0.01)


func test_pitch_moves_toward_its_setting_gradually_rather_than_jumping() -> void:
	var sim := _settled_at(90.0)

	sim.set_course(sim.course_heading(), 0.0)
	sim.advance(5.0)

	assert_float(sim.pitch()).is_less(90.0)
	assert_float(sim.pitch()).is_greater(0.0)


func test_down_turns_from_head_to_outer_wall_without_a_sudden_jump() -> void:
	var sim := _settled_at(90.0)
	sim.set_course(sim.course_heading(), 0.0)

	# Step through the whole change a frame at a time; no single frame may
	# swing "down" by more than a degree.
	var largest_swing := 0.0
	var before := sim.felt_acceleration()
	for i in int(SETTLE * 60.0):
		sim.advance(1.0 / 60.0)
		var after := sim.felt_acceleration()
		largest_swing = maxf(largest_swing, rad_to_deg(before.angle_to(after)))
		before = after

	assert_float(largest_swing).is_less(1.0)
	assert_float(_felt_toward(sim, DiveSimulation.TOWARD_UNDERSIDE)).is_greater(0.99)


func test_pitch_never_passes_nose_straight_down_or_straight_up() -> void:
	var steepest := _settled_at(90.0)
	var beyond_down := _settled_at(200.0)
	var beyond_up := _settled_at(-200.0)
	var straight_up := _settled_at(-90.0)

	assert_float(beyond_down.pitch()).is_equal_approx(steepest.pitch(), 0.001)
	assert_float(beyond_up.pitch()).is_equal_approx(straight_up.pitch(), 0.001)
