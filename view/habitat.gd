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
## where the Fabricator will go. Each: name, hue, the simulation's name for
## it, and its call: tone in hertz and pips per beat, so no two sound alike.
const STATIONS := [
	["Reactor", Color("ff7a45"), DiveSimulation.STATION_REACTOR, 220.0, 1],
	["Drive", Color("ffd24a"), DiveSimulation.STATION_DRIVE, 294.0, 2],
	["Thermal", Color("ff4a6a"), DiveSimulation.STATION_THERMAL, 370.0, 3],
	["Navigation", Color("4ad2ff"), DiveSimulation.STATION_NAVIGATION, 494.0, 1],
	["Bore Station", Color("b9ff6a"), DiveSimulation.STATION_BORE, 587.0, 2],
	["", Color.GRAY, &"", 0.0, 0],
]
## Each press of the faster key multiplies the time rate by this.
const TIME_RATE_STEP := 4.0
## How much one press moves the Course at Navigation, or the Drive's
## override, and the Drive's power and steering effort.
const PITCH_STEP := 15.0
const HEADING_STEP := 15.0
const POWER_STEP := 0.1
const EFFORT_STEP := 0.1
## The Arm's rail runs round the Bore this far out from its glass.
const RAIL_GAP := 0.15
## How quickly the look settles onto a Station's screen while carried, per second.
const LOOK_SETTLE_RATE := 4.0
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
## How much one press turns the Reactor's Shift dial, as a share of its
## frequency.
const SHIFT_DIAL_STEP := 0.02
## How far a lurch shakes the crew's view, metres per m/s^2 of jolt.
const LURCH_SHAKE_M := 0.004
## How far slipping grip waves shake the crew's view at full slip, metres.
const SLIP_SHAKE_M := 0.006
## How long the word of a recovery stays on screen, in seconds.
const RECOVERED_NOTICE_S := 8.0
## Upload priorities in the order the Bore Station's U key cycles them.
const UPLOAD_PRIORITIES: Array[StringName] = [
	DiveSimulation.UPLOAD_OLDEST_FIRST,
	DiveSimulation.UPLOAD_MOST_VALUABLE_FIRST,
	DiveSimulation.UPLOAD_NEWEST_FIRST,
]
## The Bore Station's display: the survey and the tunnel side by side, in the
## proportions of a Station screen.
const BORE_DISPLAY_SIZE := Vector2i(768, 363)

var _sim := DiveSimulation.new(MediumLayout.first_dive())
## Drive Station settings: they hold when the crew walks away. The Course
## (Navigation's) and any override are read from the simulation.
var _power_setting := 0.0
var _effort_setting := 1.0
var _stations: Array[GimballedStation] = []
var _reactor: GimballedStation
var _drive: GimballedStation
var _bore_station: GimballedStation
## A ring on the Bore glass that rides along with the feature being observed.
var _feature_ring: MeshInstance3D
var _thermal: GimballedStation
## Thermal Station setting: share of heat sent into the Column.
var _heat_split := 0.0
var _navigation: GimballedStation
var _crew := CrewMember.new()
var _arm := Arm.new(BORE_RADIUS + RAIL_GAP)
## The Stations in use, in order round the ring; the Arm carries to these.
var _in_use: Array[GimballedStation] = []
## The simulation's name for each Station in use (GimballedStation -> StringName).
var _sim_names := {}
## The Reactor's waveform display, which holds the Shift dial.
var _plasma_display: PlasmaDisplay
## True from a Boundary announced ahead until it is crossed.
var _boundary_ahead := false
## The notice of a stranding and what it cost, then of the recovery.
var _notice: Label
## Seconds left showing the recovery notice; 0 while not showing it.
var _recovered_notice_left := 0.0

@onready var _dive_view: DiveView = %DiveView
@onready var _controls: Label = $Overlay/Controls


func _ready() -> void:
	_sim.set_course(0.0, 90.0)
	_sim.set_steering_effort(_effort_setting)
	_sim.set_power(_power_setting)
	_sim.set_heat_split(_heat_split)
	_dive_view.attach(_sim)
	# Nothing is drawn over the crew's view (story 52): the overlay is a
	# developer's debug view [F3], the controls a menu [F1].
	_dive_view.visible = false
	_controls.visible = false
	var slip_sound := SlipSound.new()
	slip_sound.sim = _sim
	add_child(slip_sound)
	_build_room()
	_build_stations()
	_build_notice()
	_show_notice([
		"At the surface of the desert, ready to dive",
		"Power up at the Drive [T]. Down through sand, sandstone and granite;",
		"a few kilometres down, plot a climbing Course at Navigation [3]",
		"to arc home and sell the survey.",
		"[F1] controls",
	], RECOVERED_NOTICE_S)
	_crew.bore_radius = BORE_RADIUS
	_crew.outer_radius = OUTER_RADIUS
	_crew.length = LENGTH
	# Start standing on the Head end cap, which is the floor when diving.
	_crew.position = Vector3(0, -(OUTER_RADIUS + BORE_RADIUS) / 2.0, -LENGTH / 2.0 + CrewMember.BODY)
	_crew.basis = Basis.looking_at(Vector3.RIGHT, Vector3.BACK)
	add_child(_crew)
	var arm_view := ArmView.new()
	arm_view.arm = _arm
	arm_view.rail_radius = BORE_RADIUS + RAIL_GAP
	add_child(arm_view)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	elif event.is_action_pressed(&"ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	elif event is InputEventKey and event.pressed and not event.echo:
		match (event as InputEventKey).physical_keycode:
			KEY_1: _aim(0.0, 90.0, false)
			KEY_2: _aim(0.0, 0.0, false)
			KEY_3: _aim(0.0, -90.0, false)
			KEY_Z: _aim(0.0, -PITCH_STEP, true)
			KEY_X: _aim(0.0, PITCH_STEP, true)
			KEY_J: _aim(-HEADING_STEP, 0.0, true)
			KEY_L: _aim(HEADING_STEP, 0.0, true)
			KEY_O: _end_override()
			KEY_Y: _set_effort(_effort_setting + EFFORT_STEP)
			KEY_H: _set_effort(_effort_setting - EFFORT_STEP)
			KEY_T: _set_power(_power_setting + POWER_STEP)
			KEY_G: _set_power(_power_setting - POWER_STEP)
			KEY_F: _observe_next_feature()
			KEY_U: _cycle_upload_priority()
			KEY_F1: _controls.visible = not _controls.visible
			KEY_F3: _dive_view.visible = not _dive_view.visible
			KEY_C: _split_heat(_heat_split - HEAT_SPLIT_STEP)
			KEY_V: _split_heat(_heat_split + HEAT_SPLIT_STEP)
			KEY_P: _pulse()
			KEY_Q: _toggle_quiet_ship()
			KEY_SPACE: _arm.press()
			KEY_A:
				_arm.shift(-1)
			KEY_D:
				_arm.shift(1)
			KEY_N: _turn_shift_dial(-1)
			KEY_M: _turn_shift_dial(1)
			KEY_R: _shift()
			KEY_ENTER, KEY_KP_ENTER:
				_sim.recover()
				_sim.new_dive()
			KEY_PERIOD: _sim.set_time_rate(_sim.time_rate() * TIME_RATE_STEP)
			KEY_COMMA: _sim.set_time_rate(1.0)


func _physics_process(delta: float) -> void:
	# The simulation knows which Stations a crew member is at; the rest hold
	# their settings and steady themselves.
	for station in _in_use:
		_sim.set_attended(_sim_names[station], _at(station))
	_sim.advance(delta)
	for event in _sim.take_events():
		match event.type:
			&"boundary_approaching": _boundary_ahead = true
			&"boundary_crossed": _boundary_ahead = false
			&"stranded": _on_stranded(event)
			&"recovered_through_tunnel": _on_recovered_through_tunnel(event)
			&"recovered": _on_recovered(event)
			&"paid": _on_paid(event)
			&"new_dive": _on_new_dive(event)
	_fade_recovered_notice(delta)
	_show_calls()
	var felt := _sim.felt_acceleration()
	var up := -felt.normalized()
	for station in _stations:
		station.follow_up(up, delta)
	_arm.step(delta, _crew.eye(), _station_poses())
	if _arm.is_holding():
		var settle := 0.0 if _arm.arrived() else 1.0 - exp(-delta * LOOK_SETTLE_RATE)
		_crew.hold(_arm.held_eye(), GimballedStation.pose_look(), settle)
	else:
		_crew.step(felt, delta)
	# A poor Shift's lurch, and the grip waves slipping on the wall, are felt.
	_crew.shake(_sim.lurch() * LURCH_SHAKE_M + _sim.slip() * SLIP_SHAKE_M)
	_drive.set_supplied(_sim.drive_supplied())
	_thermal.set_supplied(_sim.thermal_supplied())
	_navigation.set_supplied(_sim.navigation_supplied())
	_show_reactor()
	_show_drive()
	_bore_station.show_reading(_bore_reading())
	_place_feature_ring()
	_show_thermal()
	_show_navigation()


func _station_poses() -> Array[Transform3D]:
	var poses: Array[Transform3D] = []
	for station in _in_use:
		poses.append(station.pose())
	return poses


## Whether the crew member can work this Station: seated at it by the Arm, or
## standing within reach of it.
func _at(station: GimballedStation) -> bool:
	if _arm.is_holding() and _arm.arrived() and _arm.station() >= 0 \
			and _in_use[_arm.station()] == station:
		return true
	return _crew.position.distance_to(station.position) <= STATION_REACH


## The heading and pitch keys. At Navigation they plot the Course; at the
## Drive they override it, starting from what the Drive steers toward now.
## `relative`: move by the amounts given; else set the pitch to `pitch`
## (and keep the heading).
func _aim(heading: float, pitch: float, relative: bool) -> void:
	if _at(_navigation):
		var p := _sim.course_pitch() + pitch if relative else pitch
		_sim.set_course(_sim.course_heading() + heading, p)
	elif _at(_drive):
		var p := _sim.steered_pitch() + pitch if relative else pitch
		_sim.override_course(_sim.steered_heading() + heading, p)


## Drive Station: give up the override and steer toward the Course again.
func _end_override() -> void:
	if _at(_drive):
		_sim.end_override()


## Drive Station: how hard to steer toward the Course.
func _set_effort(effort: float) -> void:
	if not _at(_drive):
		return
	_effort_setting = clampf(snappedf(effort, EFFORT_STEP), 0.0, 1.0)
	_sim.set_steering_effort(_effort_setting)


## Navigation: send a pulse. Only at Navigation.
func _pulse() -> void:
	if _at(_navigation):
		_sim.pulse()


## Navigation: Quiet Ship on or off. Only at Navigation.
func _toggle_quiet_ship() -> void:
	if _at(_navigation):
		_sim.set_quiet_ship(not _sim.quiet_ship())


## Drive Station: share of power sent to advancing.
func _set_power(power: float) -> void:
	if not _at(_drive):
		return
	_power_setting = clampf(snappedf(power, POWER_STEP), 0.0, 1.0)
	_sim.set_power(_power_setting)


## Each Station calls with its own tone and light as urgently as the
## simulation says, and every screen shows the time rate. Unattended Thermal
## may have moved the heat split, and an unattended Drive its power, so the
## Habitat's copies follow them.
func _show_calls() -> void:
	_heat_split = _sim.heat_split()
	_power_setting = _sim.power()
	var rate := _sim.time_rate()
	var footer := "Time x%d  [.] faster [,] normal" % roundi(rate) if rate > 1.0 \
			else "Time x1  [.] faster"
	for station in _in_use:
		station.set_call(_sim.call_urgency(_sim_names[station]))
		station.footer = footer


## The Drive Station's screen: depth and speed; heading and pitch now beside
## the Course Navigation plotted (and the Drive's override, if it holds one);
## power, the steering effort and how hard the Head is steering (turning heats
## one side of it harder); and whether the grip waves hold the wall or slip.
func _show_drive() -> void:
	var slip := _sim.slip()
	var lines := [
		"SURFACED  [Enter] dive again" if _sim.surfaced() else
			"Depth %.1f m  Speed %.2f m/s" % [_sim.depth(), _sim.speed()],
		"Heading %03.0f  Course %03.0f" % [_sim.heading_degrees(), _sim.course_heading()],
		"Pitch %+.0f  Course %+.0f deg" % [_sim.pitch(), _sim.course_pitch()],
		"OVERRIDE %03.0f %+.0f  [O] back to Course" % [
			_sim.steered_heading(), _sim.steered_pitch()] if _sim.overriding()
			else "Following the Course",
		"Set %d%%  Effort %d%%  Steer %d%%" % [roundi(_power_setting * 100.0),
			roundi(_effort_setting * 100.0), roundi(_sim.steering() * 100.0)],
		"GRIP SLIPPING %d%%  ease off [G]" % roundi(slip * 100.0) if slip > 0.0
			else "Grip holding",
		_power_line(_sim.drive_request(), _sim.drive_draw()),
	]
	_drive.show_reading("\n".join(lines))


## Navigation's screen, over its point cloud (which shows the Course): the
## Course plotted, how quiet the vessel is, the points heard and its power.
func _show_navigation() -> void:
	_navigation.show_reading("\n".join([
		"Course %03.0f  %+.0f deg%s" % [_sim.course_heading(), _sim.course_pitch(),
			"  (Drive overriding)" if _sim.overriding() else ""],
		"%s  noise %d%%  %d points" % ["QUIET SHIP" if _sim.quiet_ship() else "under way",
			roundi(_sim.noise() * 100.0), _sim.point_count()],
		_power_line(_sim.navigation_request(), _sim.navigation_draw()),
		"[P] pulse  [Q] Quiet Ship",
	]))


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
	var shift_line := "Head wear %d%%" % roundi(_sim.head_wear() * 100.0)
	if _sim.plasma_lost():
		shift_line += "  PLASMA LOST"
	elif _sim.shift_due():
		shift_line += "  SHIFT DUE  [N/M] dial [R] Shift"
	elif _boundary_ahead:
		shift_line += "  BOUNDARY AHEAD"
	lines.append(shift_line)
	_reactor.show_reading("\n".join(lines))


## The plasma is lost and the tunnel sealed: the dive is over. Tell the crew
## where, what it cost, and how to call the recovery.
func _on_stranded(event: Dictionary) -> void:
	_recovered_notice_left = 0.0
	_notice.text = "
".join([
		"STRANDED  at %.0f m" % event.depth,
		"The plasma is lost and the tunnel behind is sealed.",
		"Unsold survey lost: %d stretches, worth %.0f" % [event.lost_stretches, event.lost],
		"Paid, and kept: %.0f" % event.paid,
		"",
		"[Enter] call the recovery",
	])
	_notice.visible = true


## The plasma is lost but the tunnel behind is open: the crew are brought
## back up it. Tell them from where, what the survey aboard sold for and what
## the Head's repair cost, and how to start another dive.
func _on_recovered_through_tunnel(event: Dictionary) -> void:
	_show_notice([
		"PLASMA LOST  at %.0f m" % event.depth,
		"The tunnel behind is open: brought home through it.",
		"Survey aboard sold: %.0f" % event.carried_home,
		"Head repair paid: %.0f" % event.head_repair,
		"This dive: %.0f   Paid in all: %.0f" % [event.amount, event.total_paid],
		"",
		"[Enter] start another dive",
	], 0.0)


## Back at the surface on a fresh dive: the Stations start from their start
## settings, so the Habitat's settings do too.
func _on_recovered(event: Dictionary) -> void:
	_reset_settings()
	_show_notice([
		"RECOVERED to the surface",
		"Paid, and kept: %.0f" % event.paid,
		"Ready to dive again: power up at the Drive [T].",
	], RECOVERED_NOTICE_S)


## Surfaced and sold: what this dive was paid and why, until the crew starts
## another dive.
func _on_paid(event: Dictionary) -> void:
	var lines := [
		"SURFACED  The survey is sold",
		"Paid for this dive: %.0f" % event.amount,
		"  up the link under way %.0f, carried home %.0f" % [event.by_link, event.carried_home],
		"Column recorded %.0f m in %d stretches, quality %d%%" % [
			event.metres, event.stretches, roundi(event.mean_quality * 100.0)],
	]
	if event.lost_to_quality >= 0.5:
		lines.append("  heat and shuttering cost %.0f of pristine records" % event.lost_to_quality)
	if event.features > 0:
		lines.append("Features recorded: %d, worth %.0f" % [event.features, event.feature_worth])
	var by_medium: Dictionary = event.by_medium
	var media := PackedStringArray()
	for medium in by_medium:
		media.append("%s %.0f" % [String(medium).capitalize(), by_medium[medium]])
	lines.append("By rock: " + "  ".join(media))
	lines.append("Paid in all: %.0f" % event.total_paid)
	lines.append("")
	lines.append("[Enter] start another dive")
	_show_notice(lines, 0.0)


## A fresh dive after surfacing: back to the start settings, ready to dive.
func _on_new_dive(event: Dictionary) -> void:
	_reset_settings()
	_show_notice([
		"At the surface, ready to dive",
		"Paid so far: %.0f" % event.paid,
		"Power up at the Drive [T].",
	], RECOVERED_NOTICE_S)


## Shows the centre notice; for `seconds` if above 0, else until replaced.
func _show_notice(lines: Array, seconds: float) -> void:
	_notice.text = "\n".join(lines)
	_notice.visible = true
	_recovered_notice_left = seconds


## The Stations start a dive from their start settings, so the Habitat's do too.
func _reset_settings() -> void:
	_power_setting = 0.0
	_effort_setting = 1.0
	_heat_split = 0.0
	_sim.set_course(0.0, 90.0)
	_sim.set_steering_effort(_effort_setting)
	_sim.set_power(_power_setting)
	_sim.set_heat_split(_heat_split)
	_plasma_display.dial = _sim.plasma_tuning()
	_boundary_ahead = false


func _fade_recovered_notice(delta: float) -> void:
	if _recovered_notice_left <= 0.0:
		return
	_recovered_notice_left -= delta
	if _recovered_notice_left <= 0.0:
		_notice.visible = false


## A plain notice in the middle of the screen, hidden until needed.
func _build_notice() -> void:
	_notice = Label.new()
	_notice.set_anchors_preset(Control.PRESET_CENTER)
	_notice.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_notice.grow_vertical = Control.GROW_DIRECTION_BOTH
	_notice.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_notice.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_notice.add_theme_font_size_override(&"font_size", 26)
	_notice.add_theme_color_override(&"font_color", Color("ffd0b0"))
	var backing := StyleBoxFlat.new()
	backing.bg_color = Color(0.08, 0.02, 0.0, 0.85)
	backing.border_color = STATIONS[0][1]
	backing.set_border_width_all(2)
	backing.set_content_margin_all(24)
	_notice.add_theme_stylebox_override(&"normal", backing)
	_notice.visible = false
	$Overlay.add_child(_notice)


## Stand-in Reactor control until the Station has its own: turn the Shift dial
## one step down or up. Worked at the Reactor Station: only when at it.
func _turn_shift_dial(direction: int) -> void:
	if not _at(_reactor):
		return
	_plasma_display.dial *= 1.0 + SHIFT_DIAL_STEP * direction


## Shift to the frequency on the dial. Only when at the Reactor.
func _shift() -> void:
	if not _at(_reactor):
		return
	_sim.shift(_plasma_display.dial)


## A bar of tenths: '#' power drawn, '-' asked for but not given, '.' unused.
static func _bar(requested: float, drawn: float) -> String:
	var got := roundi(drawn * 10.0)
	var asked := maxi(got, roundi(requested * 10.0))
	return "[%s%s%s]" % ["#".repeat(got), "-".repeat(asked - got), ".".repeat(maxi(0, 10 - asked))]


## Stand-in Bore Station control until it has its own: observe the next
## feature in the Column not yet recorded, nearest the Tail first, cycling.
## Worked at the Bore Station: only within reach of it.
func _observe_next_feature() -> void:
	if not _at(_bore_station):
		return
	var candidates := _sim.features_in_column().filter(
			func(f: ColumnFeature) -> bool: return not f.is_recorded())
	if candidates.is_empty():
		_sim.set_observed_feature(-1)
		return
	var ids := candidates.map(func(f: ColumnFeature) -> int: return f.id)
	var current := ids.find(_sim.observed_feature())
	_sim.set_observed_feature(ids[(current + 1) % ids.size()])


## Bore Station: which waiting survey data goes up the link first, cycling
## through UPLOAD_PRIORITIES. Only when at the Bore Station.
func _cycle_upload_priority() -> void:
	if not _at(_bore_station):
		return
	var next := (UPLOAD_PRIORITIES.find(_sim.upload_priority()) + 1) % UPLOAD_PRIORITIES.size()
	_sim.set_upload_priority(UPLOAD_PRIORITIES[next])


## The Bore Station's display: the survey as it is recorded (quality per
## stretch, story 14) beside the tunnel and the porosity trend the Tail is
## heading into (story 26), with the link and the upload priority.
func _bore_display() -> Texture2D:
	var viewport := SubViewport.new()
	viewport.size = BORE_DISPLAY_SIZE
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport.disable_3d = true
	var half := Vector2(BORE_DISPLAY_SIZE.x / 2.0, BORE_DISPLAY_SIZE.y)
	var survey := SurveyPanel.new()
	survey.sim = _sim
	survey.size = half
	viewport.add_child(survey)
	var tunnel := TunnelPanel.new()
	tunnel.sim = _sim
	tunnel.position = Vector2(half.x, 0.0)
	tunnel.size = half
	viewport.add_child(tunnel)
	add_child(viewport)
	return viewport.get_texture()


func _bore_reading() -> String:
	var in_column := _sim.features_in_column()
	var lines := PackedStringArray()
	lines.append("Survey value %d" % roundi(_sim.survey_value()))
	if _sim.call_reason(DiveSimulation.STATION_BORE) == &"tunnel_about_to_seal":
		lines.append("TUNNEL SEALS when the Tail leaves this rock")
	var observed := _sim.observed_feature()
	var found_observed := false
	for feature in in_column:
		var where := _sim.distance() - feature.at
		var state := "RECORDED" if feature.is_recorded() else "%d%%" % roundi(100.0 * feature.recorded)
		var marker := ">" if feature.id == observed else " "
		if feature.id == observed:
			found_observed = true
		lines.append("%s %s %.1f m  %s" % [marker, String(feature.kind).capitalize(), where, state])
	if in_column.is_empty():
		lines.append("No features in the Column")
	elif not found_observed:
		lines.append("[F] observe a feature")
	return "\n".join(lines)


## Keeps the ring on the observed feature while it is in the Habitat's
## stretch of the Bore.
func _place_feature_ring() -> void:
	_feature_ring.visible = false
	var observed := _sim.observed_feature()
	if observed < 0:
		return
	for feature in _sim.features_in_column():
		if feature.id != observed:
			continue
		var into_habitat := _sim.distance() - feature.at - HABITAT_BEHIND_HEAD_M
		if into_habitat < 0.0 or into_habitat > LENGTH:
			return
		_feature_ring.position.z = -LENGTH / 2.0 + into_habitat
		(_feature_ring.material_override as StandardMaterial3D).albedo_color = (
				FeatureLook.RECORDED_COLOUR if feature.is_recorded() else FeatureLook.OBSERVING_COLOUR)
		_feature_ring.visible = true


## The heat split is worked at the Thermal Station: only within reach of it.
func _split_heat(to_column: float) -> void:
	if not _at(_thermal):
		return
	_heat_split = clampf(snappedf(to_column, HEAT_SPLIT_STEP), 0.0, 1.0)
	_sim.set_heat_split(_heat_split)


## The Thermal Station's screen: the split, where the heat is going, the hull
## against the Medium and the temperature it can bear, and wear. It calls with
## its light while the simulation warns of heat damage.
func _show_thermal() -> void:
	var warning := _sim.heat_warning()
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
	var ring := TorusMesh.new()
	ring.inner_radius = BORE_RADIUS + 0.005
	ring.outer_radius = BORE_RADIUS + 0.035
	var ring_material := _surface(FeatureLook.OBSERVING_COLOUR)
	ring_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_add_along_axis(ring, ring_material, 0.0)
	_feature_ring = get_child(get_child_count() - 1)
	_feature_ring.visible = false

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
		station.call_tone_hz = STATIONS[i][3]
		station.call_pips = STATIONS[i][4]
		if station.station_name in ["Thermal", "Reactor", "Drive"]:
			station.screen_font_size = 28
		station.position = outward * pivot_radius
		add_child(station)
		_stations.append(station)
		if not station.station_name.is_empty():
			_in_use.append(station)
			_sim_names[station] = STATIONS[i][2]
		if station.station_name == "Reactor":
			_reactor = station
			_reactor.show_display(_make_plasma_display())
		elif station.station_name == "Drive":
			_drive = station
		elif station.station_name == "Bore Station":
			_bore_station = station
			_bore_station.show_display(_bore_display())
		elif station.station_name == "Thermal":
			_thermal = station
		elif station.station_name == "Navigation":
			_navigation = station
			_navigation.show_display(_scan_display())


## The Reactor's waveform display for the Shift, its dial starting where the
## Reactor is tuned.
func _make_plasma_display() -> Texture2D:
	_plasma_display = PlasmaDisplay.new()
	_plasma_display.size = Vector2i(512, 242)
	_plasma_display.sim = _sim
	_plasma_display.hue = STATIONS[0][1]
	_plasma_display.dial = _sim.plasma_tuning()
	add_child(_plasma_display)
	return _plasma_display.get_texture()


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
