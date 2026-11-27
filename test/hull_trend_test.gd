# Which way the hull's temperature is going, tested at the simulation's
# interface. Assert relationships, never tuned constants (ADR 0001).
extends GdUnitTestSuite


func test_a_hull_taking_more_heat_than_it_sheds_is_warming() -> void:
	var sim := DiveTestKit.run(DiveTestKit.heating(1.0), 20.0)

	assert_float(sim.hull_warming_rate()).is_greater(0.0)


func test_a_hot_hull_with_the_power_cut_is_cooling() -> void:
	var sim := DiveTestKit.run(DiveTestKit.heating(1.0), 60.0)
	sim.set_power(0.0)
	DiveTestKit.run(sim, 5.0)

	assert_float(sim.hull_warming_rate()).is_less(0.0)


func test_the_rate_is_how_fast_the_temperature_changes() -> void:
	var sim := DiveTestKit.run(DiveTestKit.heating(1.0), 20.0)
	var before := sim.vessel_temperature()
	sim.advance(1.0 / 60.0)

	assert_float(sim.hull_warming_rate()).is_equal_approx(
			(sim.vessel_temperature() - before) * 60.0, 0.001)


func test_more_heat_sent_outward_warms_the_hull_faster() -> void:
	var gentle := DiveTestKit.run(DiveTestKit.heating(0.4), 20.0)
	var hard := DiveTestKit.run(DiveTestKit.heating(1.0), 20.0)
	var into_column := DiveTestKit.run(DiveTestKit.heating(1.0, 1.0), 20.0)

	assert_float(hard.hull_warming_rate()).is_greater(gentle.hull_warming_rate())
	assert_float(into_column.hull_warming_rate()).is_less(hard.hull_warming_rate())


func test_a_hull_settled_at_its_heat_is_steady() -> void:
	# Standing still, so the rock round the hull stays as it is; the pumps and
	# Navigation still make a little heat for it to settle at.
	var early := DiveTestKit.run(DiveTestKit.heating(0.0), 5.0)
	var settled := DiveTestKit.run(DiveTestKit.heating(0.0), 1200.0)

	assert_float(early.hull_warming_rate()).is_greater(0.0)
	assert_float(absf(settled.hull_warming_rate())).is_less(early.hull_warming_rate() / 100.0)


func test_a_stranded_hull_warms_as_heat_soaks_in() -> void:
	var sim := DiveTestKit.heating(0.5, 1.0)
	DiveTestKit.strand(sim)
	# A moment only: this shallow, the rescue is soon there.
	sim.advance(1.0)

	assert_bool(sim.stranded()).is_true()
	assert_float(sim.hull_warming_rate()).is_greater(0.0)


func test_a_dive_that_has_stopped_has_no_trend_and_a_new_one_starts_steady() -> void:
	# Rock open enough that the tunnel behind never seals: the plasma lost,
	# the Lithocraft is brought home through it, and the dive is over.
	var sim := DiveSimulation.new(MediumLayout.uniform(DiveTestKit.rock(2.0, 2.0, 0.5)))
	sim.set_power(1.0)
	DiveTestKit.run(sim, 20.0)
	assert_float(sim.hull_warming_rate()).is_greater(0.0)
	DiveTestKit.lose_plasma(sim)
	assert_bool(sim.surfaced()).is_true()

	assert_float(sim.hull_warming_rate()).is_equal(0.0)

	sim.new_dive()

	assert_bool(sim.surfaced()).is_false()
	assert_float(sim.hull_warming_rate()).is_equal(0.0)
