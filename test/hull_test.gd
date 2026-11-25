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


func test_the_hull_takes_damage_only_while_overheated_and_faster_the_hotter() -> void:
	var cool := DiveTestKit.run(_sim(MediumLayout.uniform(_hard_rock()), 0.1), 600.0)
	var warm := DiveTestKit.run(_sim(MediumLayout.uniform(_hard_rock()), 0.8), 600.0)
	var hot := DiveTestKit.run(_sim(MediumLayout.uniform(_hard_rock()), 1.0), 600.0)

	assert_bool(cool.hull_taking_damage()).is_false()
	assert_bool(warm.hull_taking_damage()).is_true()
	assert_bool(hot.hull_taking_damage()).is_true()
	assert_float(hot.hull_creep_rate()).is_greater(warm.hull_creep_rate())


func test_the_hull_stops_taking_damage_once_it_cools() -> void:
	var sim := DiveTestKit.run(_sim(MediumLayout.uniform(_hard_rock()), 1.0), 600.0)
	assert_bool(sim.hull_taking_damage()).is_true()

	sim.set_power(0.0)
	DiveTestKit.run(sim, 1200.0)

	assert_bool(sim.hull_taking_damage()).is_false()
	assert_float(sim.hull_creep_rate()).is_equal(0.0)


func test_the_rock_stresses_the_hull_harder_deeper_down() -> void:
	var shallow := _sim(MediumLayout.uniform(_soft_rock()), 1.0, 1.0)
	var deep := _sim(MediumLayout.uniform(_soft_rock()), 1.0, 1.0)
	while shallow.depth() < 50.0:
		shallow.advance(1.0)
	while deep.depth() < 800.0:
		deep.advance(1.0)

	assert_float(shallow.hull_stress()).is_greater(0.0)
	assert_float(deep.hull_stress()).is_greater(shallow.hull_stress())


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


## Test values only: dense rock the Head cuts easily. The tunnel seals behind
## the Tail and the rock carries no sound, so the survey stays aboard.
func _dense_rock() -> Medium:
	return Medium.new(&"dense", 1.0, 3.0, 0.0, 300.0, 1.0, {&"quartz": 1.0}, 0.0)


## Full power with every bit of heat sent outward, through rock that keeps the
## survey aboard: the hull overheats until it fails.
func _reckless() -> DiveSimulation:
	return _sim(MediumLayout.uniform(_dense_rock()), 1.0, 0.0)


func test_hull_failure_ends_the_dive_in_death_and_loses_the_unsold_survey() -> void:
	var sim := _reckless()
	var unsold := [0.0]
	var seen := []

	var failed := DiveTestKit.run_until(sim, &"hull_failed", 20000.0, seen, 1.0,
			func() -> void: unsold[0] = sim.unsold_value())

	assert_dict(failed).is_not_empty()
	assert_bool(sim.dead()).is_true()
	assert_float(sim.hull_integrity()).is_equal(0.0)
	# Thermal called with the heat warning well before.
	var types := DiveTestKit.types(seen)
	assert_int(types.find(&"station_call")).is_less(types.find(&"hull_failed"))
	# There was survey aboard, and it is lost with the crew.
	assert_float(unsold[0]).is_greater(0.0)
	assert_float(failed.lost).is_greater_equal(unsold[0])
	assert_int(failed.lost_stretches).is_greater(0)
	assert_float(sim.unsold_value()).is_equal(0.0)
	assert_int(sim.survey().size()).is_equal(sim.uploaded_survey().size())


func test_the_dead_crew_goes_no_further() -> void:
	var sim := _reckless()
	DiveTestKit.run_until(sim, &"hull_failed", 20000.0, [], 1.0)
	var depth := sim.depth()

	DiveTestKit.run(sim, 60.0)

	assert_float(sim.depth()).is_equal(depth)
	assert_float(sim.speed()).is_equal(0.0)
	assert_array(sim.take_events()).is_empty()


func test_death_shows_a_rebuy_but_charges_nothing_while_there_is_no_balance() -> void:
	var sim := _reckless()
	var paid_before := [0.0]

	var failed := DiveTestKit.run_until(sim, &"hull_failed", 20000.0, [], 1.0,
			func() -> void: paid_before[0] = sim.paid())

	assert_float(failed.rebuy).is_greater(0.0)
	assert_float(failed.rebuy_charged).is_equal(0.0)
	assert_float(failed.total_paid).is_equal(paid_before[0])
	assert_float(sim.paid()).is_equal(paid_before[0])


func test_after_death_the_rebuy_starts_a_new_dive_with_a_whole_hull() -> void:
	var sim := _reckless()
	DiveTestKit.run_until(sim, &"hull_failed", 20000.0, [], 1.0)
	var paid := sim.paid()

	sim.new_dive()

	assert_array(DiveTestKit.types(sim.take_events())).contains([&"new_dive"])
	assert_bool(sim.dead()).is_false()
	assert_float(sim.hull_integrity()).is_equal(1.0)
	assert_float(sim.depth()).is_equal(0.0)
	assert_float(sim.paid()).is_equal(paid)


func test_a_hull_that_bears_its_heat_never_fails() -> void:
	var sim := _sim(MediumLayout.uniform(_dense_rock()), 1.0, 1.0)
	var seen := []

	DiveTestKit.run_until(sim, &"hull_failed", 3000.0, seen, 1.0)

	assert_bool(sim.dead()).is_false()
	assert_array(DiveTestKit.types(seen)).not_contains([&"hull_failed"])
