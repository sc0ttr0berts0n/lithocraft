# The Column and the Bore Station survey, tested at the simulation's interface.
# Assert relationships, never tuned constants (ADR 0001).
extends GdUnitTestSuite


func _dive(layout: MediumLayout, power: float, seconds: float) -> DiveSimulation:
	var sim := DiveSimulation.new(layout)
	sim.set_power(power)
	for i in int(seconds):
		sim.advance(1.0)
	return sim


func test_the_survey_grows_as_the_lithocraft_advances() -> void:
	var sim := DiveSimulation.new(MediumLayout.uniform(Medium.sand()))
	sim.set_power(0.5)

	var sizes: Array[int] = [sim.survey().size()]
	for i in 3:
		for s in 200:
			sim.advance(1.0)
		sizes.append(sim.survey().size())

	assert_int(sizes[0]).is_equal(0)
	assert_int(sizes[1]).is_greater(sizes[0])
	assert_int(sizes[2]).is_greater(sizes[1])
	assert_int(sizes[3]).is_greater(sizes[2])


## The stretches lie end to end from the start of the dive and cover the path
## travelled, with less than one stretch still being recorded.
func _assert_one_entry_per_stretch_travelled(sim: DiveSimulation) -> void:
	var survey := sim.survey()
	assert_int(survey.size()).is_greater(1)
	var expected_start := 0.0
	for stretch in survey:
		assert_float(stretch.start).is_equal_approx(expected_start, 0.001)
		assert_float(stretch.length).is_equal_approx(survey[0].length, 0.001)
		expected_start = stretch.end()
	var last: SurveyStretch = survey.back()
	var unrecorded := sim.distance() - last.end()
	assert_float(unrecorded).is_greater_equal(0.0)
	assert_float(unrecorded).is_less(survey[0].length)


func test_the_survey_holds_one_entry_per_stretch_travelled() -> void:
	var sim := _dive(MediumLayout.first_dive(), 1.0, 500.0)

	_assert_one_entry_per_stretch_travelled(sim)


func test_one_long_step_records_every_stretch_it_covers() -> void:
	var sim := DiveSimulation.new(MediumLayout.uniform(Medium.sand()))
	sim.set_power(0.5)

	sim.advance(1000.0)

	_assert_one_entry_per_stretch_travelled(sim)


func test_without_power_nothing_new_is_recorded() -> void:
	var sim := _dive(MediumLayout.uniform(Medium.sand()), 0.5, 200.0)
	var recorded := sim.survey().size()

	sim.set_power(0.0)
	sim.advance(500.0)

	assert_int(sim.survey().size()).is_equal(recorded)
