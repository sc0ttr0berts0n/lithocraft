## Navigation's display: the point cloud, head-up. The Lithocraft is fixed at
## the centre with its Head up the screen, seen from over its back and right
## side (square to the Head), so the display turns only as the vessel does,
## never on its own. Rendered into its own world inside this SubViewport so a
## Station screen can show it as a texture.
##
## Reads only the simulation: points(), point_age() and pulses_sent() for the
## cloud; head_position(), heading() and heading_degrees() for the vessel;
## course_direction() for the Course Navigation has plotted, drawn as a dashed
## line out ahead among the points. The cloud is drawn in world metres and
## shifted by the Head's position each frame, so the points stream toward the
## marker at exactly the simulation's speed. Points fade with age; their
## places are rebuilt only when a pulse changes the cloud.
class_name ScanDisplay
extends SubViewport

## How far from the vessel the camera sits, in metres; how far round from
## over its back toward its right side, degrees, so a Course that differs in
## pitch shows beside the heading rather than behind it; and how far it leans
## back toward the Tail, degrees, so the view looks a little ahead.
const CAMERA_M := 220.0
const CAMERA_SIDE_DEG := 40.0
const CAMERA_LEAN_DEG := 20.0
## Point size on the screen in pixels.
const POINT_PX := 4.0
## Confidence colours: a guess is dim violet, certain is bright cyan-white.
const DOUBTFUL := Color(0.5, 0.35, 1.0)
const CERTAIN := Color(0.75, 1.0, 1.0)
## Seconds for a point to fade to about a third of its brightness: an old echo
## describes rock the vessel has since moved relative to.
const FADE_S := 90.0
## A plumb line under the vessel with a tick every this many metres, to read
## range by and to show which way is down.
const TICK_M := 50.0
const PLUMB_M := 400.0
## The Course line: how far out it reaches, metres, its dashes, and its colour
## (Navigation's own hue, apart from the vessel's amber heading).
const COURSE_M := 300.0
const COURSE_DASH_M := 12.0
const COURSE_COLOUR := Color(0.3, 0.85, 1.0)
const VESSEL_COLOUR := Color(1.0, 0.8, 0.3)

var sim: DiveSimulation

var _cloud := MultiMeshInstance3D.new()
## The points drawn, in the multimesh's order; their places are set when the
## cloud changes, their colours every frame as they age.
var _points: Array[ScanPoint] = []
var _pulses_shown := -1
var _vessel := Node3D.new()
var _heading := MeshInstance3D.new()
var _course := MeshInstance3D.new()
var _camera := Camera3D.new()


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
	box.size = Vector3(6.0, 6.0, 6.0)
	hull.mesh = box
	hull.material_override = _line_material(VESSEL_COLOUR)
	_vessel.add_child(hull)
	_heading.material_override = _line_material(Color(VESSEL_COLOUR, 0.8))
	_vessel.add_child(_heading)
	_course.material_override = _line_material(COURSE_COLOUR)
	_vessel.add_child(_course)
	var plumb := MeshInstance3D.new()
	plumb.mesh = _plumb_line()
	plumb.material_override = _line_material(Color(0.4, 0.5, 0.6, 0.6))
	_vessel.add_child(plumb)


func _process(_delta: float) -> void:
	if sim == null:
		return
	_place_camera()
	# The vessel stays at the centre; the cloud moves past it.
	_cloud.position = -sim.head_position()
	_heading.mesh = _line_to(sim.heading() * 60.0)
	_course.mesh = _dashes_to(sim.course_direction() * COURSE_M)
	if sim.pulses_sent() != _pulses_shown:
		_pulses_shown = sim.pulses_sent()
		_place_points(sim.points())
	_fade_points()


## Head up the screen: the camera sits over the vessel's back and right side,
## leaning toward the Tail, and looks at the vessel.
func _place_camera() -> void:
	var ahead := sim.heading()
	var bearing := deg_to_rad(sim.heading_degrees())
	var right := Vector3(cos(bearing), 0.0, sin(bearing))
	var back := right.cross(ahead).normalized()
	var side := deg_to_rad(CAMERA_SIDE_DEG)
	var lean := deg_to_rad(CAMERA_LEAN_DEG)
	var over := back * cos(side) + right * sin(side)
	_camera.position = (over * cos(lean) - ahead * sin(lean)) * CAMERA_M
	_camera.look_at(Vector3.ZERO, ahead)


func _place_points(points: Array[ScanPoint]) -> void:
	_points = points
	var multimesh := _cloud.multimesh
	multimesh.instance_count = points.size()
	for i in points.size():
		multimesh.set_instance_transform(i, Transform3D(Basis(), points[i].position))


func _fade_points() -> void:
	var multimesh := _cloud.multimesh
	for i in _points.size():
		var point := _points[i]
		var colour := DOUBTFUL.lerp(CERTAIN, point.confidence)
		colour.a = lerpf(0.35, 1.0, point.confidence) * exp(-sim.point_age(point) / FADE_S)
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
