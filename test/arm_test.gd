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


func test_at_level_from_the_reactor_left_is_drive_and_right_is_the_bore_station() -> void:
	# Seated at the Reactor, at the bottom of the ring, facing the Tail:
	# Drive is round to the left, the Bore Station round to the right past
	# the empty mount.
	var left := _seated_at(0, LEVEL)
	var right := _seated_at(0, LEVEL)

	_shifted(left, -1, LEVEL)
	_shifted(right, 1, LEVEL)

	assert_int(left.station()).is_equal(1)
	assert_int(right.station()).is_equal(4)


func test_diving_from_the_reactor_left_is_drive_and_right_is_the_bore_station() -> void:
	# Standing on the Head cap: the gimbals turn every Station's screen the
	# same way, and the Reactor's neighbours sit to either side of it.
	var left := _seated_at(0, DIVING)
	var right := _seated_at(0, DIVING)

	_shifted(left, -1, DIVING)
	_shifted(right, 1, DIVING)

	assert_int(left.station()).is_equal(1)
	assert_int(right.station()).is_equal(4)


func test_the_same_side_again_and_again_goes_round_every_station_one_at_a_time() -> void:
	var count := IN_USE.size()
	for up in [LEVEL, DIVING, CLIMBING]:
		var poses := _poses(up)
		for side in [-1, 1]:
			var arm := _seated_at(0, up)
			var visited := [0]
			for i in count:
				var before := arm.station()

				var after := _shifted(arm, side, up)

				# A neighbour round the ring, never a jump past one.
				assert_array([(before + 1) % count, (before + count - 1) % count]) \
					.contains([arm.station()])
				_assert_seated_at(after, poses[arm.station()])
				visited.append(arm.station())
			# Round once and back to the start, every Station on the way.
			assert_array(visited.slice(0, count)).contains_exactly_in_any_order(range(count))
			assert_int(visited[count]).is_equal(0)


func test_right_then_left_comes_back_to_the_same_station() -> void:
	for up in [LEVEL, DIVING, CLIMBING]:
		for index in IN_USE.size():
			var arm := _seated_at(index, up)

			_shifted(arm, 1, up)
			_shifted(arm, -1, up)

			assert_int(arm.station()).is_equal(index)
