# The autopilot's caption on a Station screen (GimballedStation), tested as
# plain view logic: what the top line says engaged, off, and just let go.
extends GdUnitTestSuite


func test_an_engaged_autopilot_reads_autopilot() -> void:
	assert_str(GimballedStation.autopilot_caption(true, INF)).is_equal("AUTOPILOT")


func test_an_autopilot_off_long_since_reads_autopilot_off_steadily() -> void:
	assert_str(GimballedStation.autopilot_caption(false, INF)).is_equal("AUTOPILOT OFF")


func test_just_after_letting_go_autopilot_off_flashes_then_holds() -> void:
	var shown := 0
	var blank := 0
	var t := 0.0
	while t < GimballedStation.DISENGAGE_FLASH_S:
		var caption := GimballedStation.autopilot_caption(false, t)
		assert_bool(caption in ["", "AUTOPILOT OFF"]).is_true()
		if caption.is_empty():
			blank += 1
		else:
			shown += 1
		t += 0.01

	assert_int(shown).is_greater(0)
	assert_int(blank).is_greater(0)
	assert_str(GimballedStation.autopilot_caption(false, GimballedStation.DISENGAGE_FLASH_S + 0.01)) \
			.is_equal("AUTOPILOT OFF")
