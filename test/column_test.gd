# The Column in the Bore, tested at the simulation's interface.
# Assert relationships, never tuned constants (ADR 0001).
extends GdUnitTestSuite


## Test values only: two Media easy to tell apart.
func _chalk() -> Medium:
	return Medium.new(&"chalk", 1.0, 0.5, 0.3, 300.0, 1.0, {&"calcite": 1.0}, 0.4)


func _basalt() -> Medium:
	return Medium.new(&"basalt", 1.0, 0.5, 0.05, 300.0, 1.0,
			{&"pyroxene": 0.5, &"plagioclase": 0.5}, 0.8)


func _chalk_over_basalt(boundary: float) -> DiveSimulation:
	return DiveSimulation.new(MediumLayout.layered([[0.0, _chalk()], [boundary, _basalt()]]))


## How far behind the Head the Boundary between chalk and basalt sits in the
## Column, found by looking along it in small steps.
func _boundary_behind_head(sim: DiveSimulation) -> float:
	var step := 0.01
	var behind := 0.0
	while sim.column_at(behind).name == &"basalt":
		behind += step
	return behind


func test_the_column_at_the_head_is_the_medium_the_lithocraft_is_in() -> void:
	var sim := _chalk_over_basalt(20.0)
	sim.set_power(0.5)

	for i in 60:
		sim.advance(1.0)
		assert_str(sim.column_at(0.0).name).is_equal(sim.medium().name)


func test_after_crossing_a_boundary_the_old_medium_is_still_in_the_column_behind() -> void:
	var sim := _chalk_over_basalt(20.0)
	sim.set_power(0.5)
	while sim.distance() < 25.0:
		sim.advance(0.5)

	assert_str(sim.column_at(0.0).name).is_equal(&"basalt")
	assert_str(sim.column_at(sim.distance() - 10.0).name).is_equal(&"chalk")


func test_a_boundary_in_the_column_moves_back_at_the_vessels_speed() -> void:
	for power in [0.2, 0.6]:
		var sim := _chalk_over_basalt(10.0)
		sim.set_power(power)
		while sim.distance() < 12.0:
			sim.advance(0.25)
		var before := _boundary_behind_head(sim)

		sim.advance(2.0)

		var moved := _boundary_behind_head(sim) - before
		assert_float(moved).is_equal_approx(sim.speed() * 2.0, 0.02)


func test_the_column_moves_faster_through_the_bore_at_higher_power() -> void:
	var slow := _chalk_over_basalt(10.0)
	var fast := _chalk_over_basalt(10.0)
	slow.set_power(0.2)
	fast.set_power(0.6)
	for sim in [slow, fast]:
		while sim.distance() < 12.0:
			sim.advance(0.25)
	var slow_before := _boundary_behind_head(slow)
	var fast_before := _boundary_behind_head(fast)

	slow.advance(2.0)
	fast.advance(2.0)

	assert_float(_boundary_behind_head(fast) - fast_before) \
			.is_greater(_boundary_behind_head(slow) - slow_before)
