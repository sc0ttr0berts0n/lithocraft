# Heat and the Thermal Station, tested at the simulation's interface.
# Assert relationships, never tuned constants (ADR 0001).
extends GdUnitTestSuite


func _sim(power: float, to_column := 0.0, layout: MediumLayout = null) -> DiveSimulation:
	var sim := DiveSimulation.new(layout if layout else MediumLayout.uniform(DiveTestKit.rock()))
	sim.set_power(power)
	sim.set_heat_split(to_column)
	# A crew member at Thermal holds the split; unattended, Thermal would move
	# heat into the Column once the hull warns (station_call_test.gd).
	sim.set_attended(DiveSimulation.STATION_THERMAL, true)
	return sim


func test_heat_produced_rises_with_power_drawn() -> void:
	var produced: Array[float] = []
	for power in [0.0, 0.3, 0.6, 1.0]:
		produced.append(DiveTestKit.run(_sim(power), 5.0).heat_produced())

	for i in range(1, produced.size()):
		assert_float(produced[i]).is_greater(produced[i - 1])


func _mean_quality(sim: DiveSimulation) -> float:
	var survey := sim.survey()
	assert_int(survey.size()).is_greater(0)
	var total := 0.0
	for stretch in survey:
		total += stretch.quality
	return total / survey.size()


func test_more_heat_sent_into_the_column_lowers_survey_quality() -> void:
	var quality: Array[float] = []
	for to_column in [0.0, 0.5, 1.0]:
		quality.append(_mean_quality(DiveTestKit.run(_sim(0.6, to_column), 300.0)))

	assert_float(quality[0]).is_equal_approx(1.0, 0.0001)
	assert_float(quality[1]).is_less(quality[0])
	assert_float(quality[2]).is_less(quality[1])


func test_heat_sent_outward_wears_the_vessel_and_heat_into_the_column_does_not() -> void:
	var outward := DiveTestKit.run(_sim(1.0, 0.0), 1200.0)
	var into_column := DiveTestKit.run(_sim(1.0, 1.0), 1200.0)

	assert_float(outward.vessel_temperature()).is_greater(into_column.vessel_temperature())
	assert_float(outward.vessel_wear()).is_greater(0.0)
	assert_float(into_column.vessel_wear()).is_equal_approx(0.0, 0.0001)


## The fastest the Lithocraft can keep going for a long dive with this heat
## split without heat ever wearing the vessel.
func _fastest_sustained_speed(to_column: float) -> float:
	var best := 0.0
	for step in range(1, 21):
		var sim := DiveTestKit.run(_sim(step / 20.0, to_column), 1200.0)
		if sim.vessel_wear() > 0.0:
			break
		best = sim.speed()
	return best


func test_cooking_the_column_sustains_more_speed_than_dumping_heat_outward() -> void:
	var outward := _fastest_sustained_speed(0.0)
	var into_column := _fastest_sustained_speed(1.0)

	assert_float(outward).is_greater(0.0)
	assert_float(into_column).is_greater(outward)


func test_the_same_power_runs_hotter_deeper_in_the_same_medium() -> void:
	var sim := _sim(0.5, 0.0)
	DiveTestKit.run(sim, 600.0)
	var shallow_depth := sim.depth()
	var shallow := sim.vessel_temperature()
	DiveTestKit.run(sim, 3000.0)

	assert_float(sim.depth()).is_greater(shallow_depth)
	assert_float(sim.surroundings_temperature()).is_greater(DiveTestKit.rock().temperature)
	assert_float(sim.vessel_temperature()).is_greater(shallow)


func test_the_warning_comes_on_before_heat_damages_the_vessel() -> void:
	var sim := _sim(1.0, 0.0)
	assert_bool(sim.heat_warning()).is_false()

	var warned_at := -1.0
	var damaged_at := -1.0
	var t := 0.0
	while damaged_at < 0.0 and t < 2000.0:
		sim.advance(0.5)
		t += 0.5
		if warned_at < 0.0 and sim.heat_warning():
			warned_at = t
		if sim.vessel_wear() > 0.0:
			damaged_at = t

	assert_float(warned_at).is_greater(0.0)
	assert_float(damaged_at).is_greater(0.0)
	# Clear warning: enough time to act on it, not one step.
	assert_float(damaged_at - warned_at).is_greater(5.0)


func test_the_warning_clears_once_the_hull_cools() -> void:
	var sim := DiveTestKit.run(_sim(1.0, 0.0), 300.0)
	assert_bool(sim.heat_warning()).is_true()

	sim.set_heat_split(1.0)
	DiveTestKit.run(sim, 600.0)

	assert_bool(sim.heat_warning()).is_false()


func test_the_vessel_does_not_wear_from_heat_it_can_shed() -> void:
	var gentle := DiveTestKit.run(_sim(0.1, 0.0), 1200.0)

	assert_float(gentle.vessel_wear()).is_equal_approx(0.0, 0.0001)
