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


func test_the_reactor_lamp_for_a_worn_head_is_dark_on_a_whole_head_and_lights_as_the_head_wears() -> void:
	var sim := Scenario.first_dive().start()
	assert_array(_labels(sim, DiveSimulation.STATION_REACTOR)).contains([CautionLamps.HEAD_WORN])
	assert_array(_lit(sim, DiveSimulation.STATION_REACTOR)).not_contains([CautionLamps.HEAD_WORN])

	DiveTestKit.wear_head_gently(sim, 0.3)

	assert_array(_lit(sim, DiveSimulation.STATION_REACTOR)).contains([CautionLamps.HEAD_WORN])


func test_a_stations_lamps_keep_their_places_lit_or_not() -> void:
	var sim := Scenario.first_dive().start()
	var before := {}
	for station in DiveSimulation.STATIONS:
		before[station] = _labels(sim, station)

	DiveTestKit.wear_head_gently(sim, 0.3)
	sim.set_power(1.0)
	DiveTestKit.run(sim, 20.0, 0.1)

	assert_array(_lit(sim, DiveSimulation.STATION_REACTOR)).is_not_empty()
	for station in DiveSimulation.STATIONS:
		assert_array(_labels(sim, station)).is_equal(before[station])


func test_only_the_reactor_shows_the_worn_head() -> void:
	var sim := Scenario.first_dive().start()
	for station in DiveSimulation.STATIONS:
		if station != DiveSimulation.STATION_REACTOR:
			assert_array(_labels(sim, station)).not_contains([CautionLamps.HEAD_WORN])


func test_the_reactors_out_of_band_lamp_lights_past_a_boundary_and_clears_once_the_wobble_is_cancelled() -> void:
	var sim := Scenario.first_dive().start()
	sim.set_power(0.5)
	assert_array(_labels(sim, DiveSimulation.STATION_REACTOR)).contains([CautionLamps.OUT_OF_BAND])
	DiveTestKit.run_until(sim, &"boundary_crossed", 600.0, [], 0.25)

	assert_array(_lit(sim, DiveSimulation.STATION_REACTOR)).contains([CautionLamps.OUT_OF_BAND])

	DiveTestKit.cancel_wobble(sim)
	assert_array(_lit(sim, DiveSimulation.STATION_REACTOR)).not_contains([CautionLamps.OUT_OF_BAND])


func test_the_reactors_hot_lamp_lights_only_while_the_hot_hulls_narrower_band_tells() -> void:
	var sim := DiveSimulation.new(MediumLayout.uniform(DiveTestKit.rock()))
	var cool_band := DiveTestKit.run(DiveSimulation.new(MediumLayout.uniform(DiveTestKit.rock())), 1.0).band()
	sim.set_power(1.0)
	DiveTestKit.run(sim, 300.0)
	# Hot, the Band narrowed, but the Residual flat: nothing to caution.
	assert_float(sim.band()).is_less(cool_band)
	assert_array(_lit(sim, DiveSimulation.STATION_REACTOR)).is_empty()

	# A Residual a cool Head would bear, outside this one's Band.
	DiveTestKit.tune(sim, DiveSimulation.CHANNEL_ACTIVE, DiveTestKit.wobble(sim) + Vector2(0.0, (sim.band() + cool_band) / 2.0))

	assert_array(_lit(sim, DiveSimulation.STATION_REACTOR)).contains_exactly_in_any_order(
			[CautionLamps.HOT, CautionLamps.OUT_OF_BAND])

	# The hull cools, the Band eases round the same Residual, and both clear.
	sim.set_power(0.0)
	DiveTestKit.run(sim, 900.0)
	assert_array(_lit(sim, DiveSimulation.STATION_REACTOR)).is_empty()
