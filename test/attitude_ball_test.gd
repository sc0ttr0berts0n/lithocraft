# The Drive's attitude ball: the Head's direction is the ball's middle, every
# other direction lies on the ball the way it lies from the Head, and that
# holds at every pitch, straight up and down included.
extends GdUnitTestSuite

const NEAR := 0.0001


func test_where_the_head_points_is_the_ball_s_middle_at_any_pitch() -> void:
	for pitch: float in [-90.0, -60.0, 0.0, 45.0, 89.0, 90.0]:
		var ball := AttitudeBall.new(pitch, 30.0)

		assert_vector(ball.place(30.0, pitch)).is_equal_approx(Vector2.ZERO, Vector2(NEAR, NEAR))


func test_a_steeper_direction_lies_below_the_middle_and_a_shallower_above() -> void:
	var ball := AttitudeBall.new(40.0, 90.0)

	assert_float(ball.place(90.0, 60.0).y).is_greater(0.0)
	assert_float(ball.place(90.0, 20.0).y).is_less(0.0)
	assert_float(absf(ball.place(90.0, 60.0).x)).is_less(NEAR)


func test_a_heading_to_the_right_lies_right_of_the_middle() -> void:
	var ball := AttitudeBall.new(0.0, 350.0)

	assert_float(ball.place(10.0, 0.0).x).is_greater(0.0)
	assert_float(ball.place(330.0, 0.0).x).is_less(0.0)


func test_the_horizon_lies_above_the_middle_in_a_dive_and_below_it_in_a_climb() -> void:
	assert_float(AttitudeBall.new(30.0, 0.0).place(0.0, 0.0).y).is_less(0.0)
	assert_float(AttitudeBall.new(-30.0, 0.0).place(0.0, 0.0).y).is_greater(0.0)


func test_straight_down_a_tilt_toward_a_heading_lies_that_way_from_the_middle() -> void:
	# The Head's heading points up from the pole; a direction tilted toward a
	# heading 90 degrees right of it lies to the right, one behind it below.
	var ball := AttitudeBall.new(90.0, 0.0)
	var right := ball.place(90.0, 80.0)
	var behind := ball.place(180.0, 80.0)
	var ahead := ball.place(0.0, 80.0)

	assert_float(right.x).is_greater(0.0)
	assert_float(absf(right.y)).is_less(NEAR)
	assert_float(behind.y).is_greater(0.0)
	assert_float(ahead.y).is_less(0.0)


func test_the_ball_turns_smoothly_through_vertical() -> void:
	# No dead spot: a direction's place moves little as the Head tilts the
	# last degree onto vertical, whichever way the direction lies.
	for at_heading: float in [0.0, 90.0, 200.0]:
		var near_vertical := AttitudeBall.new(89.5, 0.0).place(at_heading, 70.0)
		var vertical := AttitudeBall.new(90.0, 0.0).place(at_heading, 70.0)

		assert_float(near_vertical.distance_to(vertical)).is_less(0.02)


func test_a_direction_behind_the_ball_is_pinned_to_the_rim_on_its_side() -> void:
	var ball := AttitudeBall.new(0.0, 0.0)

	assert_bool(ball.on_face(150.0, 0.0)).is_false()
	var pinned := ball.place(150.0, 0.0)
	assert_float(pinned.length()).is_equal_approx(1.0, NEAR)
	assert_float(pinned.x).is_greater(0.0)
	assert_float(ball.place(180.0, 0.0).length()).is_equal_approx(1.0, NEAR)


func test_every_place_is_on_the_disc() -> void:
	for pitch: float in [-90.0, -30.0, 0.0, 60.0, 90.0]:
		var ball := AttitudeBall.new(pitch, 120.0)
		for at_heading: float in [0.0, 120.0, 300.0]:
			for at_pitch: float in [-90.0, -10.0, 45.0, 90.0]:
				assert_float(ball.place(at_heading, at_pitch).length()).is_less_equal(1.0 + NEAR)


func test_the_surfaceward_part_grows_as_the_head_climbs() -> void:
	var dive := _area(AttitudeBall.new(45.0, 0.0).surfaceward())
	var level := _area(AttitudeBall.new(0.0, 0.0).surfaceward())
	var climb := _area(AttitudeBall.new(-45.0, 0.0).surfaceward())

	assert_float(dive).is_less(level)
	assert_float(level).is_less(climb)
	assert_float(level).is_equal_approx(PI / 2.0, 0.01)
	assert_float(_area(AttitudeBall.new(90.0, 0.0).surfaceward())).is_equal(0.0)
	assert_float(_area(AttitudeBall.new(-90.0, 0.0).surfaceward())).is_equal_approx(PI, 0.01)


func test_only_the_face_s_half_of_a_circle_is_drawn() -> void:
	var ball := AttitudeBall.new(0.0, 0.0)
	var runs := ball.meridian(180.0)

	# The meridian behind the Head shows only near the poles, at the rim.
	for run in runs:
		for point in run:
			assert_float(point.length()).is_less_equal(1.0 + NEAR)
	var horizon := ball.parallel(0.0)
	assert_int(horizon.size()).is_greater(0)
	for run in horizon:
		for point in run:
			assert_float(absf(point.y)).is_less(NEAR)


func _area(outline: PackedVector2Array) -> float:
	var twice := 0.0
	for i in outline.size():
		var a := outline[i]
		var b := outline[(i + 1) % outline.size()]
		twice += a.x * b.y - b.x * a.y
	return absf(twice) / 2.0
