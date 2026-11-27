# The Drive's primary flight display: its tapes keep the
# reading at the middle and slide the scale past it, with the Course's bug at
# the Course's own value.
extends GdUnitTestSuite


func _heading_tape() -> FlightTape:
	return FlightTape.new(60.0, 300.0, 360.0)


func test_the_reading_sits_at_the_tapes_middle() -> void:
	var tape := FlightTape.new(2.0, 200.0)

	assert_float(tape.place(0.7, 0.7)).is_equal_approx(0.0, 0.0001)


func test_a_larger_value_lies_further_along_the_tape() -> void:
	var tape := FlightTape.new(2.0, 200.0)

	assert_float(tape.place(1.0, 0.5)).is_greater(tape.place(0.8, 0.5))
	assert_float(tape.place(0.8, 0.5)).is_greater(0.0)
	assert_float(tape.place(0.2, 0.5)).is_less(0.0)


func test_the_course_bug_sits_at_the_course_s_heading_the_short_way_round() -> void:
	var tape := _heading_tape()

	# A Course of 350 is 20 degrees left of a heading of 10, not 340 right.
	assert_float(tape.place(350.0, 10.0)).is_equal_approx(tape.place(-20.0, 0.0), 0.0001)
	assert_float(tape.place(350.0, 10.0)).is_less(0.0)
	assert_float(tape.place(10.0, 350.0)).is_greater(0.0)
	assert_float(tape.place(10.0, 350.0)).is_equal_approx(-tape.place(350.0, 10.0), 0.0001)


func test_a_bug_off_the_tape_is_pinned_to_its_nearer_end() -> void:
	var tape := _heading_tape()

	assert_bool(tape.on_scale(180.0, 0.0)).is_false()
	assert_float(absf(tape.pinned(90.0, 0.0))).is_equal_approx(tape.length / 2.0, 0.0001)
	assert_float(tape.pinned(90.0, 0.0)).is_greater(0.0)
	assert_float(tape.pinned(270.0, 0.0)).is_less(0.0)
	# On the tape, the bug sits at its place.
	assert_bool(tape.on_scale(10.0, 0.0)).is_true()
	assert_float(tape.pinned(10.0, 0.0)).is_equal_approx(tape.place(10.0, 0.0), 0.0001)


func test_heading_ticks_wrap_through_north() -> void:
	var tape := _heading_tape()

	var ticks := tape.ticks(5.0, 10.0)

	assert_array(ticks).contains([350.0, 0.0, 10.0])
	for value in ticks:
		assert_float(value).is_greater_equal(0.0)
		assert_float(value).is_less(360.0)
		assert_bool(tape.on_scale(value, 5.0)).is_true()


func test_ticks_outside_the_scale_s_range_are_left_off() -> void:
	var tape := FlightTape.new(2.0, 200.0)

	var ticks := tape.ticks(0.2, 0.5, 0.0)

	assert_array(ticks).is_equal([0.0, 0.5, 1.0])

