# Steering at the Drive Station, tested at the simulation's interface: power,
# heading and pitch in; the Lithocraft's path, depth and heat out.
# Assert relationships, never tuned constants (ADR 0001).
extends GdUnitTestSuite


## Test values only: a Medium strong enough that the grip waves never slip.
func _rock() -> Medium:
	return Medium.new(&"rock", 1.0, 2.0, 0.05, 300.0, 1.0, {&"quartz": 1.0}, 0.5)


func _run(sim: DiveSimulation, seconds: float, step := 1.0) -> DiveSimulation:
	for i in int(seconds / step):
		sim.advance(step)
	return sim


## A Lithocraft under power that has turned from its dive to travel level,
## heading 0, and has had all the time it needs to get there.
func _travelling_level(power := 1.0, layout: MediumLayout = null) -> DiveSimulation:
	var sim := DiveSimulation.new(layout if layout else MediumLayout.uniform(_rock()))
	sim.set_power(power)
	sim.set_pitch(0.0)
	sim.set_heading(0.0)
	_run(sim, 3000.0)
	return sim


## Compass heading in degrees, -180 to 180, so headings either side of 0 compare.
func _heading(sim: DiveSimulation) -> float:
	return wrapf(sim.heading_degrees(), -180.0, 180.0)


func test_travelling_level_keeps_depth_while_distance_grows() -> void:
	var sim := _travelling_level()
	var depth := sim.depth()
	var distance := sim.distance()

	_run(sim, 100.0)

	assert_float(sim.pitch()).is_equal_approx(0.0, 0.01)
	assert_float(sim.distance()).is_greater(distance)
	assert_float(sim.depth()).is_equal_approx(depth, 0.01)


func test_climbing_brings_the_lithocraft_shallower() -> void:
	var sim := _travelling_level()
	var depth := sim.depth()

	sim.set_pitch(-45.0)
	_run(sim, 1000.0)

	assert_float(sim.depth()).is_less(depth)


func test_a_heading_change_takes_effect_gradually_not_instantly() -> void:
	var sim := _travelling_level()
	assert_float(_heading(sim)).is_equal_approx(0.0, 0.01)

	sim.set_heading(90.0)
	sim.advance(1.0)
	var after_a_second := _heading(sim)
	_run(sim, 30.0)
	var after_half_a_minute := _heading(sim)
	_run(sim, 3000.0)

	assert_float(after_a_second).is_greater(0.0)
	assert_float(after_a_second).is_less(1.0)
	assert_float(after_half_a_minute).is_greater(after_a_second)
	assert_float(after_half_a_minute).is_less(90.0)
	assert_float(_heading(sim)).is_equal_approx(90.0, 0.01)
