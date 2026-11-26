## Navigation's display: the point cloud seen from a camera that circles the
## Head, in the manner of Scanner Sombre. Rendered into its own world inside
## this SubViewport so a Station screen can show it as a texture.
##
## Reads only the simulation: points() for the cloud, head_position() and
## heading() for the vessel, course_direction() for the Course Navigation has
## plotted, drawn as a dashed line out ahead among the points. The cloud is drawn in world metres and shifted by
## the Head's position each frame, so the vessel moves through it at exactly
## the simulation's speed; it is rebuilt only when a pulse adds points.
class_name ScanDisplay
extends SubViewport

## How far the camera circles round a point this far ahead of the Head, in
## metres, and how fast.
const LOOK_AHEAD_M := 70.0
const ORBIT_M := 170.0
const ORBIT_RATE := 0.15
const ORBIT_LIFT := 0.45
## Point size on the screen in pixels.
const POINT_PX := 4.0
## Confidence colours: a guess is dim violet, certain is bright cyan-white.
const DOUBTFUL := Color(0.5, 0.35, 1.0)
const CERTAIN := Color(0.75, 1.0, 1.0)
## A plumb line under the vessel with a tick every this many metres, to read
## range by.
const TICK_M := 50.0
const PLUMB_M := 400.0
## The Course line: how far out it reaches, metres, its dashes, and its colour
## (Navigation's own hue, apart from the vessel's amber heading).
const COURSE_M := 300.0
const COURSE_DASH_M := 12.0
const COURSE_COLOUR := Color(0.3, 0.85, 1.0)

var sim: DiveSimulation

var _cloud := MultiMeshInstance3D.new()
var _shown := -1
var _vessel := Node3D.new()
var _heading := MeshInstance3D.new()
var _course := MeshInstance3D.new()
var _camera := Camera3D.new()
var _orbit := 0.0


func _ready() -> void:
	own_world_3d = true
	render_target_update_mode = SubViewport.UPDATE_ALWAYS

	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0.01, 0.015, 0.025)
	_camera.environment = environment
	_camera.far = 2000.0
	add_child(_camera)

	var multimesh := MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.use_colors = true
	multimesh.mesh = PointMesh.new()
	_cloud.multimesh = multimesh
	var point_material := StandardMaterial3D.new()
	point_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	point_material.vertex_color_use_as_albedo = true
	point_material.use_point_size = true
	point_material.point_size = POINT_PX
	point_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_cloud.material_override = point_material
	add_child(_cloud)

	add_child(_vessel)
	var hull := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(4.0, 4.0, 4.0)
	hull.mesh = box
	hull.material_override = _line_material(Color(1.0, 0.8, 0.3))
	_vessel.add_child(hull)
	_heading.material_override = _line_material(Color(1.0, 0.8, 0.3, 0.8))
	_vessel.add_child(_heading)
	_course.material_override = _line_material(COURSE_COLOUR)
	_vessel.add_child(_course)
	var plumb := MeshInstance3D.new()
	plumb.mesh = _plumb_line()
	plumb.material_override = _line_material(Color(0.4, 0.5, 0.6, 0.6))
	_vessel.add_child(plumb)


func _process(delta: float) -> void:
	if sim == null:
		return
	_orbit += ORBIT_RATE * delta
	var head := sim.head_position()
	var target := sim.heading() * LOOK_AHEAD_M
	_camera.position = target + Vector3(sin(_orbit), ORBIT_LIFT, cos(_orbit)).normalized() * ORBIT_M
	_camera.look_at(target, Vector3.UP)
	# The vessel stays at the centre; the cloud moves past it.
	_cloud.position = -head
	_heading.mesh = _line_to(sim.heading() * 60.0)
	_course.mesh = _dashes_to(sim.course_direction() * COURSE_M)
	if sim.point_count() != _shown:
		_show_points(sim.points())


func _show_points(points: Array[ScanPoint]) -> void:
	_shown = points.size()
	var multimesh := _cloud.multimesh
	multimesh.instance_count = points.size()
	for i in points.size():
		var point := points[i]
		multimesh.set_instance_transform(i, Transform3D(Basis(), point.position))
		var colour := DOUBTFUL.lerp(CERTAIN, point.confidence)
		colour.a = lerpf(0.35, 1.0, point.confidence)
		multimesh.set_instance_color(i, colour)


static func _line_to(end: Vector3) -> ImmediateMesh:
	var mesh := ImmediateMesh.new()
	mesh.surface_begin(Mesh.PRIMITIVE_LINES)
	mesh.surface_add_vertex(Vector3.ZERO)
	mesh.surface_add_vertex(end)
	mesh.surface_end()
	return mesh


static func _dashes_to(end: Vector3) -> ImmediateMesh:
	var mesh := ImmediateMesh.new()
	mesh.surface_begin(Mesh.PRIMITIVE_LINES)
	var length := end.length()
	var along := 0.0
	while along < length:
		mesh.surface_add_vertex(end * (along / length))
		mesh.surface_add_vertex(end * (minf(along + COURSE_DASH_M, length) / length))
		along += 2.0 * COURSE_DASH_M
	mesh.surface_end()
	return mesh


static func _plumb_line() -> ImmediateMesh:
	var mesh := ImmediateMesh.new()
	mesh.surface_begin(Mesh.PRIMITIVE_LINES)
	mesh.surface_add_vertex(Vector3.ZERO)
	mesh.surface_add_vertex(Vector3.DOWN * PLUMB_M)
	var depth := TICK_M
	while depth <= PLUMB_M:
		mesh.surface_add_vertex(Vector3(-6.0, -depth, 0.0))
		mesh.surface_add_vertex(Vector3(6.0, -depth, 0.0))
		mesh.surface_add_vertex(Vector3(0.0, -depth, -6.0))
		mesh.surface_add_vertex(Vector3(0.0, -depth, 6.0))
		depth += TICK_M
	mesh.surface_end()
	return mesh


static func _line_material(colour: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = colour
	if colour.a < 1.0:
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	return m
