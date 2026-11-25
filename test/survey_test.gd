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


## Test values only: two Media with nothing in common.
func _chalk() -> Medium:
	return Medium.new(&"chalk", 1.0, 0.5, 0.3, 300.0, 1.0, {&"calcite": 1.0}, 0.4)


func _basalt() -> Medium:
	return Medium.new(&"basalt", 1.0, 0.5, 0.05, 300.0, 1.0,
			{&"pyroxene": 0.5, &"plagioclase": 0.5}, 0.8)


func _assert_composition_close(actual: Dictionary, expected: Dictionary) -> void:
	assert_array(actual.keys()).contains_exactly_in_any_order(expected.keys())
	for mineral in expected:
		assert_float(actual[mineral]).is_equal_approx(expected[mineral], 0.001)


func test_a_stretch_records_the_composition_of_the_medium_it_passed_through() -> void:
	for medium in [_chalk(), _basalt(), Medium.granite()]:
		var sim := _dive(MediumLayout.uniform(medium), 0.3, 300.0)

		var survey := sim.survey()
		assert_int(survey.size()).is_greater(0)
		for stretch in survey:
			assert_str(stretch.medium_name).is_equal(medium.name)
			_assert_composition_close(stretch.composition, medium.composition)


func test_after_a_boundary_the_survey_records_the_new_medium() -> void:
	var layout := MediumLayout.layered([[0.0, _chalk()], [40.0, _basalt()]])
	var sim := _dive(layout, 0.3, 600.0)

	var survey := sim.survey()
	var first: SurveyStretch = survey.front()
	var last: SurveyStretch = survey.back()
	assert_float(last.start).is_greater(40.0)
	_assert_composition_close(first.composition, _chalk().composition)
	_assert_composition_close(last.composition, _basalt().composition)


func test_a_stretch_across_a_boundary_holds_some_of_each_medium() -> void:
	var survey := _dive(MediumLayout.uniform(_chalk()), 0.3, 300.0).survey()
	var stretch_length: float = survey[0].length
	# A Boundary a quarter of the way into the third stretch.
	var boundary := stretch_length * 2.25
	var layout := MediumLayout.layered([[0.0, _chalk()], [boundary, _basalt()]])

	var straddling: SurveyStretch = _dive(layout, 0.3, 600.0).survey()[2]

	assert_float(straddling.composition[&"calcite"]).is_between(0.01, 0.99)
	assert_float(straddling.composition[&"pyroxene"]).is_between(0.01, 0.99)
	# Mostly basalt by length, so it is named for basalt.
	assert_str(straddling.medium_name).is_equal(&"basalt")


func test_every_stretch_has_a_quality_and_an_untouched_column_is_pristine() -> void:
	# By default Thermal sends all heat outward, so nothing heats the Column and
	# every stretch of this dive is recorded at the best quality there is.
	var survey := _dive(MediumLayout.first_dive(), 1.0, 500.0).survey()

	assert_int(survey.size()).is_greater(1)
	for stretch in survey:
		assert_float(stretch.quality).is_equal_approx(1.0, 0.0001)


func test_the_survey_handed_out_is_a_copy() -> void:
	var sim := _dive(MediumLayout.uniform(Medium.sand()), 0.5, 200.0)
	var recorded := sim.survey().size()

	sim.survey().clear()

	assert_int(sim.survey().size()).is_equal(recorded)


func test_without_power_nothing_new_is_recorded() -> void:
	var sim := _dive(MediumLayout.uniform(Medium.sand()), 0.5, 200.0)
	var recorded := sim.survey().size()

	sim.set_power(0.0)
	sim.advance(500.0)

	assert_int(sim.survey().size()).is_equal(recorded)
