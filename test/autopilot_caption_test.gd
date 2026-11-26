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


func test_the_autopilots_word_is_coloured_by_what_it_means() -> void:
	assert_str(GimballedStation.autopilot_meaning(true, INF)).is_equal(StationTheme.ENGAGED)
	assert_str(GimballedStation.autopilot_meaning(false, 0.1)).is_equal(StationTheme.CAUTION)
	assert_str(GimballedStation.autopilot_meaning(false, INF)).is_equal(StationTheme.NOW)


## A sound's loudest sample, as a share of full scale.
func _peak(wav: AudioStreamWAV) -> float:
	var peak := 0
	for i in wav.data.size() / 2:
		peak = maxi(peak, absi(wav.data.decode_s16(i * 2)))
	return peak / 32767.0


## How abruptly a sound starts: its loudest sample in its first 5 ms, as a
## share of its peak.
func _attack(wav: AudioStreamWAV) -> float:
	var early := 0
	for i in int(wav.mix_rate * 0.005):
		early = maxi(early, absi(wav.data.decode_s16(i * 2)))
	return early / 32767.0 / _peak(wav)


## "I hate the shrillness": the disconnect is softer than any Station's call.
func test_the_disconnect_tone_is_lower_quieter_and_softer_edged_than_a_stations_call() -> void:
	var disconnect := GimballedStation.disengage_tone()
	var Habitat := preload("res://view/habitat.gd")
	var highest_call := 0.0
	for station in Habitat.STATIONS:
		highest_call = maxf(highest_call, station[3])

	for note in GimballedStation.DISENGAGE_NOTES:
		assert_float(note).is_less(highest_call)
	assert_float(_peak(disconnect)).is_less(_peak(GimballedStation.call_tone(highest_call, 1)))
	assert_float(_attack(disconnect)).is_less(_attack(GimballedStation.call_tone(highest_call, 1)))


func test_the_disconnect_tone_still_falls_so_it_is_not_taken_for_a_call() -> void:
	var notes := GimballedStation.DISENGAGE_NOTES
	assert_int(notes.size()).is_greater(1)
	for i in range(1, notes.size()):
		assert_float(notes[i]).is_less(notes[i - 1])
