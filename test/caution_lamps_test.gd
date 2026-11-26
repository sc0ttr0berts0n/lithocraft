# Caution lamps (CautionLamps): each Station's labelled lamps, lit and
# cleared by the simulation's state alone.
extends GdUnitTestSuite


func _lit(sim: DiveSimulation, station: StringName) -> Array:
	var lit := []
	for lamp in CautionLamps.of(sim, station):
		if lamp.lit:
			lit.append(lamp.label)
	return lit


func _labels(sim: DiveSimulation, station: StringName) -> Array:
	return CautionLamps.of(sim, station).map(func(lamp: Dictionary) -> String: return lamp.label)


func test_a_fresh_dive_lights_no_lamp_at_any_station() -> void:
	var sim := Scenario.first_dive().start()

	for station in DiveSimulation.STATIONS:
		assert_array(_lit(sim, station)).is_empty()


func test_the_reactor_lamp_for_a_worn_head_lights_as_the_head_wears_and_clears_when_it_is_whole() -> void:
	var sim := Scenario.first_dive().start()
	assert_array(_labels(sim, DiveSimulation.STATION_REACTOR)).contains([CautionLamps.HEAD_WORN])
	assert_array(_lit(sim, DiveSimulation.STATION_REACTOR)).not_contains([CautionLamps.HEAD_WORN])

	sim.debug_wear_head(0.3)
	assert_array(_lit(sim, DiveSimulation.STATION_REACTOR)).contains([CautionLamps.HEAD_WORN])

	sim.debug_wear_head(-1.0)
	assert_array(_lit(sim, DiveSimulation.STATION_REACTOR)).not_contains([CautionLamps.HEAD_WORN])


func test_a_stations_lamps_keep_their_places_lit_or_not() -> void:
	var sim := Scenario.first_dive().start()
	for station in DiveSimulation.STATIONS:
		var before := _labels(sim, station)
		sim.debug_wear_head(0.3)
		sim.set_power(1.0)
		DiveTestKit.run(sim, 20.0, 0.1)

		assert_array(_labels(sim, station)).is_equal(before)


func test_only_the_reactor_shows_the_worn_head() -> void:
	var sim := Scenario.first_dive().start()
	for station in DiveSimulation.STATIONS:
		if station != DiveSimulation.STATION_REACTOR:
			assert_array(_labels(sim, station)).not_contains([CautionLamps.HEAD_WORN])
