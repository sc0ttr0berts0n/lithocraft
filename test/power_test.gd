# The Reactor and the power budget, tested at the simulation's interface.
# Assert relationships, never tuned constants (ADR 0001).
extends GdUnitTestSuite


func _sim(power: float, to_column := 0.0) -> DiveSimulation:
	var sim := DiveSimulation.new(MediumLayout.uniform(DiveTestKit.rock()))
	sim.set_power(power)
	sim.set_heat_split(to_column)
	return sim


func test_power_drawn_never_exceeds_what_the_reactor_supplies() -> void:
	for quiet in [false, true]:
		for power in [0.0, 0.5, 1.0]:
			for to_column in [0.0, 0.5, 1.0]:
				var sim := _sim(power, to_column)
				sim.set_quiet_ship(quiet)
				for i in 40:
					sim.advance(0.5)
					var drawn: float = sim.drive_draw() + sim.thermal_draw() + sim.navigation_draw()
					assert_float(drawn).is_equal_approx(sim.power_drawn(), 1e-9)
					assert_float(sim.power_drawn()).is_less_equal(sim.reactor_output() + 1e-9)


func test_asking_the_drive_for_more_than_the_budget_throttles_only_the_drive() -> void:
	var modest := DiveTestKit.run(_sim(0.2, 1.0), 5.0, 0.5)
	var greedy := DiveTestKit.run(_sim(1.0, 1.0), 5.0, 0.5)

	assert_float(greedy.power_requested()).is_greater(greedy.reactor_output())
	assert_float(greedy.drive_draw()).is_less(greedy.drive_request())
	assert_float(greedy.drive_supplied()).is_less(1.0)
	# Thermal and Navigation get what they got before the Drive asked for more.
	assert_float(greedy.thermal_draw()).is_equal_approx(modest.thermal_draw(), 1e-9)
	assert_float(greedy.navigation_draw()).is_equal_approx(modest.navigation_draw(), 1e-9)
	assert_float(greedy.thermal_supplied()).is_equal(1.0)
	assert_float(greedy.navigation_supplied()).is_equal(1.0)


func test_a_drive_within_the_budget_is_not_starved() -> void:
	var sim := DiveTestKit.run(_sim(0.2), 5.0, 0.5)

	assert_float(sim.drive_draw()).is_equal_approx(sim.drive_request(), 1e-9)
	assert_float(sim.drive_supplied()).is_equal(1.0)


func test_pumping_heat_into_the_column_takes_power_from_a_full_drive() -> void:
	var outward := DiveTestKit.run(_sim(1.0, 0.0), 5.0, 0.5)
	var into_column := DiveTestKit.run(_sim(1.0, 1.0), 5.0, 0.5)

	assert_float(into_column.thermal_draw()).is_greater(outward.thermal_draw())
	assert_float(into_column.drive_draw()).is_less(outward.drive_draw())
	assert_float(into_column.speed()).is_less(outward.speed())


func test_thermal_draw_makes_heat_too() -> void:
	var idle_pumps := DiveTestKit.run(_sim(0.0, 0.0), 5.0, 0.5)
	var busy_pumps := DiveTestKit.run(_sim(0.0, 1.0), 5.0, 0.5)

	assert_float(busy_pumps.heat_produced()).is_greater(idle_pumps.heat_produced())


func test_an_idling_head_supplies_less_and_starves_thermal_before_navigation() -> void:
	var sim := DiveTestKit.run(_sim(1.0, 1.0), 2.0, 0.5)
	var running_output := sim.reactor_output()
	sim.set_quiet_ship(true)
	DiveTestKit.run(sim, 30.0, 0.5)

	assert_float(sim.reactor_output()).is_less(running_output)
	assert_float(sim.thermal_supplied()).is_less(1.0)
	assert_float(sim.navigation_supplied()).is_equal(1.0)


func test_starved_thermal_sends_less_heat_into_the_column_than_the_split_asks() -> void:
	var sim := _sim(0.0, 1.0)
	sim.set_quiet_ship(true)
	DiveTestKit.run(sim, 30.0, 0.5)

	assert_float(sim.thermal_supplied()).is_less(1.0)
	assert_float(sim.heat_to_column()).is_less(sim.heat_produced())
	assert_float(sim.heat_outward()).is_greater(0.0)
