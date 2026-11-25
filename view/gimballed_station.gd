## A Station hung on a gimbal at its pivot. It swings so its own up follows
## the crew's "up", lagging a little so the swing can be seen.
## Without a name it is an empty mount: the gimbal with no Station on it.
class_name GimballedStation
extends Node3D

## How quickly the gimbal settles onto a new "up", per second.
const SWING_RATE := 3.0
## Middle of the screen, in the cradle's frame.
const SCREEN_CENTRE := Vector3(0, 0.2, 0)
## Eyes of a crew member working the Station, in the cradle's frame: in front
## of the screen and at standing eye height (1.65 m) above a floor 1.1 m
## below the pivot.
const POSE_EYE := Vector3(0, 0.55, -0.85)

var station_name := ""
var hue := Color.WHITE

var _cradle := Node3D.new()
var _screen_text: Label3D


func _ready() -> void:
	add_child(_cradle)
	_add_yoke()
	if station_name.is_empty():
		return
	var desk := MeshInstance3D.new()
	var desk_mesh := BoxMesh.new()
	desk_mesh.size = Vector3(0.9, 0.04, 0.5)
	desk.mesh = desk_mesh
	desk.material_override = _material(Color(0.29, 0.34, 0.37))
	desk.position = Vector3(0, -0.08, 0)
	_cradle.add_child(desk)

	var screen := MeshInstance3D.new()
	var screen_mesh := BoxMesh.new()
	screen_mesh.size = Vector3(0.8, 0.4, 0.02)
	screen.mesh = screen_mesh
	screen.material_override = _material(Color(0.04, 0.07, 0.09))
	screen.position = SCREEN_CENTRE
	_cradle.add_child(screen)

	# The screen faces the Head; the crew work it from the Head side.
	_screen_text = Label3D.new()
	_screen_text.text = station_name
	_screen_text.modulate = hue
	_screen_text.pixel_size = 0.0015
	_screen_text.font_size = 48
	_screen_text.position = SCREEN_CENTRE + Vector3(0, 0, -0.015)
	_screen_text.rotation = Vector3(0, PI, 0)
	_cradle.add_child(_screen_text)


## Text shown on the Station's screen, under its name.
func show_reading(text: String) -> void:
	if _screen_text:
		_screen_text.text = "%s\n%s" % [station_name, text]


## Where a crew member's eyes are held to work this Station, Habitat frame:
## origin at the eyes, basis upright with the cradle, facing the screen.
func pose() -> Transform3D:
	return pose_for(position, _cradle.basis)


## The middle of this Station's screen, Habitat frame.
func screen_centre() -> Vector3:
	return screen_centre_for(position, _cradle.basis)


## The working pose of a Station pivoting at pivot with its cradle at cradle.
## The eyes are where a person standing STATION_HANG below the pivot would
## have them, on the Head side of the cradle, as the screen faces that way.
static func pose_for(pivot: Vector3, cradle: Basis) -> Transform3D:
	var facing_screen := cradle * Basis(Vector3.UP, PI)
	return Transform3D(facing_screen, pivot + cradle * POSE_EYE)


static func screen_centre_for(pivot: Vector3, cradle: Basis) -> Vector3:
	return pivot + cradle * SCREEN_CENTRE


## How far to look down from level, in radians, to see the screen from the pose.
static func pose_look() -> float:
	return -atan2(POSE_EYE.y - SCREEN_CENTRE.y, -POSE_EYE.z)


## Swing toward the given "up" (Habitat frame, unit length).
func follow_up(up: Vector3, dt: float) -> void:
	_cradle.basis = Gimbal.toward_up(_cradle.basis, up, 1.0 - exp(-dt * SWING_RATE))


func _add_yoke() -> void:
	# A ring at the pivot so the gimbal itself is visible.
	var yoke := MeshInstance3D.new()
	var ring := TorusMesh.new()
	ring.inner_radius = 0.1
	ring.outer_radius = 0.13
	yoke.mesh = ring
	yoke.material_override = _material(Color(0.54, 0.6, 0.64))
	yoke.rotation = Vector3(PI / 2, 0, 0)
	add_child(yoke)
	var bob := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.05
	sphere.height = 0.1
	bob.mesh = sphere
	bob.material_override = _material(hue if not station_name.is_empty() else Color(0.4, 0.4, 0.4))
	_cradle.add_child(bob)


static func _material(colour: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = colour
	return m
