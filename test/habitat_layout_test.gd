# Tests of the Habitat's layout: where each Station hangs round the ring
# (the Habitat's STATIONS and pivot()) and which way its gimbal turns it
# (GimballedStation.follow_up()). Plain data and lone gimbals, no scene.
extends GdUnitTestSuite

const Habitat := preload("res://view/habitat.gd")


## Every "down" the vessel feels: pitched anywhere from climbing (up toward
## the Head) to diving (up toward the Tail), and banked a little either way
## as it turns.
func _ups() -> Array[Vector3]:
	var ups: Array[Vector3] = []
	for pitch_deg in range(-90, 91, 15):
		var pitch := deg_to_rad(pitch_deg)
		for bank in [-0.2, 0.0, 0.2]:
			ups.append(Vector3(sin(bank), cos(bank) * cos(pitch), cos(bank) * sin(pitch)))
	return ups


func _places_in_use() -> Array[int]:
	var places: Array[int] = []
	for place in Habitat.STATIONS.size():
		if not Habitat.STATIONS[place][0].is_empty():
			places.append(place)
	return places


func _place_of(station_name: String) -> int:
	for place in Habitat.STATIONS.size():
		if Habitat.STATIONS[place][0] == station_name:
			return place
	return -1


## A lone gimbal at a place, settled onto up.
func _settled(place: int, up: Vector3) -> GimballedStation:
	var station: GimballedStation = auto_free(GimballedStation.new())
	station.position = Habitat.pivot(place)
	add_child(station)
	station.follow_up(Vector3.UP, 1.0)
	for i in 3:
		station.follow_up(up, 10.0)
	return station


func test_every_station_faces_the_bore_with_the_column_behind_its_screen_in_every_down() -> void:
	for up in _ups():
		for place in _places_in_use():
			var station := _settled(place, up)
			var pose := station.pose()
			var eye := pose.origin
			var view := -pose.basis.z
			var screen := station.screen_centre()
			var name: String = Habitat.STATIONS[place][0]

			# Looking at the screen is looking toward the Bore axis, as
			# squarely as standing upright allows.
			var toward_axis := Vector3(-screen.x, -screen.y, 0)
			var upright_toward := (toward_axis - up * toward_axis.dot(up)).normalized()
			assert_float(view.dot(upright_toward)) \
				.override_failure_message("%s faces away from the Bore, up %s" % [name, up]) \
				.is_greater(0.999)
			# The line of sight passes the screen before it comes nearest
			# the axis: the Column is behind the screen.
			var to_screen := (screen - eye).dot(view)
			var view_across := Vector2(view.x, view.y)
			var nearest_axis := -Vector2(eye.x, eye.y).dot(view_across) / view_across.length_squared()
			assert_float(nearest_axis) \
				.override_failure_message("%s has the Column in front of its screen, up %s" % [name, up]) \
				.is_greater(to_screen)


func test_the_drive_and_navigation_are_neighbours_on_the_ring() -> void:
	var count: int = Habitat.STATIONS.size()
	var drive := _place_of("Drive")
	var navigation := _place_of("Navigation")

	assert_int(drive).is_not_equal(-1)
	assert_int(navigation).is_not_equal(-1)
	assert_array([(drive + 1) % count, (drive + count - 1) % count]).contains([navigation])
