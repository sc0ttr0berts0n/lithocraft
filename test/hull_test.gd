# The hull: heat wear (creep), hull failure and death, tested at the
# simulation's interface. Assert relationships, never tuned constants
# (ADR 0001).
extends GdUnitTestSuite


## Test values only: rock so hard the Head barely advances, so a vessel at full
## power stays where it is and makes heat all the while.
func _hard_rock(temperature := 300.0) -> Medium:
	return Medium.new(&"hard", 1000.0, 1000.0, 0.05, temperature, 1.0, {&"quartz": 1.0}, 0.5)


## Test values only: rock the Head cuts easily.
func _soft_rock(temperature := 300.0) -> Medium:
	return Medium.new(&"soft", 1.0, 3.0, 0.05, temperature, 1.0, {&"quartz": 1.0}, 0.5)


## A crew member at Thermal holds the split, so nothing steadies the heat.
func _sim(layout: MediumLayout, power: float, to_column := 0.0) -> DiveSimulation:
	var sim := DiveSimulation.new(layout)
	sim.set_power(power)
	sim.set_heat_split(to_column)
	sim.set_attended(DiveSimulation.STATION_THERMAL, true)
	return sim


func test_a_new_hull_is_whole_and_not_creeping() -> void:
	var sim := _sim(MediumLayout.uniform(_hard_rock()), 0.0)

	assert_float(sim.hull_integrity()).is_equal(1.0)
	assert_float(sim.hull_creep_rate()).is_equal(0.0)


func test_below_its_rated_temperature_the_hull_takes_no_damage() -> void:
	var sim := DiveTestKit.run(_sim(MediumLayout.uniform(_hard_rock()), 0.1), 1200.0)

	assert_float(sim.vessel_temperature()).is_less(sim.hull_damage_temperature())
	assert_float(sim.hull_creep_rate()).is_equal(0.0)
	assert_float(sim.hull_integrity()).is_equal(1.0)


func test_the_further_over_its_rated_temperature_the_faster_the_hull_creeps() -> void:
	var warm := DiveTestKit.run(_sim(MediumLayout.uniform(_hard_rock()), 0.8), 600.0)
	var hot := DiveTestKit.run(_sim(MediumLayout.uniform(_hard_rock()), 1.0), 600.0)

	assert_float(warm.vessel_temperature()).is_greater(warm.hull_damage_temperature())
	assert_float(hot.vessel_temperature()).is_greater(warm.vessel_temperature())
	assert_float(warm.hull_creep_rate()).is_greater(0.0)
	assert_float(hot.hull_creep_rate()).is_greater(warm.hull_creep_rate())
	assert_float(hot.hull_integrity()).is_less(warm.hull_integrity())


func test_deeper_down_the_same_heat_creeps_the_hull_faster() -> void:
	# Shallow: held at the surface in hard rock. Deep: down through soft rock
	# into hard rock that is cooler, so the deep hull is no hotter.
	var shallow := _sim(MediumLayout.uniform(_hard_rock()), 1.0)
	var deep := _sim(MediumLayout.layered([[0.0, _soft_rock()], [400.0, _hard_rock(285.0)]]), 1.0,
			1.0)
	while deep.depth() < 400.0:
		deep.advance(1.0)
	deep.set_heat_split(0.0)
	DiveTestKit.run(shallow, 1200.0)
	DiveTestKit.run(deep, 1200.0)

	assert_float(deep.depth()).is_greater(shallow.depth() + 300.0)
	assert_float(deep.vessel_temperature()).is_greater(deep.hull_damage_temperature())
	assert_float(deep.vessel_temperature()).is_less_equal(shallow.vessel_temperature())
	assert_float(deep.hull_creep_rate()).is_greater(shallow.hull_creep_rate())


## Drives down to `depth` at full power with the heat sent into the Column,
## then cuts the power and lingers there for `seconds`.
func _linger(layout: MediumLayout, depth: float, seconds: float) -> DiveSimulation:
	var sim := _sim(layout, 1.0, 1.0)
	while sim.depth() < depth:
		sim.advance(1.0)
	sim.set_power(0.0)
	return DiveTestKit.run(sim, seconds)


func test_lingering_deep_at_no_power_the_rock_heats_the_hull() -> void:
	var layout := MediumLayout.uniform(_soft_rock())
	var shallow := _linger(layout, 50.0, 1200.0)
	var deep := _linger(layout, 1500.0, 1200.0)

	assert_float(shallow.speed()).is_equal(0.0)
	assert_float(deep.speed()).is_equal(0.0)
	assert_float(deep.vessel_temperature()).is_greater(shallow.vessel_temperature())


func test_rock_hotter_than_the_hull_bears_wears_it_even_at_no_power() -> void:
	var bears := DiveSimulation.new(MediumLayout.uniform(_soft_rock())).hull_damage_temperature()
	var hot := MediumLayout.layered([[0.0, _soft_rock()], [100.0, _soft_rock(bears * 1.2)]])
	var cool := MediumLayout.uniform(_soft_rock())

	var in_hot := _linger(hot, 150.0, 1200.0)
	var in_cool := _linger(cool, 150.0, 1200.0)

	assert_float(in_hot.drive_draw()).is_equal(0.0)
	assert_float(in_hot.vessel_temperature()).is_greater(in_hot.hull_damage_temperature())
	assert_float(in_hot.hull_creep_rate()).is_greater(0.0)
	assert_float(in_hot.hull_integrity()).is_less(1.0)
	assert_float(in_cool.hull_creep_rate()).is_equal(0.0)
