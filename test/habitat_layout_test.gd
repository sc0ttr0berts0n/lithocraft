# Tests of the Habitat's layout: where each Station hangs round the ring
# (the Habitat's STATIONS and pivot()) and which way its gimbal turns it
# (GimballedStation.follow_up()). Plain data and lone gimbals, no scene.
extends GdUnitTestSuite

const Habitat := preload("res://view/habitat.gd")


## Every "down" the vessel feels: the felt acceleration has no sideways
## part, so "up" is pitched somewhere from climbing (up toward the Head) to
## diving (up toward the Tail), here every 5 degrees.
func _ups() -> Array[Vector3]:
	var ups: Array[Vector3] = []
	for pitch_deg in range(-90, 91, 5):
		var pitch := deg_to_rad(pitch_deg)
		ups.append(Vector3(0, cos(pitch), sin(pitch)))
	return ups


## A lone gimbal at a place, built level, then swung onto up for long
## enough to settle there.
func _settled(place: int, up: Vector3) -> GimballedStation:
	var station: GimballedStation = auto_free(GimballedStation.new())
	station.position = Habitat.pivot(place)
	add_child(station)
	station.follow_up(Vector3.UP, 0.0)
	station.follow_up(up, 60.0)
	return station


func test_every_station_faces_the_bore_with_the_column_behind_its_screen_in_every_down() -> void:
	for up in _ups():
		for place in DiveTestKit.station_places():
			var station := _settled(place, up)
			var pose := station.pose()
			var eye := pose.origin
			var view := -pose.basis.z
			var screen := station.screen_centre()
			var station_name := DiveTestKit.station_name(place)

			# Looking at the screen is looking toward the Bore axis, as
			# squarely as standing upright allows.
			var toward_axis := Vector3(-screen.x, -screen.y, 0)
			var upright_toward := (toward_axis - up * toward_axis.dot(up)).normalized()
			assert_float(view.dot(upright_toward)) \
				.override_failure_message("%s faces away from the Bore, up %s" % [station_name, up]) \
				.is_greater(0.999)
			# The line of sight passes the screen before it comes nearest
			# the axis: the Column is behind the screen.
			var to_screen := (screen - eye).dot(view)
			var view_across := Vector2(view.x, view.y)
			var nearest_axis := -Vector2(eye.x, eye.y).dot(view_across) / view_across.length_squared()
			assert_float(nearest_axis) \
				.override_failure_message("%s has the Column in front of its screen, up %s" % [station_name, up]) \
				.is_greater(to_screen)


func test_the_drive_and_navigation_are_neighbours_on_the_ring() -> void:
	var count: int = Habitat.STATIONS.size()
	var drive := DiveTestKit.station_place("Drive")
	var navigation := DiveTestKit.station_place("Navigation")

	assert_int(drive).is_not_equal(-1)
	assert_int(navigation).is_not_equal(-1)
	assert_array([(drive + 1) % count, (drive + count - 1) % count]).contains([navigation])


func test_a_station_with_nothing_felt_holds_where_it_was() -> void:
	var station := _settled(DiveTestKit.station_place("Drive"), Vector3.BACK)
	var before := station.pose()

	station.follow_up(Vector3.ZERO, 1.0)

	assert_bool(station.pose().is_equal_approx(before)).is_true()
