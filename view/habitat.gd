## The Habitat: an annular room around the Bore, seen only from inside.
## Owns the dive's simulation, advances it, and lets "down" follow the
## felt acceleration it reports. This node's axes are the simulation's
## Habitat frame (DiveSimulation.TOWARD_HEAD is -Z, the Head end cap).
## Dimensions are the prototype's starting values, not commitments.
extends Node3D

const BORE_RADIUS := 0.8
const OUTER_RADIUS := 3.3
const LENGTH := 2.4
## Stations pivot this far above the outer wall.
const STATION_HANG := 1.1
## Six Station positions; this dive uses five. "" is the empty mount
## where the Fabricator will go.
const STATIONS := [
	["Reactor", Color("ff7a45")],
	["Drive", Color("ffd24a")],
	["Thermal", Color("ff4a6a")],
	["Navigation", Color("4ad2ff")],
	["Bore Station", Color("b9ff6a")],
	["", Color.GRAY],
]
const PITCH_STEP := 15.0

var _sim := DiveSimulation.new(MediumLayout.uniform(Medium.sand()))
var _pitch_setting := 90.0
var _stations: Array[GimballedStation] = []
var _drive: GimballedStation
var _crew := CrewMember.new()

@onready var _dive_view: DiveView = %DiveView


func _ready() -> void:
	_sim.set_pitch(_pitch_setting)
	_dive_view.attach(_sim)
	_build_room()
	_build_stations()
	_crew.bore_radius = BORE_RADIUS
	_crew.outer_radius = OUTER_RADIUS
	_crew.length = LENGTH
	# Start standing on the Head end cap, which is the floor when diving.
	_crew.position = Vector3(0, -(OUTER_RADIUS + BORE_RADIUS) / 2.0, -LENGTH / 2.0 + CrewMember.BODY)
	_crew.basis = Basis.looking_at(Vector3.RIGHT, Vector3.BACK)
	add_child(_crew)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	elif event.is_action_pressed(&"ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	elif event is InputEventKey and event.pressed and not event.echo:
		match (event as InputEventKey).physical_keycode:
			KEY_1: _steer(90.0)
			KEY_2: _steer(0.0)
			KEY_3: _steer(-90.0)
			KEY_Z: _steer(_pitch_setting - PITCH_STEP)
			KEY_X: _steer(_pitch_setting + PITCH_STEP)


func _physics_process(delta: float) -> void:
	_sim.advance(delta)
	var felt := _sim.felt_acceleration()
	_crew.step(felt, delta)
	var up := -felt.normalized()
	for station in _stations:
		station.follow_up(up, delta)
	_drive.show_reading("Depth %.1f m\nPitch %+.0f deg (set %+.0f)" % [
		_sim.depth(), _sim.pitch(), _pitch_setting])


## Stand-in pitch control until the Drive Station has its own.
func _steer(pitch: float) -> void:
	_pitch_setting = clampf(pitch, -90.0, 90.0)
	_sim.set_pitch(_pitch_setting)


func _build_room() -> void:
	var outer := CylinderMesh.new()
	outer.top_radius = OUTER_RADIUS
	outer.bottom_radius = OUTER_RADIUS
	outer.height = LENGTH
	outer.radial_segments = 64
	outer.cap_top = false
	outer.cap_bottom = false
	outer.flip_faces = true
	_add_along_axis(outer, _surface(Color(0.17, 0.2, 0.22)), 0.0)

	# The Bore: glass round the Column, which stays in view from anywhere.
	var column := CylinderMesh.new()
	column.top_radius = BORE_RADIUS - 0.08
	column.bottom_radius = BORE_RADIUS - 0.08
	column.height = LENGTH
	_add_along_axis(column, _surface(Color(0.55, 0.42, 0.27)), 0.0)
	var glass := CylinderMesh.new()
	glass.top_radius = BORE_RADIUS
	glass.bottom_radius = BORE_RADIUS
	glass.height = LENGTH
	glass.cap_top = false
	glass.cap_bottom = false
	var glass_material := _surface(Color(0.62, 0.85, 1.0, 0.15))
	glass_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glass_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	_add_along_axis(glass, glass_material, 0.0)

	# Ribs round the outer wall and along it, so walking and turning show.
	for z in [-LENGTH / 3.0, 0.0, LENGTH / 3.0]:
		var rib := TorusMesh.new()
		rib.inner_radius = OUTER_RADIUS - 0.04
		rib.outer_radius = OUTER_RADIUS
		_add_along_axis(rib, _surface(Color(0.36, 0.45, 0.5)), z)
	for i in 12:
		var a := TAU * i / 12.0
		var strip := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(0.05, 0.02, LENGTH)
		strip.mesh = box
		strip.material_override = _surface(Color(0.36, 0.45, 0.5))
		strip.position = Vector3(cos(a), sin(a), 0) * (OUTER_RADIUS - 0.01)
		strip.basis = Basis(Vector3.BACK, a + PI / 2.0)
		add_child(strip)

	# End caps: the Head is warm, the Tail cool.
	_add_cap(-LENGTH / 2.0, Color(0.36, 0.22, 0.1), "HEAD", Color("e0964a"))
	_add_cap(LENGTH / 2.0, Color(0.09, 0.16, 0.24), "TAIL", Color("5aa2e0"))

	var light := OmniLight3D.new()
	light.omni_range = 8.0
	light.light_energy = 1.2
	light.position = Vector3(0, 0, 0)
	add_child(light)
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color.BLACK
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.5, 0.55, 0.6)
	environment.ambient_light_energy = 0.6
	var world := WorldEnvironment.new()
	world.environment = environment
	add_child(world)


func _build_stations() -> void:
	var pivot_radius := OUTER_RADIUS - STATION_HANG
	for i in STATIONS.size():
		var a := TAU * i / STATIONS.size() - PI / 2.0
		var outward := Vector3(cos(a), sin(a), 0)
		# The strut from the outer wall to the gimbal pivot.
		var strut := MeshInstance3D.new()
		var rod := CylinderMesh.new()
		rod.top_radius = 0.03
		rod.bottom_radius = 0.03
		rod.height = STATION_HANG
		strut.mesh = rod
		strut.material_override = _surface(Color(0.54, 0.6, 0.64))
		strut.position = outward * (OUTER_RADIUS - STATION_HANG / 2.0)
		strut.basis = Basis(Vector3.BACK, a - PI / 2.0)
		add_child(strut)

		var station := GimballedStation.new()
		station.station_name = STATIONS[i][0]
		station.hue = STATIONS[i][1]
		station.position = outward * pivot_radius
		add_child(station)
		_stations.append(station)
		if station.station_name == "Drive":
			_drive = station


func _add_cap(z: float, colour: Color, label: String, ink: Color) -> void:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var segments := 64
	for i in segments:
		var a0 := TAU * i / segments
		var a1 := TAU * (i + 1) / segments
		var i0 := Vector3(cos(a0), sin(a0), 0) * BORE_RADIUS
		var o0 := Vector3(cos(a0), sin(a0), 0) * OUTER_RADIUS
		var i1 := Vector3(cos(a1), sin(a1), 0) * BORE_RADIUS
		var o1 := Vector3(cos(a1), sin(a1), 0) * OUTER_RADIUS
		for v in [i0, o0, o1, i0, o1, i1]:
			tool.add_vertex(v)
	tool.generate_normals()
	var cap := MeshInstance3D.new()
	cap.mesh = tool.commit()
	var material := _surface(colour)
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	cap.material_override = material
	cap.position.z = z
	add_child(cap)
	# Words on the cap, readable from inside the room, at four places round it.
	var inward := 1.0 if z < 0.0 else -1.0
	for i in 4:
		var a := TAU * i / 4.0
		var text := Label3D.new()
		text.text = label
		text.modulate = ink
		text.font_size = 96
		text.pixel_size = 0.004
		text.position = Vector3(cos(a), sin(a), 0) * 2.05 + Vector3(0, 0, z + inward * 0.01)
		text.basis = Basis(Vector3.BACK, a - PI / 2.0)
		if inward < 0.0:
			text.basis = text.basis * Basis(Vector3.UP, PI)
		add_child(text)


func _add_along_axis(mesh: Mesh, material: Material, z: float) -> void:
	var node := MeshInstance3D.new()
	node.mesh = mesh
	node.material_override = material
	# Godot's cylinders and tori stand on Y; the Habitat's axis is Z.
	node.basis = Basis(Vector3.RIGHT, PI / 2.0)
	node.position.z = z
	add_child(node)


static func _surface(colour: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = colour
	return m
