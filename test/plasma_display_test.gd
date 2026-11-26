# The Reactor screen's two lanes, ACTIVE and STANDBY: what each lane reads of
# its Residual against the Band.
extends GdUnitTestSuite


func test_a_residual_reads_beside_the_band_it_is_held_against() -> void:
	assert_str(PlasmaDisplay.residual_text(0.0, 0.2)).is_equal("RESIDUAL 0.00  BAND 0.20")
	assert_str(PlasmaDisplay.residual_text(0.456, 0.1)).is_equal("RESIDUAL 0.46  BAND 0.10")


func test_standby_reads_a_dash_until_the_boundary_ahead_is_scanned() -> void:
	var sim := DiveSimulation.new(MediumLayout.layered([[0.0, DiveTestKit.basalt()], [100.0, DiveTestKit.rock(4.0)]]))
	sim.set_power(0.5)
	sim.advance(0.1)
	var standby := DiveSimulation.CHANNEL_STANDBY
	assert_str(PlasmaDisplay.residual_text(sim.residual(standby), sim.band())).is_equal("RESIDUAL —")

	DiveTestKit.quiet_scan(sim)

	assert_str(PlasmaDisplay.residual_text(sim.residual(standby), sim.band())).is_not_equal("RESIDUAL —")


func test_the_guess_reads_how_sure_it_is_and_says_so_when_there_is_no_scan() -> void:
	assert_str(PlasmaDisplay.guess_text(1.234, 0.567, 0.62)).is_equal("GUESS 1.23 Hz  x0.57  SURE 62%")
	assert_str(PlasmaDisplay.guess_text(NAN, NAN, 0.0)).is_equal("GUESS —  NO SCAN")


func test_the_countdown_reads_its_plus_or_minus_and_beyond_five_minutes_when_the_scan_cannot_say() -> void:
	assert_str(PlasmaDisplay.countdown_text(42.4, 5.2, 300.0)).is_equal("BOUNDARY 42 s ±6")
	assert_str(PlasmaDisplay.countdown_text(125.0, 20.6, 300.0)).is_equal("BOUNDARY 125 s ±21")
	assert_str(PlasmaDisplay.countdown_text(INF, INF, 300.0)).is_equal("BOUNDARY > 5 min")


func test_the_plus_or_minus_draws_in_the_screens_font() -> void:
	assert_bool(ThemeDB.fallback_font.has_char("±".unicode_at(0))).is_true()


func test_the_dash_draws_in_the_screens_font() -> void:
	assert_bool(ThemeDB.fallback_font.has_char("—".unicode_at(0))).is_true()
