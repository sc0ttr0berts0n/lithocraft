# Tests at the Arm's seam: press the button, ask for left or right, step it
# with where the crew member's eyes are and where each Station is worked
# from, and read where it holds them. Plain data, no scene: the Stations
# hang where the Habitat's layout puts them (STATIONS, pivot()), turned as
# their gimbals turn them.
extends GdUnitTestSuite

const Habitat := preload("res://view/habitat.gd")
## Standing on the outer wall, this far in from it.
const ON_THE_WALL := Habitat.OUTER_RADIUS - 0.4

const LEVEL := Vector3.UP
const DIVING := Vector3.BACK      # down is toward the Head (-Z)
const CLIMBING := Vector3.FORWARD # down is toward the Tail (+Z)
## Pitched a little off level, where left and right are nearly but not
## quite a tie.
var SHALLOW_DIVE := Vector3(0, cos(deg_to_rad(5.0)), sin(deg_to_rad(5.0)))
var SHALLOW_CLIMB := Vector3(0, cos(deg_to_rad(5.0)), -sin(deg_to_rad(5.0)))

## Long enough for any reach or carry to finish, however it is tuned.
const PLENTY := 30.0
## How far the ring of Stations has slid from the Head end to the Tail end
## (Habitat.ring_z()): at either end, and part of the way.
const BY_THE_HEAD := 0.0
const BY_THE_TAIL := 1.0
const MID_SLIDE := 0.4


## The Habitat's places with a Station on them, in order round the ring:
## the Arm's Stations, with the empty mount left out, as the Habitat does.
var in_use := DiveTestKit.station_places()


func _pivot(place: int, slid := BY_THE_HEAD) -> Vector3:
	return Habitat.pivot(place, slid)


## The in-use Station of that name, as an index into in_use.
func _index_of(station_name: String) -> int:
	return in_use.find(DiveTestKit.station_place(station_name))


## A new Arm on the Habitat's rail, the ring of Stations slid this far.
func _new_arm(slid := BY_THE_HEAD) -> Arm:
	return Habitat.new_arm(slid)


## A Station's cradle with its gimbal settled to up.
func _cradle(index: int, up: Vector3) -> Basis:
	return GimballedStation.settled_cradle(_pivot(in_use[index]), up, Basis())


## Where each in-use Station is worked from, with the gimbals settled to up
## and the ring slid this far.
func _poses(up: Vector3, slid := BY_THE_HEAD) -> Array[Transform3D]:
	var poses: Array[Transform3D] = []
	for index in in_use.size():
		poses.append(GimballedStation.pose_for(_pivot(in_use[index], slid), _cradle(index, up)))
	return poses


func _screen(index: int, up: Vector3) -> Vector3:
	return GimballedStation.screen_centre_for(_pivot(in_use[index]), _cradle(index, up))


## A crew member standing upright for this "up", eyes at the given point.
func _eye_at(point: Vector3, up: Vector3) -> Transform3D:
	return Transform3D(Gimbal.toward_up(Basis(), up, 1.0), point)


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
		points.append(radial * ON_THE_WALL)
		points.append(radial * 1.2 + Vector3(0, 0, -Habitat.LENGTH / 2.0 + 0.3))
		points.append(radial * 2.0 + Vector3(0, 0, Habitat.LENGTH / 2.0 - 0.3))
	return points


func _assert_caught_from_anywhere(up: Vector3, slid := BY_THE_HEAD) -> void:
	var poses := _poses(up, slid)
	for point in _anywhere():
		var arm := _new_arm(slid)
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


func test_from_anywhere_the_arm_seats_the_player_with_the_ring_by_the_tail() -> void:
	_assert_caught_from_anywhere(CLIMBING, BY_THE_TAIL)
	_assert_caught_from_anywhere(LEVEL, BY_THE_TAIL)


func test_from_anywhere_the_arm_seats_the_player_with_the_ring_part_way_along() -> void:
	_assert_caught_from_anywhere(CLIMBING, MID_SLIDE)


## Places along the Bore's length: on each end cap and on the curved outer
## wall part of the way along.
func _along_the_bore() -> Array[Vector3]:
	var beside := Vector3(cos(0.4), sin(0.4), 0)
	return [
		beside * 2.0 + Vector3(0, 0, -Habitat.LENGTH / 2.0 + 0.3),
		beside * ON_THE_WALL + Vector3(0, 0, 0.9),
		beside * 2.0 + Vector3(0, 0, Habitat.LENGTH / 2.0 - 0.3),
	]


## Steps a called Arm until it catches; returns where its carriage was along
## the Bore as it caught, and after how many seconds (PLENTY if it never did).
func _catch(arm: Arm, eye: Transform3D, poses: Array[Transform3D]) -> Dictionary:
	var seconds := 0.0
	while not arm.is_holding() and seconds < PLENTY:
		arm.step(1.0 / 60.0, eye, poses)
		seconds += 1.0 / 60.0
	return {carriage_z = arm.carriage().z, seconds = seconds}


func test_called_from_anywhere_along_the_bore_the_carriage_runs_to_the_player_to_catch_them() -> void:
	for slid in [BY_THE_HEAD, BY_THE_TAIL]:
		var poses := _poses(CLIMBING, slid)
		for point in _along_the_bore():
			var arm := _new_arm(slid)
			arm.press()

			var caught := _catch(arm, _eye_at(point, CLIMBING), poses)

			# It catches them from level with them along the Bore...
			assert_bool(arm.is_holding()).is_true()
			assert_float(caught.carriage_z) \
				.override_failure_message("caught at %s from %.2f along the Bore" % [point, caught.carriage_z]) \
				.is_equal_approx(point.z, 0.25)
			# ...then carries them to a Station, the carriage back at the ring.
			var eye := _run(arm, arm.held_eye(), poses)
			_assert_seated_at(eye, poses[arm.station()])
			assert_float(arm.carriage().z).is_equal_approx(Habitat.ring_z(slid), 0.001)


func test_the_further_along_the_bore_the_player_is_the_longer_the_arm_takes_to_catch_them() -> void:
	var poses := _poses(DIVING)
	var radial := Vector3(cos(0.4), sin(0.4), 0) * 2.0
	var by_the_ring := _eye_at(radial + Vector3(0, 0, Habitat.ring_z()), DIVING)
	var half_way := _eye_at(radial, DIVING)
	var far_end := _eye_at(radial + Vector3(0, 0, Habitat.LENGTH / 2.0 - 0.3), DIVING)
	var took := []

	for eye: Transform3D in [by_the_ring, half_way, far_end]:
		var arm := _new_arm()
		arm.press()
		took.append(_catch(arm, eye, poses).seconds)

	assert_float(took[1]).is_greater(took[0])
	assert_float(took[2]).is_greater(took[1])
	assert_float(took[2]).is_less(PLENTY)


func test_parked_the_rail_slides_with_the_ring_of_stations() -> void:
	var arm := _new_arm()
	var poses := _poses(CLIMBING)
	var eye := _eye_at(_beside(0, CLIMBING), CLIMBING)

	# The ring slides the Habitat's length over some seconds; the Arm is told
	# each step where it is.
	for i in 361:
		arm.slide_to(Habitat.ring_z(i / 360.0))
		arm.step(1.0 / 60.0, eye, poses)

		assert_float(arm.carriage().z).is_equal_approx(Habitat.ring_z(i / 360.0), 0.001)
	assert_int(arm.state()).is_equal(Arm.State.PARKED)


func test_held_at_a_station_the_player_rides_the_slide_seated_there() -> void:
	for index in in_use.size():
		var arm := _seated_at(index, DIVING)
		var eye := arm.held_eye()

		for i in 361:
			var slid := i / 360.0
			var poses := _poses(CLIMBING if i > 0 else DIVING, slid)
			arm.slide_to(Habitat.ring_z(slid))
			arm.step(1.0 / 60.0, eye, poses)
			eye = arm.held_eye()

			# Seated the whole way: never left behind, never let go.
			assert_bool(arm.arrived()).is_true()
			assert_int(arm.station()).is_equal(index)
			assert_float(eye.origin.distance_to(poses[index].origin)).is_less(0.01)
			assert_float(arm.carriage().z).is_equal_approx(Habitat.ring_z(slid), 0.001)


func test_called_as_the_ring_slides_the_arm_still_brings_the_player_to_a_station() -> void:
	var arm := _new_arm()
	var eye := _eye_at(_along_the_bore()[0], CLIMBING)
	arm.press()

	# The ring sets off for the Tail end as the Arm is called.
	for i in int(PLENTY * 60.0):
		var slid := minf(1.0, i / 360.0)
		arm.slide_to(Habitat.ring_z(slid))
		arm.step(1.0 / 60.0, eye, _poses(CLIMBING, slid))
		if arm.is_holding():
			eye = arm.held_eye()

	assert_bool(arm.arrived()).is_true()
	_assert_seated_at(eye, _poses(CLIMBING, BY_THE_TAIL)[arm.station()])
	assert_float(arm.carriage().z).is_equal_approx(Habitat.ring_z(BY_THE_TAIL), 0.001)


## Standing on whatever is the floor at that pitch, at a Station's place
## round the ring: on the outer wall when level or nearly, on an end cap
## otherwise.
func _beside(index: int, up: Vector3) -> Vector3:
	var pivot := _pivot(in_use[index])
	if up.dot(LEVEL) > 0.9:
		return Vector3(pivot.x, pivot.y, 0).normalized() * ON_THE_WALL + Vector3(0, 0, pivot.z)
	return pivot - up * 0.9


func test_at_every_pitch_the_arm_takes_the_player_to_the_station_they_are_standing_by() -> void:
	for up in [LEVEL, DIVING, CLIMBING]:
		var poses := _poses(up)
		for index in in_use.size():
			var arm := _new_arm()
			arm.press()

			var eye := _run(arm, _eye_at(_beside(index, up), up), poses)

			assert_int(arm.station()).is_equal(index)
			_assert_seated_at(eye, poses[index])


## Seated at a Station, once the carry there has finished.
func _seated_at(index: int, up: Vector3) -> Arm:
	var arm := _new_arm()
	arm.press()
	_run(arm, _eye_at(_beside(index, up), up), _poses(up))
	return arm


func _shifted(arm: Arm, side: int, up: Vector3) -> Transform3D:
	arm.shift(side)
	return _run(arm, arm.held_eye(), _poses(up))


## Where one left or right from a Station takes the crew member, each way.
func _one_step_from(index: int, up: Vector3) -> Array:
	var reached := []
	for side in [-1, 1]:
		var arm := _seated_at(index, up)
		_shifted(arm, side, up)
		reached.append(arm.station())
	return reached


func test_the_drive_and_navigation_are_one_left_or_right_apart_at_every_pitch() -> void:
	var drive := _index_of("Drive")
	var navigation := _index_of("Navigation")
	for up in [LEVEL, DIVING, CLIMBING, SHALLOW_DIVE, SHALLOW_CLIMB]:
		assert_array(_one_step_from(drive, up)) \
			.override_failure_message("Navigation is not one step from the Drive, up %s" % up) \
			.contains([navigation])
		assert_array(_one_step_from(navigation, up)) \
			.override_failure_message("the Drive is not one step from Navigation, up %s" % up) \
			.contains([drive])


func test_left_or_right_moves_one_station_at_a_time_toward_that_side() -> void:
	var count := in_use.size()
	for up in [LEVEL, DIVING, CLIMBING, SHALLOW_DIVE, SHALLOW_CLIMB]:
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
	var count := in_use.size()
	for up in [LEVEL, DIVING, CLIMBING, SHALLOW_DIVE, SHALLOW_CLIMB]:
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
		var eye := arm.held_eye()

		arm.press()
		var released := arm.is_holding()
		_run(arm, eye, _poses(up))

		assert_bool(released).is_false()
		assert_int(arm.station()).is_equal(-1)
		assert_int(arm.state()).is_equal(Arm.State.PARKED)


func test_pressing_while_it_reaches_calls_it_off() -> void:
	var arm := _new_arm()
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
		for index in in_use.size():
			var arm := _seated_at(index, up)
			var eye := arm.held_eye().origin
			var screen := _screen(index, up)

			for p in arm.chain():
				assert_bool(_in_the_way(p, eye, screen, _cradle(index, up))) \
					.override_failure_message("chain at %s blocks Station %d, up %s" % [p, index, up]) \
					.is_false()


func test_left_or_right_before_being_caught_is_not_saved_up_for_later() -> void:
	var arm := _new_arm()
	arm.shift(1)
	arm.press()

	_run(arm, _eye_at(_beside(2, LEVEL), LEVEL), _poses(LEVEL))

	assert_int(arm.station()).is_equal(2)


func test_one_way_then_the_other_comes_back_to_the_same_station() -> void:
	for up in [LEVEL, DIVING, CLIMBING, SHALLOW_DIVE, SHALLOW_CLIMB]:
		for index in in_use.size():
			for side in [-1, 1]:
				var arm := _seated_at(index, up)

				_shifted(arm, side, up)
				_shifted(arm, -side, up)

				assert_int(arm.station()).is_equal(index)


func test_seated_at_once_the_arm_holds_the_player_at_that_station() -> void:
	var poses := _poses(DIVING)
	for index in in_use.size():
		var arm := _new_arm()

		arm.seat(index, poses[index])

		assert_bool(arm.arrived()).is_true()
		assert_int(arm.station()).is_equal(index)
		_assert_seated_at(arm.held_eye(), poses[index])


func test_seated_at_once_the_arm_follows_the_station_as_down_turns() -> void:
	var arm := _new_arm()
	arm.seat(0, _poses(DIVING)[0])

	var eye := _run(arm, arm.held_eye(), _poses(LEVEL), 1.0)

	assert_bool(arm.arrived()).is_true()
	_assert_seated_at(eye, _poses(LEVEL)[0])


func test_the_rail_runs_round_the_bore_where_the_ring_of_stations_hangs() -> void:
	var arm := _new_arm()
	var parked := [arm.carriage(), arm.hand()]
	arm.press()
	_run(arm, _eye_at(_beside(_index_of("Thermal"), DIVING), DIVING), _poses(DIVING))

	# Parked or holding at a Station across the ring, the carriage is level
	# with every Station's pivot along the Bore, just outside the glass.
	for point: Vector3 in parked + [arm.carriage()]:
		for index in in_use.size():
			assert_float(point.z).is_equal_approx(_pivot(in_use[index]).z, 0.001)
	assert_float(Vector2(arm.carriage().x, arm.carriage().y).length()).is_between(
			Habitat.BORE_RADIUS, Habitat.BORE_RADIUS + 2.0 * Habitat.RAIL_GAP)
