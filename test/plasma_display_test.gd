# The Reactor screen's two lanes, ACTIVE and STANDBY: what each lane reads of
# its Residual against the Band.
extends GdUnitTestSuite


func test_a_residual_reads_beside_the_band_it_is_held_against() -> void:
	assert_str(PlasmaDisplay.residual_text(0.0, 0.2)).is_equal("RESIDUAL 0.00  BAND 0.20")
	assert_str(PlasmaDisplay.residual_text(0.456, 0.1)).is_equal("RESIDUAL 0.46  BAND 0.10")


func test_standby_reads_a_dash_until_the_boundary_approaching_call() -> void:
	var sim := DiveSimulation.new(MediumLayout.layered([[0.0, DiveTestKit.basalt()], [100.0, DiveTestKit.rock(4.0)]]))
	sim.set_power(0.5)
	sim.advance(0.1)
	var standby := DiveSimulation.CHANNEL_STANDBY
	assert_str(PlasmaDisplay.residual_text(sim.residual(standby), sim.band())).is_equal("RESIDUAL —")

	DiveTestKit.run_until(sim, &"boundary_approaching")

	assert_str(PlasmaDisplay.residual_text(sim.residual(standby), sim.band())).is_not_equal("RESIDUAL —")


func test_the_dash_draws_in_the_screens_font() -> void:
	assert_bool(ThemeDB.fallback_font.has_char("—".unicode_at(0))).is_true()
