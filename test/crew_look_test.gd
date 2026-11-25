# Mouse look while the Arm holds the crew member: the look is told how far
# the mouse moved, the Arm keeps putting the eyes at the Station's pose, and
# the view still turns. A CrewMember outside the scene tree: hold() and
# look() touch no Input and no physics.
extends GdUnitTestSuite

const LEVEL := Vector3.UP
const DIVING := Vector3.BACK
const CLIMBING := Vector3.FORWARD

const PIVOT := Vector3(0, -2.2, 0)
## Mouse travel, in pixels, enough to turn the view clearly.
const ACROSS := Vector2(200, 0)
const DOWN := Vector2(0, 200)


func _pose(up: Vector3) -> Transform3D:
	return GimballedStation.pose_for(PIVOT, Gimbal.toward_up(Basis(), up, 1.0))


func _crew() -> CrewMember:
	return auto_free(CrewMember.new())


## Seated: held at the pose with the look settled (weight 0, as once arrived).
func _seat(crew: CrewMember, pose: Transform3D) -> void:
	crew.hold(pose, GimballedStation.pose_look(), 0.0)


func test_held_at_a_station_in_every_down_moving_the_mouse_across_turns_the_view() -> void:
	for up in [LEVEL, DIVING, CLIMBING]:
		var crew := _crew()
		var pose := _pose(up)
		_seat(crew, pose)
		var before := crew.view()

		crew.look(ACROSS)
		_seat(crew, pose)

		assert_float(crew.view().basis.z.dot(before.basis.z)).is_less(0.99)
		# Turned about the crew member's own up, which the Arm holds upright.
		assert_float(crew.view().basis.x.dot(pose.basis.y)).is_equal_approx(0.0, 0.001)


func test_held_at_a_station_in_every_down_moving_the_mouse_down_lowers_the_view() -> void:
	for up in [LEVEL, DIVING, CLIMBING]:
		var crew := _crew()
		var pose := _pose(up)
		_seat(crew, pose)
		var before := -crew.view().basis.z

		crew.look(DOWN)
		_seat(crew, pose)

		var after := -crew.view().basis.z
		assert_float(after.dot(pose.basis.y)).is_less(before.dot(pose.basis.y))


func test_the_eyes_stay_where_the_arm_holds_them_while_looking() -> void:
	var crew := _crew()
	var pose := _pose(DIVING)

	crew.look(ACROSS + DOWN)
	_seat(crew, pose)

	assert_float(crew.view().origin.distance_to(pose.origin)).is_less(0.001)


func test_a_look_away_during_a_carry_is_kept_not_pulled_back_to_the_screen() -> void:
	var crew := _crew()
	var pose := _pose(LEVEL)
	_seat(crew, pose)
	crew.look(ACROSS)
	var looked := crew.view()

	# Still being carried: the Habitat eases the look toward the screen.
	for i in 60:
		crew.hold(pose, GimballedStation.pose_look(), 0.1)

	assert_float(crew.view().basis.z.dot(looked.basis.z)).is_greater(0.999)


func test_a_new_carry_begins_by_easing_the_look_to_the_screen() -> void:
	var crew := _crew()
	var pose := _pose(LEVEL)
	crew.look(ACROSS + DOWN)
	_seat(crew, pose)
	crew.step(-LEVEL * 9.8, 0.0)  # let go

	for i in 120:
		crew.hold(pose, GimballedStation.pose_look(), 0.1)

	var screen := Basis(Vector3.RIGHT, GimballedStation.pose_look())
	assert_float(crew.view().basis.z.dot((pose.basis * screen).z)).is_greater(0.999)
