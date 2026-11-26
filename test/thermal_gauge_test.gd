# The Thermal Station's instrument (ThermalGauge): the hull's temperature on
# a scale against what the hull bears, which way it is going, and where the
# heat is sent. Read from the simulation; relationships, never tuned values.
extends GdUnitTestSuite


func _sim(power: float, to_column := 0.0) -> DiveSimulation:
	var sim := DiveSimulation.new(MediumLayout.uniform(DiveTestKit.rock()))
	sim.set_power(power)
	sim.set_heat_split(to_column)
	return sim


func _gauge(sim: DiveSimulation) -> ThermalGauge:
	var gauge: ThermalGauge = auto_free(ThermalGauge.new())
	gauge.sim = sim
	return gauge


## Runs at full power, all heat outward, until the hull is at least this hot.
func _heated_to(kelvin: float) -> DiveSimulation:
	var sim := _sim(1.0)
	for i in 3000:
		if sim.vessel_temperature() >= kelvin:
			break
		sim.advance(0.1)
	assert_float(sim.vessel_temperature()).is_greater_equal(kelvin)
	return sim


func test_a_hotter_hull_stands_further_along_the_scale() -> void:
	var cool := _gauge(_sim(0.0))
	var warm := _gauge(DiveTestKit.run(_sim(1.0), 30.0))
	var hot := _gauge(DiveTestKit.run(_sim(1.0), 90.0))

	assert_float(cool.needle()).is_between(0.0, 1.0)
	assert_float(warm.needle()).is_greater(cool.needle())
	assert_float(hot.needle()).is_greater(warm.needle())


func test_the_needle_is_the_simulations_hull_temperature_on_the_scale() -> void:
	var sim := DiveTestKit.run(_sim(1.0), 30.0)
	var gauge := _gauge(sim)

	assert_float(gauge.needle()).is_equal_approx(gauge.place(sim.vessel_temperature()), 0.0001)
	assert_float(gauge.kelvin_at(gauge.needle())).is_equal_approx(sim.vessel_temperature(), 0.01)


func test_the_amber_and_red_ranges_start_at_the_simulations_own_thresholds() -> void:
	var sim := _sim(0.0)
	var gauge := _gauge(sim)

	assert_float(gauge.caution_from()).is_equal_approx(gauge.place(sim.hull_warning_temperature()), 0.0001)
	assert_float(gauge.warning_from()).is_equal_approx(gauge.place(sim.hull_damage_temperature()), 0.0001)
	# Cool, then amber, then red, with room on the scale for each.
	assert_float(gauge.needle()).is_less(gauge.caution_from())
	assert_float(gauge.caution_from()).is_less(gauge.warning_from())
	assert_float(gauge.warning_from()).is_less(1.0)


func test_the_hull_reads_in_the_colour_of_the_range_it_is_in() -> void:
	var probe := _sim(0.0)
	var cool := _gauge(probe)
	var caution := _gauge(_heated_to(probe.hull_warning_temperature()))
	var warning := _gauge(_heated_to(probe.hull_damage_temperature() + 1.0))

	assert_that(cool.meaning()).is_equal(StationTheme.NOW)
	assert_bool(caution.sim.hull_creep_rate() > 0.0).is_false()
	assert_that(caution.meaning()).is_equal(StationTheme.CAUTION)
	assert_bool(warning.sim.hull_creep_rate() > 0.0).is_true()
	assert_that(warning.meaning()).is_equal(StationTheme.WARNING)


func test_a_hull_past_the_end_of_the_scale_is_pinned_there() -> void:
	var gauge := _gauge(_sim(0.0))

	assert_float(gauge.place(gauge.scale_to() + 500.0)).is_equal(1.0)
	assert_float(gauge.place(gauge.scale_from() - 500.0)).is_equal(0.0)


func test_a_rising_and_a_falling_hull_are_told_apart() -> void:
	var rising := _gauge(DiveTestKit.run(_sim(1.0), 30.0))
	var falling_sim := DiveTestKit.run(_sim(1.0), 60.0)
	falling_sim.set_power(0.0)
	var falling := _gauge(DiveTestKit.run(falling_sim, 5.0))
	var steady := _gauge(DiveTestKit.run(_sim(0.0), 1200.0))

	assert_int(rising.trend()).is_equal(1)
	assert_int(falling.trend()).is_equal(-1)
	assert_int(steady.trend()).is_equal(0)
	# The trend mark points from the needle to where the hull is heading.
	assert_float(rising.trend_place()).is_greater(rising.needle())
	assert_float(falling.trend_place()).is_less(falling.needle())
	assert_float(steady.trend_place()).is_equal(steady.needle())


func test_a_faster_warming_hull_has_a_longer_trend_mark() -> void:
	var gentle := _gauge(DiveTestKit.run(_sim(0.4), 20.0))
	var hard := _gauge(DiveTestKit.run(_sim(1.0), 20.0))

	assert_float(hard.trend_place() - hard.needle()).is_greater(gentle.trend_place() - gentle.needle())


func test_the_split_shows_where_the_heat_goes_against_the_crews_setting() -> void:
	var out := _gauge(DiveTestKit.run(_sim(0.5, 0.0), 5.0))
	var some := _gauge(DiveTestKit.run(_sim(0.5, 0.3), 5.0))
	var most := _gauge(DiveTestKit.run(_sim(0.5, 0.8), 5.0))

	assert_float(out.column_share()).is_equal(0.0)
	assert_float(some.column_share()).is_greater(0.0)
	assert_float(most.column_share()).is_greater(some.column_share())
	assert_float(most.column_share()).is_less(1.0)
	assert_float(some.split_set()).is_equal_approx(0.3, 0.0001)
	# The share drawn is the simulation's own heat, not the setting repeated.
	assert_float(some.column_share()).is_equal_approx(
			some.sim.heat_to_column() / some.sim.heat_produced(), 0.0001)


func test_the_gauge_lies_whole_in_a_screens_body_cool_and_hot() -> void:
	var probe := _sim(0.0)
	for sim: DiveSimulation in [probe, _heated_to(probe.hull_damage_temperature() + 1.0)]:
		var screen: StationScreen = auto_free(StationScreen.new())
		add_child(screen)
		var gauge := ThermalGauge.new()
		gauge.sim = sim
		screen.set_instrument(gauge)
		screen.show_lines(["one", "two", "three", "four"])
		await get_tree().process_frame
		await get_tree().process_frame

		assert_bool(gauge.get_global_rect().is_equal_approx(screen.body_rect())).is_true()
		# Every part of the gauge lies whole inside the body it was given.
		for part: Rect2 in gauge.parts():
			assert_bool(Rect2(Vector2.ZERO, gauge.size).grow(0.5).encloses(part)).override_failure_message(
					"%s lies off the gauge (%s)" % [part, gauge.size]).is_true()


func test_the_thermal_station_shows_the_gauge_as_its_instrument() -> void:
	var habitat: Node3D = auto_free((load("res://view/habitat.tscn") as PackedScene).instantiate())
	add_child(habitat)
	habitat.set_physics_process(false)
	habitat._physics_process(1.0 / 60.0)
	await get_tree().process_frame
	await get_tree().process_frame

	var thermal: GimballedStation = null
	for child in habitat.get_children():
		if child is GimballedStation and (child as GimballedStation).station_name == "Thermal":
			thermal = child
	var gauges := thermal.screen().root().find_children("*", "ThermalGauge", true, false)
	assert_int(gauges.size()).is_equal(1)
	assert_object((gauges[0] as ThermalGauge).sim).is_same(habitat.simulation())
	# The hull's reading is the gauge's now: no status line repeats it, and
	# integrity and creep keep their line.
	var texts := "\n".join(thermal.screen().texts())
	assert_str(texts).contains("Integrity")
	assert_str(texts).contains("creep")
	assert_str(texts).not_contains("[#")
	assert_str(texts).not_contains("bears")
