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


func test_every_station_faces_the_bore_with_the_wall_behind_its_screen_in_every_down() -> void:
	for up in _ups():
		for place in DiveTestKit.station_places():
			var station := _settled(place, up)
			var pose := station.pose()
			var eye := pose.origin
			var view := -pose.basis.z
			var screen := station.screen_centre()
			var station_name := DiveTestKit.station_name(place)

			# Looking at the screen is looking away from the Bore axis, as
			# squarely as standing upright allows: the screen faces the Bore.
			var toward_axis := Vector3(-screen.x, -screen.y, 0)
			var upright_toward := (toward_axis - up * toward_axis.dot(up)).normalized()
			assert_float(view.dot(upright_toward)) \
				.override_failure_message("%s's screen faces away from the Bore, up %s" % [station_name, up]) \
				.is_less(-0.999)
			# The crew stand between the Bore and the screen: the line of
			# sight comes nearest the axis behind the eye.
			var view_across := Vector2(view.x, view.y)
			var nearest_axis := -Vector2(eye.x, eye.y).dot(view_across) / view_across.length_squared()
			assert_float(nearest_axis) \
				.override_failure_message("%s has the Column in front of the crew, up %s" % [station_name, up]) \
				.is_less(0.0)


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


## A crew member in a room of the Habitat's shape, dropped onto whatever is
## the floor under this felt acceleration at a Station's place round the ring,
## and left to settle there.
func _standing_under(place: int, felt: Vector3) -> CrewMember:
	var crew: CrewMember = auto_free(CrewMember.new())
	crew.bore_radius = Habitat.BORE_RADIUS
	crew.outer_radius = Habitat.OUTER_RADIUS
	crew.length = Habitat.LENGTH
	var pivot := Habitat.pivot(place)
	crew.position = Vector3(pivot.x, pivot.y, 0.0)
	for step in 1200:
		crew.step(felt, 1.0 / 60.0)
	return crew


func test_the_habitat_has_the_proportions_of_a_can_of_beans() -> void:
	# The developer's words: taller than wide, about 1.45 to 1 (issue #68).
	var tall_to_wide: float = Habitat.LENGTH / (2.0 * Habitat.OUTER_RADIUS)

	assert_float(tall_to_wide).is_between(1.4, 1.5)


func test_standing_on_the_head_end_floor_in_a_dive_every_station_is_within_reach() -> void:
	var diving := Vector3.FORWARD * 9.8  # felt toward the Head: its cap is the floor
	for place in DiveTestKit.station_places():
		var crew := _standing_under(place, diving)
		var station_name := DiveTestKit.station_name(place)

		assert_float(crew.position.z) 			.override_failure_message("the crew did not land on the Head end floor") 			.is_less(-Habitat.LENGTH / 2.0 + 2.0 * CrewMember.BODY)
		assert_float(crew.position.distance_to(Habitat.pivot(place))) 			.override_failure_message("%s is out of reach from the Head end floor" % station_name) 			.is_less_equal(Habitat.STATION_REACH)


func test_standing_on_the_head_end_floor_in_a_dive_every_screen_is_at_eye_level() -> void:
	var diving := Vector3.FORWARD * 9.8
	for place in DiveTestKit.station_places():
		var eye := _standing_under(place, diving).eye().origin
		var pivot := Habitat.pivot(place)
		var screen := GimballedStation.screen_centre_for(pivot,
				GimballedStation.settled_cradle(pivot, Vector3.BACK, Basis()))

		# The eyes are no higher than the screen's top nor lower than its foot.
		assert_float(absf(eye.z - screen.z)) 			.override_failure_message("%s's screen is not at eye level" % DiveTestKit.station_name(place)) 			.is_less(GimballedStation.SCREEN_SIZE.y / 2.0)


func test_every_screen_and_key_panel_stays_inside_the_room_in_every_down() -> void:
	var half_screen := GimballedStation.SCREEN_SIZE / 2.0 + Vector2.ONE * GimballedStation.CASING
	# The key panel hangs off the cradle's -x side of the screen.
	var keys_edge := -(GimballedStation.SCREEN_SIZE.x / 2.0 + GimballedStation.KEYS_GAP 			+ GimballedStation.KEYS_WIDTH + GimballedStation.CASING)
	for up in _ups():
		for place in DiveTestKit.station_places():
			var pivot := Habitat.pivot(place)
			var cradle := GimballedStation.settled_cradle(pivot, up, Basis())
			for x in [keys_edge, half_screen.x]:
				for y in [-half_screen.y, half_screen.y]:
					var corner := pivot + cradle * (GimballedStation.SCREEN_CENTRE + Vector3(x, y, 0.0))
					var where := "%s's corner %s, up %s" % [DiveTestKit.station_name(place), corner, up]
					assert_float(Vector2(corner.x, corner.y).length()) 						.override_failure_message("through the outer wall: " + where) 						.is_less(Habitat.OUTER_RADIUS)
					assert_float(Vector2(corner.x, corner.y).length()) 						.override_failure_message("through the Bore glass: " + where) 						.is_greater(Habitat.BORE_RADIUS)
					assert_float(absf(corner.z)) 						.override_failure_message("through an end cap: " + where) 						.is_less(Habitat.LENGTH / 2.0)
