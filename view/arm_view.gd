## Draws the Arm: the rail round the Bore, the carriage on it, the chain
## and the claw. Reads an Arm each frame; changes nothing in it.
class_name ArmView
extends Node3D

const AMBER := Color("ffb02e")
const RAIL_COLOUR := Color(0.78, 0.82, 0.85)

var arm: Arm
var rail_radius := 0.95

var _carriage := MeshInstance3D.new()
var _links: Array[MeshInstance3D] = []
var _claw := Node3D.new()
var _fingers: Array[MeshInstance3D] = []


func _ready() -> void:
	var rail := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = rail_radius - 0.03
	torus.outer_radius = rail_radius + 0.03
	rail.mesh = torus
	rail.material_override = _material(RAIL_COLOUR)
	rail.basis = Basis(Vector3.RIGHT, PI / 2.0)  # tori stand on Y; the Bore is Z
	add_child(rail)

	var box := BoxMesh.new()
	box.size = Vector3(0.18, 0.12, 0.24)
	_carriage.mesh = box
	_carriage.material_override = _material(AMBER)
	add_child(_carriage)

	var bead := SphereMesh.new()
	bead.radius = 0.035
	bead.height = 0.07
	bead.radial_segments = 8
	bead.rings = 4
	var amber := _material(AMBER)
	for i in Arm.CHAIN_LINKS:
		var link := MeshInstance3D.new()
		link.mesh = bead
		link.material_override = amber
		add_child(link)
		_links.append(link)

	add_child(_claw)
	var finger_mesh := BoxMesh.new()
	finger_mesh.size = Vector3(0.03, 0.18, 0.03)
	for side in [-1.0, 1.0]:
		var finger := MeshInstance3D.new()
		finger.mesh = finger_mesh
		finger.material_override = amber
		finger.set_meta(&"side", side)
		_claw.add_child(finger)
		_fingers.append(finger)


func _process(_delta: float) -> void:
	if arm == null:
		return
	var c := arm.carriage()
	_carriage.position = c
	_carriage.basis = _basis_with_up(Vector3(c.x, c.y, 0).normalized())

	var points := arm.chain()
	# points[0] is the carriage and the last is the claw; links go between.
	for i in _links.size():
		_links[i].position = points[i + 1]

	var hand := arm.hand()
	_claw.position = hand
	var toward := hand - points[points.size() - 2]
	if toward.length_squared() > 1e-8:
		_claw.basis = _basis_with_up(toward.normalized())
	var open := not arm.gripping()
	for finger in _fingers:
		var side: float = finger.get_meta(&"side")
		finger.position = Vector3(side * (0.07 if open else 0.035), 0.08, 0)
		finger.rotation = Vector3(0, 0, side * (-0.5 if open else 0.15))


static func _basis_with_up(up: Vector3) -> Basis:
	return Gimbal.toward_up(Basis(), up, 1.0)


static func _material(colour: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = colour
	return m
