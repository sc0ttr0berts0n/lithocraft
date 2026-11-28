# The Drive's primary flight display: its instruments are laid out on the
# display without overlapping, and each is a reading of its own that the
# centre dot points at from the Drive's working pose.
extends GdUnitTestSuite

const BORE_RADIUS := 0.8


## A Station in the tree, laid out, showing the flight display's layout over
## a stand-in picture of its shape, as the Habitat shows the Drive's.
func _drive() -> GimballedStation:
	var station: GimballedStation = auto_free(GimballedStation.new())
	station.station_name = "Drive"
	add_child(station)
	station.show_display(ImageTexture.create_from_image(Image.create(
			FlightDisplay.SIZE.x / 8, FlightDisplay.SIZE.y / 8, false, Image.FORMAT_RGB8)),
			FlightDisplay.instrument_shares())
	station.show_reading("Following the Course")
	await get_tree().process_frame
	await get_tree().process_frame
	return station


func test_the_instruments_lie_on_the_display_apart() -> void:
	var display := Rect2(Vector2.ZERO, Vector2(FlightDisplay.SIZE))
	var names := FlightDisplay.INSTRUMENTS.keys()
	for name: StringName in [&"attitude", &"speed", &"depth", &"heading", &"power", &"grip", &"steering"]:
		assert_array(names).contains([name])
	for i in names.size():
		var rect: Rect2 = FlightDisplay.INSTRUMENTS[names[i]]
		assert_bool(display.encloses(rect)).is_true()
		for j in range(i + 1, names.size()):
			assert_bool(rect.intersects(FlightDisplay.INSTRUMENTS[names[j]])).is_false()


func test_the_tapes_stand_as_an_airliner_s_round_the_attitude() -> void:
	var at := FlightDisplay.INSTRUMENTS
	var attitude: Rect2 = at[&"attitude"]

	assert_float(at[&"speed"].end.x).is_less_equal(attitude.position.x)
	assert_float(at[&"depth"].position.x).is_greater_equal(attitude.end.x)
	assert_float(at[&"heading"].position.y).is_greater_equal(attitude.end.y)


func test_each_instrument_is_a_reading_on_the_drive_s_screen() -> void:
	var station := await _drive()
	var readings := station.face().readings
	var named := []
	for i in readings.size():
		if station.instrument(i) != &"":
			named.append(station.instrument(i))
			assert_bool(station.is_display(i)).is_false()
			assert_str(station.reading(i)).is_empty()

	assert_array(named).contains_exactly_in_any_order(FlightDisplay.INSTRUMENTS.keys())


func test_the_dot_on_an_instrument_points_at_it_not_the_display_under_it() -> void:
	var station := await _drive()
	var face := station.face()
	var faces: Array[Pointing.Face] = [face]
	var eye := station.pose().origin
	for i in face.readings.size():
		var name := station.instrument(i)
		if name == &"":
			continue
		var look := (face.transform * Vector3(face.readings[i].get_center().x,
				face.readings[i].get_center().y, 0.0) - eye).normalized()

		var under := Pointing.under(eye, look, faces, BORE_RADIUS)

		assert_str(String(station.instrument(under.reading))).is_equal(String(name))


func test_an_instrument_on_the_display_s_left_lies_on_the_crew_s_left() -> void:
	var station := await _drive()
	var readings := station.face().readings
	var place := {}
	for i in readings.size():
		if station.instrument(i) != &"":
			place[station.instrument(i)] = readings[i]

	# Face x is the crew's right; face y is up.
	assert_float(place[&"speed"].get_center().x).is_less(place[&"depth"].get_center().x)
	assert_float(place[&"heading"].get_center().y).is_less(place[&"attitude"].get_center().y)


func test_the_ball_and_its_foot_lie_in_the_attitude_s_box_apart() -> void:
	var box: Rect2 = FlightDisplay.INSTRUMENTS[&"attitude"]
	var centre := FlightDisplay.ball_centre(box)
	var radius := FlightDisplay.ball_radius(box)
	var foot := FlightDisplay.foot(box)
	var round_ball := Rect2(centre - Vector2(radius, radius), Vector2(radius, radius) * 2.0)

	assert_bool(box.encloses(round_ball)).is_true()
	assert_bool(box.encloses(foot)).is_true()
	assert_float(round_ball.end.y).is_less_equal(foot.position.y)


func test_the_deviation_reads_whole_in_the_foot_however_long() -> void:
	# Issue #133: the flat display's foot cut "OFF COURSE 15 deg down, 3..." off.
	var width := FlightDisplay.foot(FlightDisplay.INSTRUMENTS[&"attitude"]).size.x - 24.0
	var font := ThemeDB.fallback_font
	for words: String in [CourseDeviation.text(15.0, 30.0), CourseDeviation.text(-180.0, -180.0),
			CourseDeviation.text(90.0, 135.0)]:
		var size := FlightDisplay.fitting_size(words, width)

		assert_float(font.get_string_size(words, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x).is_less_equal(width)
		assert_int(size).is_greater(FlightDisplay.FONT_LEAST)


func test_a_short_deviation_is_written_at_full_size() -> void:
	var width := FlightDisplay.foot(FlightDisplay.INSTRUMENTS[&"attitude"]).size.x - 24.0

	assert_int(FlightDisplay.fitting_size(CourseDeviation.text(30.0, 0.0), width)).is_equal(FlightDisplay.FONT)


func test_in_a_glide_the_ball_s_corner_says_how_far_off_the_line_in_the_colour_of_its_cost() -> void:
	var slack := 1.0
	var inside := FlightDisplay.glide_line_figure(slack * 0.5, slack, 0.0)
	var touching := FlightDisplay.glide_line_figure(slack * 1.2, slack, 0.1)
	var hard := FlightDisplay.glide_line_figure(slack * 4.0, slack, 1.0)

	assert_str(inside[1]).contains("0.5 m")
	assert_str(hard[1]).contains("4.0 m")
	assert_that(inside[2]).is_equal(StationTheme.ENGAGED_COLOUR)
	assert_that(touching[2]).is_equal(StationTheme.CAUTION_COLOUR)
	assert_that(hard[2]).is_equal(StationTheme.WARNING_COLOUR)
