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
## The Column inside the Bore glass.
const COLUMN_RADIUS := BORE_RADIUS - 0.08
## How far the Habitat's Head-side wall is behind the Head, in metres: the
## length of the Head section the Column passes through first. A guess for
## play, not a commitment.
const HABITAT_BEHIND_HEAD_M := 3.0
## Resolution of the Column's surface texture. LENGTH times this should be a
## whole number of pixels so the texture spans the Bore exactly.
const COLUMN_PIXELS_PER_METRE := 125.0
## How much one press moves the heat split at the Thermal Station.
const HEAT_SPLIT_STEP := 0.1
## How close the crew must be to a Station's pivot to work it, in metres.
const STATION_REACH := 2.0

var _sim := DiveSimulation.new(MediumLayout.first_dive())
var _pitch_setting := 90.0
var _stations: Array[GimballedStation] = []
var _reactor: GimballedStation
var _drive: GimballedStation
var _thermal: GimballedStation
## Thermal Station setting: share of heat sent into the Column.
var _heat_split := 0.0
var _navigation: GimballedStation
var _crew := CrewMember.new()

@onready var _dive_view: DiveView = %DiveView


func _ready() -> void:
	_sim.set_pitch(_pitch_setting)
	_sim.set_heat_split(_heat_split)
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
			KEY_C: _split_heat(_heat_split - HEAT_SPLIT_STEP)
			KEY_V: _split_heat(_heat_split + HEAT_SPLIT_STEP)
			KEY_P: _sim.pulse()
			KEY_Q: _sim.set_quiet_ship(not _sim.quiet_ship())


func _physics_process(delta: float) -> void:
	_sim.advance(delta)
	var felt := _sim.felt_acceleration()
	_crew.step(felt, delta)
	var up := -felt.normalized()
	for station in _stations:
		station.follow_up(up, delta)
	_drive.set_supplied(_sim.drive_supplied())
	_thermal.set_supplied(_sim.thermal_supplied())
	_navigation.set_supplied(_sim.navigation_supplied())
	_show_reactor()
	_drive.show_reading("Depth %.1f m\nPitch %+.0f deg (set %+.0f)\n%s" % [
		_sim.depth(), _sim.pitch(), _pitch_setting,
		_power_line(_sim.drive_request(), _sim.drive_draw())])
	_show_thermal()
	_navigation.show_reading("%s  noise %d%%  %d points\n%s\n[P] pulse  [Q] Quiet Ship" % [
		"QUIET SHIP" if _sim.quiet_ship() else "under way",
		roundi(_sim.noise() * 100.0), _sim.point_count(),
		_power_line(_sim.navigation_request(), _sim.navigation_draw())])


## Stand-in pitch control until the Drive Station has its own.
func _steer(pitch: float) -> void:
	_pitch_setting = clampf(pitch, -90.0, 90.0)
	_sim.set_pitch(_pitch_setting)


## A Station's power: what it asks for and gets, and STARVED when short.
static func _power_line(requested: float, drawn: float) -> String:
	var line := "Power %d/%d%%" % [roundi(drawn * 100.0), roundi(requested * 100.0)]
	if drawn < requested - 0.0005:
		line += "  STARVED"
	return line


## The Reactor Station's screen: the Head's plasma, the power it supplies
## against what the Stations draw, and one bar per Station, its request
## outlined and what it gets filled, so a starved Station shows here too.
func _show_reactor() -> void:
	var output := _sim.reactor_output()
	var plasma := "STEADY" if _sim.plasma_stability() >= 1.0 else "UNSTEADY"
	var lines := [
		"Plasma %s %d%%  Head %s" % [plasma, roundi(_sim.plasma_stability() * 100.0),
			"running" if _sim.head_activity() >= 1.0 else "idling %d%%" % roundi(_sim.head_activity() * 100.0)],
		"Supply %d%%  drawn %d%%  short %d%%" % [roundi(output * 100.0),
			roundi(_sim.power_drawn() * 100.0),
			roundi((_sim.power_requested() - _sim.power_drawn()) * 100.0)],
	]
	for row in [["Nav", _sim.navigation_request(), _sim.navigation_draw()],
			["Thm", _sim.thermal_request(), _sim.thermal_draw()],
			["Drv", _sim.drive_request(), _sim.drive_draw()]]:
		lines.append("%s %s%s" % [row[0], _bar(row[1], row[2]),
				"  STARVED" if row[2] < row[1] - 0.0005 else ""])
	# The Drive running short is routine; Thermal or Navigation starved is not.
	_reactor.set_calling(_sim.navigation_supplied() < 1.0 or _sim.thermal_supplied() < 1.0)
	_reactor.show_reading("\n".join(lines))


## A bar of tenths: '#' power drawn, '-' asked for but not given, '.' unused.
static func _bar(requested: float, drawn: float) -> String:
	var got := roundi(drawn * 10.0)
	var asked := maxi(got, roundi(requested * 10.0))
	return "[%s%s%s]" % ["#".repeat(got), "-".repeat(asked - got), ".".repeat(maxi(0, 10 - asked))]


## The heat split is worked at the Thermal Station: only within reach of it.
func _split_heat(to_column: float) -> void:
	if _crew.position.distance_to(_thermal.position) > STATION_REACH:
		return
	_heat_split = clampf(snappedf(to_column, HEAT_SPLIT_STEP), 0.0, 1.0)
	_sim.set_heat_split(_heat_split)


## The Thermal Station's screen: the split, where the heat is going, the hull
## against the Medium and the temperature it can bear, and wear. It calls with
## its light while the simulation warns of heat damage.
func _show_thermal() -> void:
	var warning := _sim.heat_warning()
	_thermal.set_calling(warning)
	var to_column := roundi(_heat_split * 10.0)
	var lines := [
		_power_line(_sim.thermal_request(), _sim.thermal_draw()),
		"Out [%s|%s] Column" % ["#".repeat(10 - to_column), "#".repeat(to_column)],
		"Heat %.2f > Column %.2f" % [_sim.heat_produced(), _sim.heat_to_column()],
		"Hull %.0f K, bears %.0f K" % [
			_sim.vessel_temperature(), _sim.hull_damage_temperature()],
		"Medium %.0f K  Wear %.1f%%" % [
			_sim.surroundings_temperature(), _sim.vessel_wear() * 100.0],
	]
	if warning:
		lines.append("!! HEAT WARNING !!")
	_thermal.show_reading("\n".join(lines))


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
	var column := MeshInstance3D.new()
	column.mesh = _column_tube()
	column.material_override = _column_material()
	add_child(column)
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
		if station.station_name in ["Thermal", "Reactor"]:
			station.screen_font_size = 28
		station.position = outward * pivot_radius
		add_child(station)
		_stations.append(station)
		if station.station_name == "Reactor":
			_reactor = station
		elif station.station_name == "Drive":
			_drive = station
		elif station.station_name == "Thermal":
			_thermal = station
		elif station.station_name == "Navigation":
			_navigation = station
			_navigation.show_display(_scan_display())


## Navigation's point cloud display, drawn in its own world and shown on the
## Navigation Station's screen.
func _scan_display() -> Texture2D:
	var display := ScanDisplay.new()
	display.size = Vector2i(512, 242)
	display.sim = _sim
	add_child(display)
	return display.get_texture()


## The Column as an open tube along the Bore, with the whole texture on its
## side: u runs round it, v from 0 at the Tail end (+Z) to 1 at the Head end
## (-Z), matching ColumnStrip, which draws the Head end at the bottom.
## (Godot's CylinderMesh shares its texture with its caps, so it can't.)
func _column_tube() -> ArrayMesh:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var segments := 48
	var tail := LENGTH / 2.0
	var head := -LENGTH / 2.0
	for i in segments:
		var u0 := float(i) / segments
		var u1 := float(i + 1) / segments
		var r0 := Vector3(cos(u0 * TAU), sin(u0 * TAU), 0)
		var r1 := Vector3(cos(u1 * TAU), sin(u1 * TAU), 0)
		var quad := [
			[r0, tail, Vector2(u0, 0)], [r1, tail, Vector2(u1, 0)], [r1, head, Vector2(u1, 1)],
			[r0, tail, Vector2(u0, 0)], [r1, head, Vector2(u1, 1)], [r0, head, Vector2(u0, 1)],
		]
		for corner in quad:
			tool.set_normal(corner[0])
			tool.set_uv(corner[2])
			tool.add_vertex(corner[0] * COLUMN_RADIUS + Vector3(0, 0, corner[1]))
	return tool.commit()


## The Column's surface: a ColumnStrip drawn in a SubViewport and wrapped
## round the Column tube. The strip's height is the Bore's length at the same
## metres as the room, so the Column slides past at exactly the simulation's
## speed(), and its width is the Column's circumference.
func _column_material() -> StandardMaterial3D:
	var viewport := SubViewport.new()
	viewport.size = Vector2i(
			roundi(TAU * COLUMN_RADIUS * COLUMN_PIXELS_PER_METRE),
			roundi(LENGTH * COLUMN_PIXELS_PER_METRE))
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport.disable_3d = true
	var strip := ColumnStrip.new()
	strip.sim = _sim
	strip.pixels_per_metre = COLUMN_PIXELS_PER_METRE
	strip.cell_m = 0.1
	strip.grain_m = Vector2(0.07, 0.05)
	strip.behind_head_m = HABITAT_BEHIND_HEAD_M
	strip.show_readout = false
	strip.size = Vector2(viewport.size)
	viewport.add_child(strip)
	add_child(viewport)
	var material := _surface(Color.WHITE)
	material.albedo_texture = viewport.get_texture()
	# The Bore lights its own Column, so its colours read true from anywhere
	# in the room (the room's lamp sits on the axis, inside the Column).
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	return material


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
