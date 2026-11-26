# The Reactor screen's two lanes, ACTIVE and STANDBY: what each MATCH reads.
extends GdUnitTestSuite


func test_a_match_reads_as_a_percentage() -> void:
	assert_str(PlasmaDisplay.match_text(1.0)).is_equal("MATCH 100%")
	assert_str(PlasmaDisplay.match_text(0.25)).is_equal("MATCH 25%")


func test_standby_reads_a_dash_until_the_boundary_approaching_call() -> void:
	var sim := DiveSimulation.new(MediumLayout.layered([[0.0, DiveTestKit.basalt()], [100.0, DiveTestKit.rock(4.0)]]))
	sim.set_power(0.5)
	sim.advance(0.1)
	assert_str(PlasmaDisplay.match_text(sim.standby_match())).is_equal("MATCH —")

	DiveTestKit.run_until(sim, &"boundary_approaching")

	assert_str(PlasmaDisplay.match_text(sim.standby_match())).is_not_equal("MATCH —")


func test_the_dash_draws_in_the_screens_font() -> void:
	assert_bool(ThemeDB.fallback_font.has_char("—".unicode_at(0))).is_true()
