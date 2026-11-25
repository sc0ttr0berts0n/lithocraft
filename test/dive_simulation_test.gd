# Tests at the one seam: the simulation's interface.
# Build a simulation from a Medium layout, send commands, advance time,
# read state and events. Assert relationships, never tuned constants.
extends GdUnitTestSuite


func _sand_dive() -> DiveSimulation:
	return DiveSimulation.new(MediumLayout.uniform(Medium.sand()))


func test_lithocraft_goes_deeper_under_power_in_sand() -> void:
	var sim := _sand_dive()
	var start_depth := sim.depth()

	sim.set_power(0.5)
	sim.advance(10.0)

	assert_float(sim.depth()).is_greater(start_depth)


func test_higher_power_goes_further_in_the_same_time() -> void:
	var gentle := _sand_dive()
	var hard := _sand_dive()

	gentle.set_power(0.3)
	hard.set_power(0.9)
	gentle.advance(10.0)
	hard.advance(10.0)

	assert_float(hard.depth()).is_greater(gentle.depth())


func test_without_power_the_lithocraft_stays_put() -> void:
	var sim := _sand_dive()
	var start_depth := sim.depth()

	sim.set_power(0.0)
	sim.advance(10.0)

	assert_float(sim.depth()).is_equal(start_depth)
