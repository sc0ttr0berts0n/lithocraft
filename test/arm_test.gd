# Tests at the Arm's seam: press the button, ask for left or right, step it
# with where the crew member's eyes are and where each Station is worked
# from, and read where it holds them. Plain data, no scene: the Habitat's
# geometry is rebuilt here from its documented dimensions.
extends GdUnitTestSuite

const BORE_RADIUS := 0.8
const OUTER_RADIUS := 3.3
const PIVOT_RADIUS := 2.2
## Five Stations in use round the ring, with the empty mount (the sixth
## place, at 210 degrees) left out, as the Habitat does.
const STATION_COUNT := 6
const IN_USE := [0, 1, 2, 3, 4]

const LEVEL := Vector3.UP
const DIVING := Vector3.BACK      # down is toward the Head (-Z)
const CLIMBING := Vector3.FORWARD # down is toward the Tail (+Z)

## Long enough for any reach or carry to finish, however it is tuned.
const PLENTY := 30.0


func _pivot(place: int) -> Vector3:
	var a := TAU * place / STATION_COUNT - PI / 2.0
	return Vector3(cos(a), sin(a), 0) * PIVOT_RADIUS


func _cradle(up: Vector3) -> Basis:
	return Gimbal.toward_up(Basis(), up, 1.0)


## Where each in-use Station is worked from, with the gimbals settled to up.
func _poses(up: Vector3) -> Array[Transform3D]:
	var poses: Array[Transform3D] = []
	for place in IN_USE:
		poses.append(GimballedStation.pose_for(_pivot(place), _cradle(up)))
	return poses


func _screen(index: int, up: Vector3) -> Vector3:
	return GimballedStation.screen_centre_for(_pivot(IN_USE[index]), _cradle(up))


## A crew member standing upright for this "up", eyes at the given point.
func _eye_at(point: Vector3, up: Vector3) -> Transform3D:
	return Transform3D(_cradle(up), point)


func _run(arm: Arm, eye: Transform3D, poses: Array[Transform3D], seconds := PLENTY) -> Transform3D:
	for i in int(seconds * 60.0):
		arm.step(1.0 / 60.0, eye, poses)
		if arm.is_holding():
			eye = arm.held_eye()
	return eye


func _assert_seated_at(eye: Transform3D, pose: Transform3D) -> void:
	assert_float(eye.origin.distance_to(pose.origin)).is_less(0.01)
	assert_float(eye.basis.y.dot(pose.basis.y)).is_greater(0.999)
	assert_float(eye.basis.z.dot(pose.basis.z)).is_greater(0.999)


## Places all round the Habitat: on the outer wall, by the Bore, on both
## end caps, between Stations.
func _anywhere() -> Array[Vector3]:
	var points: Array[Vector3] = []
	for i in 12:
		var a := TAU * (i + 0.5) / 12.0
		var radial := Vector3(cos(a), sin(a), 0)
		points.append(radial * 2.9)
		points.append(radial * 1.2 + Vector3(0, 0, -0.9))
		points.append(radial * 2.0 + Vector3(0, 0, 0.9))
	return points


func _assert_caught_from_anywhere(up: Vector3) -> void:
	var poses := _poses(up)
	for point in _anywhere():
		var arm := Arm.new(BORE_RADIUS + 0.15)
		arm.press()

		var eye := _run(arm, _eye_at(point, up), poses)

		assert_bool(arm.is_holding()).is_true()
		_assert_seated_at(eye, poses[arm.station()])


func test_from_anywhere_at_level_the_arm_seats_the_player_at_a_station() -> void:
	_assert_caught_from_anywhere(LEVEL)


func test_from_anywhere_diving_the_arm_seats_the_player_at_a_station() -> void:
	_assert_caught_from_anywhere(DIVING)


func test_from_anywhere_climbing_the_arm_seats_the_player_at_a_station() -> void:
	_assert_caught_from_anywhere(CLIMBING)


## Standing on whatever is the floor at that pitch, at a Station's place
## round the ring: on the outer wall when level, on an end cap otherwise.
func _beside(index: int, up: Vector3) -> Vector3:
	var round_ring := _pivot(IN_USE[index]).normalized()
	if up == LEVEL:
		return round_ring * 2.9
	return round_ring * PIVOT_RADIUS - up * 0.9


func test_at_every_pitch_the_arm_takes_the_player_to_the_station_they_are_standing_by() -> void:
	for up in [LEVEL, DIVING, CLIMBING]:
		var poses := _poses(up)
		for index in IN_USE.size():
			var arm := Arm.new(BORE_RADIUS + 0.15)
			arm.press()

			var eye := _run(arm, _eye_at(_beside(index, up), up), poses)

			assert_int(arm.station()).is_equal(index)
			_assert_seated_at(eye, poses[index])


## Seated at a Station, once the carry there has finished.
func _seated_at(index: int, up: Vector3) -> Arm:
	var arm := Arm.new(BORE_RADIUS + 0.15)
	arm.press()
	_run(arm, _eye_at(_beside(index, up), up), _poses(up))
	return arm


func _shifted(arm: Arm, side: int, up: Vector3) -> Transform3D:
	arm.shift(side)
	return _run(arm, arm.held_eye(), _poses(up))


func test_from_the_reactor_left_is_drive_and_right_is_the_bore_station_at_every_pitch() -> void:
	# The Reactor is at the bottom of the ring. Level, the crew member faces
	# the Tail; diving or climbing, the gimbals turn every screen the same
	# way across the ring. Either way Drive sits to their left and the Bore
	# Station (past the empty mount) to their right.
	for up in [LEVEL, DIVING, CLIMBING]:
		var left := _seated_at(0, up)
		var right := _seated_at(0, up)

		_shifted(left, -1, up)
		_shifted(right, 1, up)

		assert_int(left.station()).is_equal(1)
		assert_int(right.station()).is_equal(4)


func test_left_or_right_moves_one_station_at_a_time_toward_that_side() -> void:
	var count := IN_USE.size()
	for up in [LEVEL, DIVING, CLIMBING]:
		var poses := _poses(up)
		for index in count:
			for side in [-1, 1]:
				var arm := _seated_at(index, up)
				var before := arm.held_eye()

				var after := _shifted(arm, side, up)

				# A neighbour round the ring, never a jump past one...
				var neighbours := [(index + 1) % count, (index + count - 1) % count]
				assert_array(neighbours).contains([arm.station()])
				# ...and not the one that is further the other way.
				var other: int = neighbours[0] if arm.station() == neighbours[1] else neighbours[1]
				var toward := func(i: int) -> float:
					return (poses[i].origin - before.origin).dot(before.basis.x) * side
				assert_float(toward.call(arm.station())).is_greater_equal(toward.call(other) - 0.01)
				_assert_seated_at(after, poses[arm.station()])


func test_every_station_in_use_can_be_reached_with_left_and_right_at_every_pitch() -> void:
	var count := IN_USE.size()
	for up in [LEVEL, DIVING, CLIMBING]:
		# Where left and right lead from each Station, then follow them.
		var leads := []
		for index in count:
			var next := []
			for side in [-1, 1]:
				var arm := _seated_at(index, up)
				_shifted(arm, side, up)
				next.append(arm.station())
			leads.append(next)
		var reached := [0]
		var frontier := [0]
		while not frontier.is_empty():
			for n in leads[frontier.pop_back()]:
				if n not in reached:
					reached.append(n)
					frontier.append(n)

		assert_array(reached).contains_exactly_in_any_order(range(count))


func test_pressing_again_lets_go_and_the_arm_goes_back_to_its_rail() -> void:
	for up in [LEVEL, DIVING, CLIMBING]:
		var arm := _seated_at(2, up)
		var seat := arm.held_eye()

		arm.press()
		var released := arm.is_holding()
		_run(arm, seat, _poses(up))

		assert_bool(released).is_false()
		assert_int(arm.station()).is_equal(-1)
		assert_int(arm.state()).is_equal(Arm.State.PARKED)


func test_pressing_while_it_reaches_calls_it_off() -> void:
	var arm := Arm.new(BORE_RADIUS + 0.15)
	arm.press()
	arm.step(0.1, _eye_at(_beside(0, LEVEL), LEVEL), _poses(LEVEL))

	arm.press()
	_run(arm, _eye_at(_beside(0, LEVEL), LEVEL), _poses(LEVEL))

	assert_bool(arm.is_holding()).is_false()
	assert_int(arm.state()).is_equal(Arm.State.PARKED)


## True if p, seen from eye, is in the way of any part of the screen (with
## a margin round it for the desk and the chain's thickness).
func _in_the_way(p: Vector3, eye: Vector3, screen: Vector3, cradle: Basis) -> bool:
	var facing := -cradle.z  # the screen's face points this way, at the eye
	var to_screen := (screen - eye).dot(-facing)
	var to_p := (p - eye).dot(-facing)
	if to_p <= 0.0 or to_p >= to_screen:
		return false  # behind the eye or beyond the screen
	var on_plane := eye + (p - eye) * (to_screen / to_p) - screen
	var margin := 0.15
	return absf(on_plane.dot(cradle.x)) < 0.4 + margin \
		and absf(on_plane.dot(cradle.y)) < 0.2 + margin


func test_seated_the_chain_and_claw_never_block_the_view_of_the_station() -> void:
	for up in [LEVEL, DIVING, CLIMBING]:
		for index in IN_USE.size():
			var arm := _seated_at(index, up)
			var eye := arm.held_eye().origin
			var screen := _screen(index, up)

			for p in arm.chain():
				assert_bool(_in_the_way(p, eye, screen, _cradle(up))) \
					.override_failure_message("chain at %s blocks Station %d, up %s" % [p, index, up]) \
					.is_false()


func test_left_or_right_before_being_caught_is_not_saved_up_for_later() -> void:
	var arm := Arm.new(BORE_RADIUS + 0.15)
	arm.shift(1)
	arm.press()

	_run(arm, _eye_at(_beside(2, LEVEL), LEVEL), _poses(LEVEL))

	assert_int(arm.station()).is_equal(2)


func test_one_way_then_the_other_comes_back_to_the_same_station() -> void:
	for up in [LEVEL, DIVING, CLIMBING]:
		for index in IN_USE.size():
			for side in [-1, 1]:
				var arm := _seated_at(index, up)

				_shifted(arm, side, up)
				_shifted(arm, -side, up)

				assert_int(arm.station()).is_equal(index)
