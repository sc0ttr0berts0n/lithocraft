# Heat and the Thermal Station, tested at the simulation's interface.
# Assert relationships, never tuned constants (ADR 0001).
extends GdUnitTestSuite


## Test values only: a Medium strong enough that the grip waves never slip,
## so every bit of Drive power goes into speed.
func _rock() -> Medium:
	return Medium.new(&"rock", 2.0, 2.0, 0.05, 300.0, 1.0, {&"quartz": 1.0}, 0.5)


func _run(sim: DiveSimulation, seconds: float, step := 1.0) -> DiveSimulation:
	for i in int(seconds / step):
		sim.advance(step)
	return sim


func _sim(power: float, to_column := 0.0, layout: MediumLayout = null) -> DiveSimulation:
	var sim := DiveSimulation.new(layout if layout else MediumLayout.uniform(_rock()))
	sim.set_power(power)
	sim.set_heat_split(to_column)
	return sim


func test_heat_produced_rises_with_power_drawn() -> void:
	var produced: Array[float] = []
	for power in [0.0, 0.3, 0.6, 1.0]:
		produced.append(_run(_sim(power), 5.0).heat_produced())

	assert_float(produced[0]).is_equal_approx(0.0, 0.0001)
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
		quality.append(_mean_quality(_run(_sim(0.6, to_column), 300.0)))

	assert_float(quality[0]).is_equal_approx(1.0, 0.0001)
	assert_float(quality[1]).is_less(quality[0])
	assert_float(quality[2]).is_less(quality[1])


func test_heat_sent_outward_wears_the_vessel_and_heat_into_the_column_does_not() -> void:
	var outward := _run(_sim(1.0, 0.0), 1200.0)
	var into_column := _run(_sim(1.0, 1.0), 1200.0)

	assert_float(outward.vessel_temperature()).is_greater(into_column.vessel_temperature())
	assert_float(outward.vessel_wear()).is_greater(0.0)
	assert_float(into_column.vessel_wear()).is_equal_approx(0.0, 0.0001)


func test_the_vessel_does_not_wear_from_heat_it_can_shed() -> void:
	var gentle := _run(_sim(0.1, 0.0), 1200.0)

	assert_float(gentle.vessel_wear()).is_equal_approx(0.0, 0.0001)
