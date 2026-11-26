# Tests at the pointer's seam: where the eyes are and which way they look,
# the Station screens as faces in the Habitat frame, and what lies under
# the centre dot. Plain data, no scene: the Habitat's geometry is rebuilt
# here from its documented dimensions, as in arm_test.gd.
extends GdUnitTestSuite

const BORE_RADIUS := 0.8
const PIVOT_RADIUS := 2.2
const STATION_COUNT := 6

const LEVEL := Vector3.UP
const DIVING := Vector3.BACK      # down is toward the Head (-Z)
const CLIMBING := Vector3.FORWARD # down is toward the Tail (+Z)


func _pivot(place: int) -> Vector3:
	var a := TAU * place / STATION_COUNT - PI / 2.0
	return Vector3(cos(a), sin(a), 0) * PIVOT_RADIUS


func _cradle(up: Vector3) -> Basis:
	return Gimbal.toward_up(Basis(), up, 1.0)


## A face with two readings, one above the other, inside its screen.
func _face(pivot: Vector3, cradle: Basis) -> Pointing.Face:
	var face := GimballedStation.face_for(pivot, cradle)
	var half := face.bounds.size / 2.0
	face.readings = [
		Rect2(Vector2(-half.x, 0.0), Vector2(half.x * 2.0, half.y)),
		Rect2(Vector2(-half.x, -half.y), Vector2(half.x * 2.0, half.y)),
	]
	return face


func _faces(up: Vector3) -> Array[Pointing.Face]:
	var faces: Array[Pointing.Face] = []
	for place in STATION_COUNT:
		faces.append(_face(_pivot(place), _cradle(up)))
	return faces


## The direction from the eyes to a point on a face (face coordinates).
func _toward(eye: Vector3, face: Pointing.Face, at: Vector2) -> Vector3:
	return (face.transform * Vector3(at.x, at.y, 0.0) - eye).normalized()


## Seated at a Station, looking at its screen as the Arm leaves the crew.
func _seated_look(place: int, up: Vector3) -> Transform3D:
	var pose := GimballedStation.pose_for(_pivot(place), _cradle(up))
	return pose * Transform3D(Basis(Vector3.RIGHT, GimballedStation.pose_look()), Vector3.ZERO)


func test_seated_at_a_station_in_every_down_the_dot_lies_on_its_screen() -> void:
	for up in [LEVEL, DIVING, CLIMBING]:
		var faces := _faces(up)
		for place in STATION_COUNT:
			var look := _seated_look(place, up)

			var under := Pointing.under(look.origin, -look.basis.z, faces, BORE_RADIUS)

			assert_int(under.get("face", -1)).is_equal(place)


func test_the_dot_names_the_reading_it_lies_on() -> void:
	var faces := _faces(LEVEL)
	var eye := _seated_look(0, LEVEL).origin
	var face := faces[0]
	for reading in face.readings.size():
		var direction := _toward(eye, face, face.readings[reading].get_center())

		var under := Pointing.under(eye, direction, faces, BORE_RADIUS)

		assert_int(under.face).is_equal(0)
		assert_int(under.reading).is_equal(reading)


func test_on_a_screen_but_off_every_reading_names_the_screen_alone() -> void:
	var faces := _faces(LEVEL)
	var face := faces[0]
	face.readings = [face.readings[0]]
	var eye := _seated_look(0, LEVEL).origin
	var below := Vector2(0.0, -face.bounds.size.y / 4.0)

	var under := Pointing.under(eye, _toward(eye, face, below), faces, BORE_RADIUS)

	assert_int(under.face).is_equal(0)
	assert_int(under.reading).is_equal(-1)


func test_a_reading_beyond_the_screen_edge_is_still_pointed_at() -> void:
	# Text set above a display sits past the screen's own edge.
	var faces := _faces(LEVEL)
	var face := faces[0]
	var top := face.bounds.end.y
	face.readings.append(Rect2(Vector2(-0.1, top), Vector2(0.2, 0.1)))
	var eye := _seated_look(0, LEVEL).origin

	var under := Pointing.under(eye, _toward(eye, face, Vector2(0.0, top + 0.05)), faces, BORE_RADIUS)

	assert_int(under.face).is_equal(0)
	assert_int(under.reading).is_equal(face.readings.size() - 1)


func test_looking_away_from_every_screen_points_at_nothing() -> void:
	var look := _seated_look(0, LEVEL)

	var under := Pointing.under(look.origin, look.basis.z, _faces(LEVEL), BORE_RADIUS)

	assert_bool(under.is_empty()).is_true()


func test_a_screen_seen_from_behind_is_not_pointed_at() -> void:
	var faces := _faces(LEVEL)
	var face := faces[0]
	var centre := face.transform.origin
	var behind := centre - face.transform.basis.z * 0.5

	var under := Pointing.under(behind, (centre - behind).normalized(), faces, BORE_RADIUS)

	assert_bool(under.is_empty()).is_true()


func test_of_two_screens_in_line_the_nearer_is_pointed_at() -> void:
	var far := _face(Vector3(0, 2.0, 0), Basis())
	var near := _face(Vector3(0, 2.0, -0.5), Basis())
	var faces: Array[Pointing.Face] = [far, near]
	var eye := near.transform.origin + near.transform.basis.z * 0.5

	var under := Pointing.under(eye, -near.transform.basis.z, faces, BORE_RADIUS)

	assert_int(under.face).is_equal(1)


func test_the_column_in_the_bore_hides_the_screens_across_it() -> void:
	var faces := _faces(LEVEL)
	# The Station across the ring from the Reactor, seen through the Bore.
	var across := faces[3]
	var eye := Vector3(0, -2.0, -0.85)
	var look := _toward(eye, across, Vector2.ZERO)

	var hidden := Pointing.under(eye, look, faces, BORE_RADIUS)
	var with_no_column := Pointing.under(eye, look, faces, 0.0)

	assert_bool(hidden.is_empty()).is_true()
	assert_int(with_no_column.get("face", -1)).is_equal(3)


## A Station built outside the tree, its screen and text made as in the
## Habitat (_ready builds them; nothing here needs the tree).
func _station(display: bool) -> GimballedStation:
	var station: GimballedStation = auto_free(GimballedStation.new())
	station.station_name = "Test"
	station._ready()
	if display:
		station.show_display(ImageTexture.create_from_image(Image.create(4, 4, false, Image.FORMAT_RGB8)))
	station.show_reading("first\nsecond")
	return station


func test_a_screens_readings_are_its_lines_top_to_bottom_then_its_display() -> void:
	for display in [false, true]:
		var station := _station(display)

		var readings := station.face().readings

		var lines := ["Test", "first", "second"]
		assert_int(readings.size()).is_equal(lines.size() + (1 if display else 0))
		for i in lines.size():
			assert_str(station.reading(i)).is_equal(lines[i])
			assert_bool(station.is_display(i)).is_false()
			if i > 0:
				assert_float(readings[i].end.y).is_less_equal(readings[i - 1].position.y + 0.0001)
		if display:
			assert_bool(station.is_display(lines.size())).is_true()
			assert_float(readings[lines.size()].end.y).is_less_equal(readings[lines.size() - 1].position.y + 0.0001)


func test_each_line_of_text_is_pointed_at_from_the_working_pose() -> void:
	var station := _station(true)
	var face := station.face()
	var faces: Array[Pointing.Face] = [face]
	var eye := station.pose().origin
	for i in 3:
		var under := Pointing.under(eye, _toward(eye, face, face.readings[i].get_center()), faces, BORE_RADIUS)

		assert_int(under.reading).is_equal(i)
