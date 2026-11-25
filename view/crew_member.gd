## The player, walking the Habitat in first person. Falls along the felt
## acceleration it is given, turns its own "up" smoothly to oppose it, and
## stands on whichever wall that puts underfoot. Collision with the Habitat
## is worked out from its shape (a ring between two cylinders and two caps).
## View code: the simulation is told nothing about where the crew stand.
class_name CrewMember
extends Node3D

## Radius of the body, metres. Also how far the feet are below the body centre.
const BODY := 0.3
## Eye height above the body centre, metres.
const EYE := 1.35
const WALK_SPEED := 3.0
## How quickly the body turns to a new "up", per second.
const UPRIGHT_RATE := 6.0
const MOUSE_SENSITIVITY := 0.0025
const LOOK_LIMIT := 1.5

var bore_radius := 0.8
var outer_radius := 3.3
var length := 2.4

var _velocity := Vector3.ZERO
var _look := 0.0
## While the Arm holds the crew member: how far the mouse has turned them in
## the harness from the held pose (about their own up), and whether the
## mouse has moved since the look last settled, which makes it their own.
var _held := false
var _held_turn := 0.0
var _looked := false
var _grounded := false
var _camera := Camera3D.new()


func _init() -> void:
	# A child from the start, so it is freed with the crew member even if
	# they never enter the tree (as in tests).
	_camera.fov = 80.0
	_camera.near = 0.05
	_camera.position = Vector3(0, EYE, 0)
	add_child(_camera)


func _ready() -> void:
	_camera.make_current()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		look((event as InputEventMouseMotion).relative)


## Turn the view by this much mouse travel, in pixels: across turns about the
## crew member's own up, down lowers the look. On foot it turns the body;
## held by the Arm it turns them in the harness, the same in every "down".
func look(relative: Vector2) -> void:
	var turn := -relative.x * MOUSE_SENSITIVITY
	if _held:
		_held_turn += turn
		_looked = true
	basis = basis * Basis(Vector3.UP, turn)
	_look = clampf(_look - relative.y * MOUSE_SENSITIVITY, -LOOK_LIMIT, LOOK_LIMIT)
	_camera.rotation = Vector3(_look, 0, 0)


## One physics step. felt is the felt acceleration in the Habitat frame.
func step(felt: Vector3, dt: float) -> void:
	_held = false
	var up_target := -felt.normalized()
	basis = Gimbal.toward_up(basis, up_target, 1.0 - exp(-dt * UPRIGHT_RATE))
	var up := basis.y
	var wish := _wish_direction()

	_velocity += felt * dt
	if _grounded:
		var normal_speed := _velocity.dot(up)
		var along := _velocity - up * normal_speed
		along = along.lerp(wish * WALK_SPEED, 1.0 - exp(-dt * 10.0))
		_velocity = along + up * normal_speed
	position += _velocity * dt
	_collide(up)


## Shakes the view by up to this many metres this frame (a jolt the body
## feels, e.g. a poor Shift's lurch); 0 holds it still.
func shake(metres: float) -> void:
	_camera.h_offset = randf_range(-metres, metres)
	_camera.v_offset = randf_range(-metres, metres)


## Where the eyes are and which way the body faces (Habitat frame).
func eye() -> Transform3D:
	return Transform3D(basis, position + basis.y * EYE)


## Where the eyes are and which way they look, up/down look included
## (Habitat frame, unshaken): the centre dot lies along -basis.z.
func view() -> Transform3D:
	var at := eye()
	return Transform3D(at.basis * Basis(Vector3.RIGHT, _look), at.origin)


## Held by the Arm instead of stepping: eyes put at eye_pose, nothing falls,
## turned in the harness as far as the mouse has turned them. While carried
## the look eases by weight (0..1) toward look_toward (up/down) and the
## pose's own facing, unless the mouse has moved since it last settled
## (weight 0, seated): then the look is the crew member's own and is kept.
func hold(eye_pose: Transform3D, look_toward: float, weight: float) -> void:
	if not _held:
		# Just caught: the Arm took the eyes as they were, turn and all.
		_held = true
		_held_turn = 0.0
	if weight <= 0.0:
		_looked = false
	elif not _looked:
		_look = lerpf(_look, look_toward, weight)
		_held_turn = lerpf(_held_turn, 0.0, weight)
	basis = eye_pose.basis.orthonormalized() * Basis(Vector3.UP, _held_turn)
	position = eye_pose.origin - basis.y * EYE
	_velocity = Vector3.ZERO
	_grounded = false
	_camera.rotation = Vector3(_look, 0, 0)


func _wish_direction() -> Vector3:
	var forward := -basis.z
	var right := basis.x
	# The walk keys from the key map: forward, left, back, right.
	var down := KeyMap.held(&"walk")
	var f := float(down[0]) - float(down[2])
	var r := float(down[3]) - float(down[1])
	var wish := forward * f + right * r
	return wish.normalized() if wish.length_squared() > 0.0 else Vector3.ZERO


func _collide(up: Vector3) -> void:
	_grounded = false
	var radial := Vector2(position.x, position.y)
	var r := maxf(radial.length(), 1e-6)
	if r > outer_radius - BODY:
		radial *= (outer_radius - BODY) / r
		_hit(Vector3(-radial.x, -radial.y, 0).normalized(), up)
	elif r < bore_radius + BODY:
		radial *= (bore_radius + BODY) / r
		_hit(Vector3(radial.x, radial.y, 0).normalized(), up)
	position.x = radial.x
	position.y = radial.y
	var half := length / 2.0 - BODY
	if position.z > half:
		position.z = half
		_hit(Vector3.FORWARD, up)
	elif position.z < -half:
		position.z = -half
		_hit(Vector3.BACK, up)


## normal points from the surface into the room.
func _hit(normal: Vector3, up: Vector3) -> void:
	var into := _velocity.dot(normal)
	if into < 0.0:
		_velocity -= normal * into
	if up.dot(normal) > 0.6:
		_grounded = true
