# The frame every Station screen shares (StationScreen) and the key list
# beside it (KeyList): built in the tree, laid out by Godot's Containers,
# and read back as rectangles in the screen's own pixels.
extends GdUnitTestSuite

const Habitat := preload("res://view/habitat.gd")


func _screen() -> StationScreen:
	var screen: StationScreen = auto_free(StationScreen.new())
	screen.set_station_name("Test")
	add_child(screen)
	return screen


func _picture() -> Texture2D:
	return ImageTexture.create_from_image(Image.create(64, 32, false, Image.FORMAT_RGB8))


func _whole() -> Rect2:
	return Rect2(Vector2.ZERO, Vector2(StationScreen.SIZE))


func _lamps(lit: bool) -> Array[Dictionary]:
	var lamps: Array[Dictionary] = [{label = "HEAD WORN", lit = lit}, {label = "SHIFT DUE", lit = false}]
	return lamps


func test_the_header_strip_is_at_the_top_with_the_name_the_autopilot_and_the_lamps() -> void:
	var screen := _screen()
	screen.set_autopilot("AUTOPILOT", StationTheme.ENGAGED)
	screen.show_lamps(_lamps(false))
	screen.show_lines(["first", "second"])
	await DiveTestKit.laid_out(self)

	var rects := screen.text_rects()
	assert_str(screen.texts()[0]).is_equal("Test   AUTOPILOT")
	assert_float(rects[0].position.y).is_equal_approx(0.0, 0.5)
	assert_float(rects[0].size.x).is_equal_approx(StationScreen.SIZE.x, 0.5)
	for i in range(1, rects.size()):
		assert_float(rects[i].position.y).is_greater_equal(rects[i - 1].end.y - 0.5)
	assert_array(Array(screen.lamp_labels())).is_equal(["HEAD WORN", "SHIFT DUE"])


func test_a_lamp_is_lit_and_cleared_keeping_its_place() -> void:
	var screen := _screen()
	screen.show_lamps(_lamps(false))
	assert_array(Array(screen.lit_lamps())).is_empty()

	screen.show_lamps(_lamps(true))
	assert_array(Array(screen.lit_lamps())).is_equal(["HEAD WORN"])
	assert_array(Array(screen.lamp_labels())).is_equal(["HEAD WORN", "SHIFT DUE"])

	screen.show_lamps(_lamps(false))
	assert_array(Array(screen.lit_lamps())).is_empty()
	assert_array(Array(screen.lamp_labels())).is_equal(["HEAD WORN", "SHIFT DUE"])


func test_every_reading_lies_whole_on_the_screen_however_many_lines() -> void:
	for with_instrument in [false, true]:
		for count in [1, 6, 12, 20]:
			var screen := _screen()
			if with_instrument:
				var pictures: Array[Texture2D] = [_picture()]
				screen.show_pictures(pictures)
			var lines := []
			for i in count:
				lines.append("A line of a Station's reading, long enough to run quite wide %d" % i)
			screen.show_lines(lines)
			screen.set_footer("Time x1")
			await DiveTestKit.laid_out(self)

			var rects := screen.text_rects()
			assert_int(rects.size()).is_equal(count + 2)
			for rect in rects:
				assert_bool(_whole().grow(0.5).encloses(rect)).override_failure_message(
						"%d lines, instrument %s: %s runs off the screen" % [count, with_instrument, rect]
				).is_true()
				assert_float(rect.size.y).is_greater(0.0)


func test_a_line_too_long_for_the_screen_shrinks_the_text_until_it_is_whole() -> void:
	var screen := _screen()
	screen.show_lines(["short"])
	var roomy := screen.status_font_size()

	screen.show_lines(["a reading that goes on and on, ".repeat(6)])

	assert_int(screen.status_font_size()).is_less(roomy)
	var width := ThemeDB.fallback_font.get_string_size("a reading that goes on and on, ".repeat(6),
			HORIZONTAL_ALIGNMENT_LEFT, -1, screen.status_font_size()).x
	assert_float(width).is_less_equal(StationScreen.SIZE.x - 2.0 * StationScreen.MARGIN_PX)


func test_an_instrument_fills_the_body_between_the_header_and_the_status_lines() -> void:
	var screen := _screen()
	var instrument := Control.new()
	screen.set_instrument(instrument)
	screen.show_lines(["first", "second"])
	await DiveTestKit.laid_out(self)

	var rects := screen.text_rects()
	var body := screen.body_rect()
	assert_bool(instrument.get_global_rect().is_equal_approx(body)).is_true()
	assert_float(body.position.y).is_greater_equal(rects[0].end.y - 0.5)
	assert_float(body.end.y).is_less_equal(rects[1].position.y + 0.5)
	# The instrument has the larger part of the screen.
	assert_float(body.size.y).is_greater(StationScreen.SIZE.y / 2.0)
	assert_float(body.size.x).is_equal_approx(StationScreen.SIZE.x, 0.5)


func test_pictures_side_by_side_keep_their_shape_inside_the_body() -> void:
	var screen := _screen()
	var pictures: Array[Texture2D] = [_picture(), _picture()]
	screen.show_pictures(pictures)
	screen.show_lines(["first"])
	await DiveTestKit.laid_out(self)

	var left := screen.picture_rect(0)
	var right := screen.picture_rect(1)
	assert_int(screen.picture_count()).is_equal(2)
	assert_bool(screen.body_rect().grow(0.5).encloses(left)).is_true()
	assert_bool(screen.body_rect().grow(0.5).encloses(right)).is_true()
	assert_float(left.end.x).is_less_equal(right.position.x)
	assert_float(left.size.x / left.size.y).is_equal_approx(2.0, 0.01)


## Every Label a frame holds is written in a colour of the Theme, whatever
## the Station shows on it.
func test_every_label_of_a_frame_is_written_in_a_theme_colour() -> void:
	var screen := _screen()
	screen.set_autopilot("AUTOPILOT OFF", StationTheme.CAUTION)
	screen.show_lamps(_lamps(true))
	screen.show_lines(["now", ["aimed for", StationTheme.SELECTED], ["working", StationTheme.ENGAGED],
			["caution", StationTheme.CAUTION], ["warning", StationTheme.WARNING],
			["legend", StationTheme.LEGEND]])
	screen.set_footer("Time x1")
	await DiveTestKit.laid_out(self)

	var labels := screen.root().find_children("*", "Label", true, false)
	assert_int(labels.size()).is_greater(8)
	for label: Label in labels:
		assert_bool(StationTheme.has(label.get_theme_color(&"font_color"))).override_failure_message(
				"'%s' is written in %s" % [label.text, label.get_theme_color(&"font_color")]).is_true()


func test_every_stations_key_list_shows_every_key_whole() -> void:
	for station in Habitat.STATIONS:
		if station[2] == &"":
			continue
		var bindings := KeyMap.bindings_at(station[2])
		var keys: KeyList = auto_free(KeyList.new())
		add_child(keys)
		keys.show_keys(bindings)
		await DiveTestKit.laid_out(self)

		var whole := Rect2(Vector2.ZERO, Vector2(keys.size))
		var rows := keys.row_rects()
		assert_int(rows.size()).is_equal(bindings.size())
		for i in rows.size():
			assert_bool(whole.encloses(rows[i])).override_failure_message(
					"%s: '%s' is cut off the key list (%s)" % [station[0], bindings[i].does, rows[i]]).is_true()
			if i > 0:
				assert_float(rows[i].position.y).is_greater_equal(rows[i - 1].end.y - 0.5)
		for words in keys.does_labels():
			# Wrapped onto as many lines as it needs, none hidden.
			assert_int(words.get_visible_line_count()).is_equal(words.get_line_count())
			assert_bool(whole.encloses(words.get_global_rect())).is_true()


func test_a_key_list_longer_than_any_station_has_still_shows_every_key_whole() -> void:
	var bindings: Array[Dictionary] = []
	for i in 14:
		bindings.append({keys = [KEY_Z, KEY_X], does = "a binding with a good deal to say about itself %d" % i})
	var keys: KeyList = auto_free(KeyList.new())
	add_child(keys)
	keys.show_keys(bindings)
	await DiveTestKit.laid_out(self)

	var whole := Rect2(Vector2.ZERO, Vector2(keys.size))
	for row in keys.row_rects():
		assert_bool(whole.encloses(row)).is_true()


## The Stations of a Habitat a few steps into the First dive, laid out.
func _habitat_stations() -> Array[GimballedStation]:
	var habitat := DiveTestKit.staged_habitat(self)
	habitat.simulation().set_power(1.0)
	for i in 5:
		habitat._physics_process(1.0 / 60.0)
	await DiveTestKit.laid_out(self)
	return DiveTestKit.stations(habitat)


func test_no_station_in_the_habitat_floats_text_and_every_reading_lies_on_its_screen() -> void:
	var stations := await _habitat_stations()

	assert_int(stations.size()).is_equal(DiveSimulation.STATIONS.size())
	for station in stations:
		assert_array(station.find_children("*", "Label3D", true, false)).override_failure_message(
				"%s floats text off its screen" % station.station_name).is_empty()
		var face := station.face()
		# Its name and autopilot, and at least one reading of its own.
		assert_int(face.readings.size()).is_greater(2)
		assert_str(station.reading(0)).starts_with(station.station_name)
		for i in face.readings.size():
			assert_bool(face.bounds.grow(0.001).encloses(face.readings[i])).override_failure_message(
					"%s: reading %d '%s' lies off its screen" % [station.station_name, i, station.reading(i)]
			).is_true()


func test_every_label_on_every_station_of_the_habitat_is_written_in_a_theme_colour() -> void:
	var stations := await _habitat_stations()

	for station in stations:
		var labels := station.screen().root().find_children("*", "Label", true, false)
		labels.append_array(station.key_list().root().find_children("*", "Label", true, false))
		assert_int(labels.size()).is_greater(3)
		for label: Label in labels:
			if label.get_parent() is TextureRect:
				continue  # a key's glyph, part of the key's picture
			assert_bool(StationTheme.has(label.get_theme_color(&"font_color"))).override_failure_message(
					"%s: '%s' is written in %s" % [station.station_name, label.text,
					label.get_theme_color(&"font_color")]).is_true()


func test_the_reactors_worn_head_lamp_follows_the_simulation_onto_its_screen() -> void:
	var habitat := DiveTestKit.staged_habitat(self)
	var reactor := DiveTestKit.station(habitat, "Reactor")
	habitat._physics_process(1.0 / 60.0)
	assert_array(Array(reactor.screen().lit_lamps())).not_contains([CautionLamps.HEAD_WORN])

	DiveTestKit.wear_head_gently(habitat.simulation(), 0.3)
	habitat._physics_process(1.0 / 60.0)

	assert_array(Array(reactor.screen().lit_lamps())).contains([CautionLamps.HEAD_WORN])
