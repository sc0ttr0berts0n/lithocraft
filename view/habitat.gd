## The Habitat: an annular room around the Bore, seen only from inside.
## Owns the dive's simulation, advances it, and lets "down" follow the
## felt acceleration it reports. This node's axes are the simulation's
## Habitat frame (DiveSimulation.TOWARD_HEAD is -Z, the Head end cap).
## Dimensions are the prototype's starting values, not commitments.
extends Node3D

const BORE_RADIUS := 0.8
const OUTER_RADIUS := 3.3
const LENGTH := 2.4
## Stations pivot this far in from the outer wall: close to it, so the crew
## stand between the Bore and the screen.
const STATION_HANG := 0.75
## Six Station positions in order round the ring (see place_angle()); this
## dive uses five. "" is the empty mount where the Fabricator will go. The
## Drive sits beside Navigation, since steering and the Course go together.
## Each: name, hue, the simulation's name for it, and its call: tone in hertz
## and pips per beat, so no two sound alike.
const STATIONS := [
	["Reactor", Color("ff7a45"), DiveSimulation.STATION_REACTOR, 220.0, 1],
	["Drive", Color("ffd24a"), DiveSimulation.STATION_DRIVE, 294.0, 2],
	["Navigation", Color("4ad2ff"), DiveSimulation.STATION_NAVIGATION, 494.0, 1],
	["Thermal", Color("ff4a6a"), DiveSimulation.STATION_THERMAL, 370.0, 3],
	["Bore Station", Color("b9ff6a"), DiveSimulation.STATION_BORE, 587.0, 2],
	["", Color.GRAY, &"", 0.0, 0],
]
## Each press of the faster key multiplies the time rate by this.
const TIME_RATE_STEP := 4.0
## How much one press moves the Course at Navigation, or the Drive's
## override, and the Drive's power and steering effort.
const PITCH_STEP := 15.0
const HEADING_STEP := 15.0
## The Course's pitch for dive, level and climb (the keys 1, 2, 3).
const PITCHES: Array[float] = [90.0, 0.0, -90.0]
const POWER_STEP := 0.1
const EFFORT_STEP := 0.1
## The Arm's rail runs round the Bore this far out from its glass.
const RAIL_GAP := 0.15
## How quickly the look settles onto a Station's screen while carried, per second.
const LOOK_SETTLE_RATE := 4.0
## The centre dot's size in pixels, and how bright it is off a reading and on one.
const DOT_PX := 6.0
const DOT_OFF_READING := Color(1, 1, 1, 0.45)
const DOT_ON_READING := Color(1, 1, 1, 0.95)
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
## How much one press tunes the Shift dial's STANDBY channel, as a share of
## its frequency.
const STANDBY_STEP := 0.02
## How far a lurch shakes the crew's view, metres per m/s^2 of jolt.
const LURCH_SHAKE_M := 0.004
## How far slipping grip waves shake the crew's view at full slip, metres.
const SLIP_SHAKE_M := 0.006
## How long a passing notice stays on screen, in seconds.
const NOTICE_S := 8.0
## Hull creep as the Thermal screen shows it, percent of the hull a minute,
## per unit of hull_creep_rate() (a share of the hull a second).
const PERCENT_PER_MIN := 100.0 * 60.0
## Upload priorities in the order the Bore Station's U key cycles them.
const UPLOAD_PRIORITIES: Array[StringName] = [
	DiveSimulation.UPLOAD_OLDEST_FIRST,
	DiveSimulation.UPLOAD_MOST_VALUABLE_FIRST,
	DiveSimulation.UPLOAD_NEWEST_FIRST,
]
## The Bore Station's display: the survey and the tunnel side by side, in the
## proportions of a Station screen.
const BORE_DISPLAY_SIZE := Vector2i(768, 363)
## Pixels per metre of a Station screen's display: Navigation's two
## displays, the point cloud and the moving map, are sized from their share
## of the screen (GimballedStation.display_rect()).
const DISPLAY_PX_PER_M := 1010.0
## The debug menu's steps: wear per press (hull or Head), and time skipped.
const DEBUG_WEAR_STEP := 0.1
const DEBUG_SKIP_S := 300.0

## The start menu, which a dive's end returns to.
const START_MENU := "res://view/start_menu.tscn"

## The Scenario to play, set by the start menu before the Habitat enters the
## tree; the First dive when the Habitat is run on its own.
var scenario: Scenario = null
var _sim: DiveSimulation
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
## True while the crew holds K at Thermal to arm self-destruct.
var _holding_self_destruct := false
var _navigation: GimballedStation
var _crew := CrewMember.new()
var _arm := Arm.new(BORE_RADIUS + RAIL_GAP)
## The Stations in use, in order round the ring; the Arm carries to these.
var _in_use: Array[GimballedStation] = []
## True from a Boundary announced ahead until it is crossed.
var _boundary_ahead := false
## The simulation's name for each Station in use (GimballedStation -> StringName).
var _sim_names := {}
## The centre notice: where the dive stands (a stranding, a death, the
## breakdown of what a dive was paid) or a passing word.
var _notice: Label
## Seconds left showing a passing notice; 0 while the notice stays until
## replaced, or none shows.
var _notice_left := 0.0
## Sparks, shake and groans while heat wears the hull.
var _hull_feel := HullFeel.new()
## The end of a dive: the lurch that settles to still, then the outcome
## sentence over the breakdown, held in _outcome_lines until the view is still.
var _outcome_screen := OutcomeScreen.new()
var _outcome_lines: Array = []
## The crew's shake last frame, metres: what the end-of-dive lurch starts from.
var _shake_m := 0.0
## The centre dot: marks what the crew is looking at while the mouse looks.
var _dot: Panel

@onready var _dive_view: DiveView = %DiveView
## The F1 controls, built from the key map.
var _controls := ControlsPanel.new()
## The numpad debug menu (numpad minus); its keys work only while it shows.
var _debug_menu := DebugPanel.new()
## The checklist (Tab): the Orders, the next step, surface control's messages.
var _checklist := ChecklistPanel.new()


func _ready() -> void:
	if scenario == null:
		scenario = Scenario.first_dive()
	_sim = scenario.start()
	# The Scenario set the Stations up (a drill may start under way): the
	# Habitat's copies of their settings follow the simulation's.
	_power_setting = _sim.power()
	_effort_setting = _sim.steering_effort()
	_heat_split = _sim.heat_split()
	_dive_view.attach(_sim)
	# Nothing is drawn over the crew's view (story 52): the overlay is a
	# developer's debug view, the controls a menu.
	_dive_view.visible = false
	_build_controls()
	_build_checklist()
	var slip_sound := SlipSound.new()
	slip_sound.sim = _sim
	add_child(slip_sound)
	_hull_feel.sim = _sim
	_hull_feel.ring_radius = OUTER_RADIUS
	_hull_feel.length = LENGTH
	add_child(_hull_feel)
	_build_room()
	_build_stations()
	# Under the notice, so a notice reads clear of it.
	_build_dot()
	_build_notice()
	# Over the notice: the developer opened it to use it.
	_build_debug_menu()
	_show_notice([
		"%s: %s" % [scenario.title, scenario.summary],
		"%s the checklist: your orders and what to do next   %s controls" % [
				KeyMap.label(&"toggle_checklist"), KeyMap.label(&"toggle_controls")],
	], NOTICE_S)
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


## Every key goes through the key map: a press runs `_key_<action>(index)` of
## the first binding that applies where the crew stands, so what each screen
## shows is what the key does.
func _unhandled_input(event: InputEvent) -> void:
	var code := KeyMap.code_of(event)
	var found := KeyMap.find(code, _wheres())
	if not found.is_empty():
		call("_key_%s" % found.action, found.index)
		_debug_menu.flash(code)


## Where the crew can work now: anywhere, each Station they are at, and the
## debug menu's keys while it shows.
func _wheres() -> Array:
	var wheres: Array = [KeyMap.ANYWHERE]
	for station in _in_use:
		if _at(station):
			wheres.append(_sim_names[station])
	if _debug_menu.visible:
		wheres.append(KeyMap.DEBUG)
	return wheres


## -1 for the first of a "-/+" pair of keys, +1 for the second.
static func _minus_plus(index: int) -> float:
	return -1.0 if index == 0 else 1.0


func _key_capture_mouse(_index: int) -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _key_release_mouse(_index: int) -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _key_arm(_index: int) -> void:
	_arm.press()


func _key_next_station(index: int) -> void:
	_arm.shift(roundi(_minus_plus(index)))


func _key_time_faster(_index: int) -> void:
	_sim.set_time_rate(_sim.time_rate() * TIME_RATE_STEP)


func _key_time_normal(_index: int) -> void:
	_sim.set_time_rate(1.0)


## Back to the start menu once the dive is over and its end has settled into
## its outcome.
func _key_new_dive(_index: int) -> void:
	if not (_sim.surfaced() or _sim.dead()) or _outcome_screen.settling():
		return
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_tree().change_scene_to_file(START_MENU)


func _key_toggle_controls(_index: int) -> void:
	_controls.visible = not _controls.visible
	if _controls.visible:
		_debug_menu.visible = false


## The checklist in the upper left; opening it is reading the orders.
func _key_toggle_checklist(_index: int) -> void:
	_checklist.visible = not _checklist.visible
	if _checklist.visible:
		_sim.read_orders()


func _key_toggle_debug(_index: int) -> void:
	_dive_view.visible = not _dive_view.visible


## The numpad debug menu; it and the F1 controls share the lower left, so
## opening one closes the other.
func _key_debug_menu(_index: int) -> void:
	_debug_menu.visible = not _debug_menu.visible
	if _debug_menu.visible:
		_controls.visible = false


# The debug menu's keys: each a simulation debug command (DiveSimulation's
# debug_*), not a crew control; or, for the overlay, a view toggle. What a
# command refuses, and why, goes to the menu's status line.

func _key_debug_overlay(index: int) -> void:
	_key_toggle_debug(index)


func _key_debug_surface(_index: int) -> void:
	_debug_menu.report(_sim.debug_surface())


func _key_debug_skip(_index: int) -> void:
	_debug_menu.report(_sim.debug_skip(DEBUG_SKIP_S))


func _key_debug_hull_wear_up(_index: int) -> void:
	_debug_menu.report(_sim.debug_wear_hull(DEBUG_WEAR_STEP))


func _key_debug_hull_wear_down(_index: int) -> void:
	_debug_menu.report(_sim.debug_wear_hull(-DEBUG_WEAR_STEP))


func _key_debug_hull_brink(_index: int) -> void:
	_debug_menu.report(_sim.debug_hull_to_brink())


func _key_debug_head_wear_up(_index: int) -> void:
	_debug_menu.report(_sim.debug_wear_head(DEBUG_WEAR_STEP))


func _key_debug_head_wear_down(_index: int) -> void:
	_debug_menu.report(_sim.debug_wear_head(-DEBUG_WEAR_STEP))


func _key_debug_shift_due(_index: int) -> void:
	_debug_menu.report(_sim.debug_shift_due())


func _key_debug_next_boundary(_index: int) -> void:
	_debug_menu.report(_sim.debug_next_boundary())


func _key_debug_strand(_index: int) -> void:
	_debug_menu.report(_sim.debug_strand())


func _key_debug_lose_plasma(_index: int) -> void:
	_debug_menu.report(_sim.debug_lose_plasma())


func _key_debug_refill_store(_index: int) -> void:
	_debug_menu.report(_sim.debug_refill_store())


func _key_debug_self_destruct(_index: int) -> void:
	_debug_menu.report(_sim.debug_self_destruct())


## Navigation: plot the Course's pitch, dive / level / climb.
func _key_plot_pitch(index: int) -> void:
	_sim.set_course(_sim.course_heading(), PITCHES[index])


func _key_plot_pitch_step(index: int) -> void:
	_sim.set_course(_sim.course_heading(), _sim.course_pitch() + _minus_plus(index) * PITCH_STEP)


func _key_plot_heading_step(index: int) -> void:
	_sim.set_course(_sim.course_heading() + _minus_plus(index) * HEADING_STEP, _sim.course_pitch())


func _key_pulse(_index: int) -> void:
	_sim.pulse()


func _key_quiet_ship(_index: int) -> void:
	_sim.set_quiet_ship(not _sim.quiet_ship())


## Drive: power up (T) / down (G).
func _key_power_step(index: int) -> void:
	_set_power(_power_setting - _minus_plus(index) * POWER_STEP)


## Drive: steering effort up (Y) / down (H).
func _key_effort_step(index: int) -> void:
	_set_effort(_effort_setting - _minus_plus(index) * EFFORT_STEP)


## Drive: the Course keys override the Course, starting from what the Drive
## steers toward now.
func _key_override_pitch(index: int) -> void:
	_sim.override_course(_sim.steered_heading(), PITCHES[index])


func _key_override_pitch_step(index: int) -> void:
	_sim.override_course(_sim.steered_heading(),
			_sim.steered_pitch() + _minus_plus(index) * PITCH_STEP)


func _key_override_heading_step(index: int) -> void:
	_sim.override_course(_sim.steered_heading() + _minus_plus(index) * HEADING_STEP,
			_sim.steered_pitch())


## Drive: give up the override and steer toward the Course again.
func _key_end_override(_index: int) -> void:
	_sim.end_override()


func _key_observe(_index: int) -> void:
	_observe_next_feature()


func _key_upload_priority(_index: int) -> void:
	_cycle_upload_priority()


## Bore Station: stop or start the link. While stranded it runs on the
## emergency store, so stopping it keeps the store for a relight.
func _key_link(_index: int) -> void:
	_sim.set_uploading(not _sim.uploading())


## Thermal: heat outward (C) / into the Column (V).
func _key_heat_split(index: int) -> void:
	_split_heat(_heat_split + _minus_plus(index) * HEAT_SPLIT_STEP)


## Reactor: tune the Shift dial's STANDBY channel one step down / up.
func _key_tune_standby(index: int) -> void:
	_sim.set_standby_tuning(_sim.standby_tuning() * (1.0 + STANDBY_STEP * _minus_plus(index)))


## Reactor: the Shift, swapping STANDBY and ACTIVE.
func _key_shift(_index: int) -> void:
	_sim.shift()


## Reactor: try to relight the Head from the emergency store; the simulation
## ignores it unless stranded.
func _key_relight(_index: int) -> void:
	_sim.relight()


## E at each Station: its autopilot's switch, on / off.
func _key_autopilot_reactor(_index: int) -> void:
	_switch_autopilot(DiveSimulation.STATION_REACTOR)


func _key_autopilot_drive(_index: int) -> void:
	_switch_autopilot(DiveSimulation.STATION_DRIVE)


func _key_autopilot_thermal(_index: int) -> void:
	_switch_autopilot(DiveSimulation.STATION_THERMAL)


func _key_autopilot_navigation(_index: int) -> void:
	_switch_autopilot(DiveSimulation.STATION_NAVIGATION)


func _key_autopilot_bore(_index: int) -> void:
	_switch_autopilot(DiveSimulation.STATION_BORE)


func _switch_autopilot(station: StringName) -> void:
	_sim.set_autopilot(station, not _sim.autopilot(station))


## A Station's autopilot let go: its disconnect warning and flashing caption.
func _on_autopilot_off(event: Dictionary) -> void:
	for station in _in_use:
		if _sim_names[station] == event.station:
			station.autopilot_off()


## Thermal: pressed, starts holding to arm self-destruct (released, the hold
## stops: see _physics_process); pressed while it runs, cancels it.
func _key_self_destruct(_index: int) -> void:
	if _sim.self_destructing():
		_sim.cancel_self_destruct()
	else:
		_holding_self_destruct = true


func _physics_process(delta: float) -> void:
	# The simulation knows which Stations a crew member is at (for commands
	# that need the crew there); each autopilot's switch alone decides
	# whether its Station steadies itself.
	for station in _in_use:
		_sim.set_attended(_sim_names[station], _at(station))
	_holding_self_destruct = _holding_self_destruct and KeyMap.held(&"self_destruct")[0]
	_sim.hold_self_destruct(_holding_self_destruct and _at(_thermal))
	_sim.advance(delta)
	for event in _sim.take_events():
		match event.type:
			&"boundary_approaching": _boundary_ahead = true
			&"boundary_crossed": _boundary_ahead = false
			&"stranded": _on_stranded(event)
			&"hull_failed": _on_hull_failed(event)
			&"relight_result": _on_relight_result(event)
			&"paid": _on_paid(event)
			&"self_destruct_started": _on_self_destruct_started(event)
			&"self_destruct_cancelled": _on_self_destruct_cancelled(event)
			&"autopilot_off": _on_autopilot_off(event)
	_fade_notice(delta)
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
	# A poor Shift's lurch, the grip waves slipping on the wall, and heat
	# wearing the hull are felt. Once the dive is over only its end lurch is,
	# settling to still before the outcome shows.
	_hull_feel.step(delta, felt)
	if _sim.surfaced() or _sim.dead():
		_shake_m = _outcome_screen.step(delta)
		if _outcome_screen.still() and not _outcome_lines.is_empty():
			_show_notice(_outcome_lines, 0.0)
			_outcome_lines = []
	else:
		_shake_m = _sim.lurch() * LURCH_SHAKE_M + _sim.slip() * SLIP_SHAKE_M \
				+ _hull_feel.shake_metres()
	_crew.shake(_shake_m)
	_drive.set_supplied(_sim.drive_supplied())
	_thermal.set_supplied(_sim.thermal_supplied())
	_navigation.set_supplied(_sim.navigation_supplied())
	_show_reactor()
	_show_drive()
	_bore_station.show_reading(_bore_reading())
	_place_feature_ring()
	_show_thermal()
	_show_navigation()


func _process(_delta: float) -> void:
	_dot.visible = Input.mouse_mode == Input.MOUSE_MODE_CAPTURED
	if _dot.visible:
		_dot.self_modulate = DOT_ON_READING if under_dot().get("reading", -1) >= 0 else DOT_OFF_READING


## What lies under the centre dot: {} for no Station screen, else
## {station = the GimballedStation, reading = the index of the reading on
## it in its face().readings (GimballedStation.reading() says what it
## shows), or -1 for the screen between readings}. The Column in the Bore
## hides the screens across the ring.
func under_dot() -> Dictionary:
	var faces: Array[Pointing.Face] = []
	for station in _in_use:
		faces.append(station.face())
	var view := _crew.view()
	var under := Pointing.under(view.origin, -view.basis.z, faces, COLUMN_RADIUS)
	if under.is_empty():
		return {}
	return {station = _in_use[under.face], reading = under.reading}


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


## Drive Station: how hard to steer toward the Course.
func _set_effort(effort: float) -> void:
	_effort_setting = clampf(snappedf(effort, EFFORT_STEP), 0.0, 1.0)
	_sim.set_steering_effort(_effort_setting)


## Drive Station: share of power sent to advancing.
func _set_power(power: float) -> void:
	_power_setting = clampf(snappedf(power, POWER_STEP), 0.0, 1.0)
	_sim.set_power(_power_setting)


## Each Station calls with its own tone and light as urgently as the
## simulation says, and every screen shows its autopilot and the time rate.
## Thermal's autopilot may have moved the heat split, and the Drive's its
## power, so the Habitat's copies follow them.
func _show_calls() -> void:
	_heat_split = _sim.heat_split()
	_power_setting = _sim.power()
	var rate := _sim.time_rate()
	var footer := "Time x%d  %s faster %s normal" % [roundi(rate), KeyMap.label(&"time_faster"),
			KeyMap.label(&"time_normal")] if rate > 1.0 \
			else "Time x1  %s faster" % KeyMap.label(&"time_faster")
	for station in _in_use:
		station.set_call(_sim.call_urgency(_sim_names[station]))
		station.autopilot = _sim.autopilot(_sim_names[station])
		station.footer = footer


## The Drive Station's screen, over its primary flight display (FlightDisplay,
## which reads depth, speed, attitude, heading, the Course, power, grip and
## steering itself): whether it follows the Course or its own override, or how
## the dive ended.
func _show_drive() -> void:
	_drive.show_reading(
		"SURFACED  %s start menu" % KeyMap.label(&"new_dive") if _sim.surfaced() else
			"%s  %s start menu" % [_death_headline(), KeyMap.label(&"new_dive")] if _sim.dead() else
			"OVERRIDE %03.0f %+.0f  %s back to Course" % [
			_sim.steered_heading(), _sim.steered_pitch(), KeyMap.label(&"end_override")] if _sim.overriding()
			else "Following the Course")


## Navigation's screen, over its point cloud (which shows the Course): the
## Course plotted, how quiet the vessel is, the points heard and its power.
func _show_navigation() -> void:
	_navigation.show_reading("\n".join([
		"Course %03.0f  %+.0f deg%s" % [_sim.course_heading(), _sim.course_pitch(),
			"  (Drive overriding)" if _sim.overriding() else ""],
		"%s  noise %d%%  %d points" % ["QUIET SHIP" if _sim.quiet_ship() else "under way",
			roundi(_sim.noise() * 100.0), _sim.point_count()],
		_power_line(_sim.navigation_request(), _sim.navigation_draw()),
	]))


## A Station's power: set against actual, as shares of the Reactor's full
## output (PowerLine).
func _power_line(requested: float, drawn: float) -> String:
	return PowerLine.text(requested, drawn, _sim.reactor_full_output())


## The Reactor Station's screen: the Head's plasma, the power it supplies
## against what the Stations draw (shares of its full output, as each Station
## reads its own), and one bar per Station, its request outlined and what it
## gets filled, so a starved Station shows here too.
func _show_reactor() -> void:
	var full := _sim.reactor_full_output()
	var plasma := "STEADY" if _sim.plasma_stability() >= 1.0 else "UNSTEADY"
	var lines := [
		"Plasma %s %d%%  Head %s" % [plasma, roundi(_sim.plasma_stability() * 100.0),
			"running" if _sim.head_activity() >= 1.0 else "idling %d%%" % roundi(_sim.head_activity() * 100.0)],
		"Supply %d%%  drawn %d%%  short %d%%" % [PowerLine.percent(_sim.reactor_output(), full),
			PowerLine.percent(_sim.power_drawn(), full),
			PowerLine.percent(_sim.power_requested(), full) - PowerLine.percent(_sim.power_drawn(), full)],
	]
	for row in [["Nav", _sim.navigation_request(), _sim.navigation_draw()],
			["Thm", _sim.thermal_request(), _sim.thermal_draw()],
			["Drv", _sim.drive_request(), _sim.drive_draw()]]:
		lines.append("%s %s%s" % [row[0], _bar(row[1] / full, row[2] / full),
				"  starved" if PowerLine.starved(row[1], row[2], full) else ""])
	var shift_line := "Head wear %d%%  window %.1f s" % [roundi(_sim.head_wear() * 100.0),
			_sim.shift_window_length()]
	if _sim.plasma_lost():
		shift_line += "  PLASMA LOST"
		lines.append(shift_line)
		lines.append(_store_line())
		lines.append(_relight_line())
		_reactor.show_reading("\n".join(lines))
		return
	elif _sim.shift_due():
		shift_line += "  SHIFT DUE  %s swap" % KeyMap.label(&"shift")
	elif _boundary_ahead:
		shift_line += "  BOUNDARY AHEAD  pretune standby %s" % KeyMap.label(&"tune_standby")
	lines.append(shift_line)
	lines.append(_store_line())
	_reactor.show_reading("\n".join(lines))


## The emergency store on the Reactor screen: how full, and whether the
## Lithocraft is running on it.
func _store_line() -> String:
	var share := _sim.emergency_store() / _sim.emergency_store_capacity()
	return "Emergency store %s %d%%%s" % [_bar(1.0, share), roundi(share * 100.0),
			"  ON STORE" if _sim.on_emergency_store() else ""]


## The relight the Reactor can try while stranded: its pulse against the
## store, its chance on this Head, and the key, or why it cannot.
func _relight_line() -> String:
	var odds := "Relight: pulse %d%% of store, chance %d%%" % [
			roundi(_sim.relight_store_share() * 100.0),
			roundi(_sim.relight_chance() * 100.0)]
	if not _sim.stranded():
		return odds
	if _sim.emergency_store() < _sim.relight_cost():
		return odds + "  STORE TOO LOW"
	return odds + "  %s relight" % KeyMap.label(&"relight")


## The plasma is lost and the tunnel sealed: stranded, on the emergency
## store, a rescue on its way. Tell the crew where, the race between the
## rescue and the stranding clock, what is aboard, and what the store can buy:
## a relight at the Reactor, cooling at Thermal, or the link sending the
## survey up as insurance.
func _on_stranded(event: Dictionary) -> void:
	_show_notice([
		"STRANDED  at %.0f m" % event.depth,
		"The plasma is lost and the tunnel behind is sealed: on the emergency store.",
		"Rescue in %s.  Hull lasts %s as the rock's heat soaks in." % [
			_duration(event.rescue_time), _duration(event.clock)],
		"Survey aboard: %d stretches, worth %.0f: home with the rescue, lost if the hull fails" % [
			event.aboard_stretches, event.aboard],
		"",
		"%s at the Reactor: relight the Head (chance %d%%, costs %d%% of the store)" % [
			KeyMap.label(&"relight"), roundi(_sim.relight_chance() * 100.0),
			roundi(_sim.relight_store_share() * 100.0)],
		"%s at Thermal: run the pumps on the store to cool the hull" % KeyMap.label(&"heat_split", 1),
		"%s at the Bore Station: stop or start the link, which runs on the store" % KeyMap.label(&"link"),
		_stranded_self_destruct_line(),
		"%s wait faster" % KeyMap.label(&"time_faster"),
	], 0.0)


## The STRANDED notice's word on self-destruct: one running carries on as
## the store dumped into the hull, else how to give up that way.
func _stranded_self_destruct_line() -> String:
	if _sim.self_destructing():
		return "SELF-DESTRUCT runs on: the store is dumping into the hull.  %s at Thermal to cancel" % (
				KeyMap.label(&"self_destruct"))
	return "Hold %s at Thermal %.0f s: self-destruct, dumping the store into the hull" % [
			KeyMap.label(&"self_destruct"), _sim.self_destruct_hold_length()]


## A relight's outcome: lit, the dive goes on; failed or refused, the crew
## are still stranded, with what is left in the store.
func _on_relight_result(event: Dictionary) -> void:
	var left := roundi(event.store / _sim.emergency_store_capacity() * 100.0)
	match event.outcome:
		&"lit":
			_show_notice(["RELIT  The Head's plasma holds again",
					"Store left %d%%. Power up at the Drive %s." % [left, KeyMap.label(&"power_step", 0)]], NOTICE_S)
		&"failed":
			_show_notice(["RELIGHT FAILED  the pulse is spent", "Store left %d%%" % left,
					"%s try again, or wait for the rescue" % KeyMap.label(&"relight")], 0.0)
		&"refused":
			_show_notice(["RELIGHT REFUSED  the store cannot pay the pulse",
					"Store left %d%%" % left, "Wait for the rescue"], 0.0)


## The hull failed and the crew died: the dive is over. Under the outcome
## sentence, the breakdown: the unsold survey lost, what was paid and kept,
## and the rebuy (shown, not charged while there is no balance to take it
## from).
func _on_hull_failed(event: Dictionary) -> void:
	_end_dive([
		"Unsold survey lost: %d stretches, worth %.0f" % [event.lost_stretches, event.lost],
		"Paid for this dive: %.0f   Paid in all: %.0f" % [event.amount, event.total_paid],
		"Rebuy: %.0f  (charged %.0f: no balance yet)" % [event.rebuy, event.rebuy_charged],
		"",
		"%s back to the start menu" % KeyMap.label(&"new_dive"),
	])


## The dive has ended: the view lurches from its shake now and settles to
## still, then shows the outcome sentence (DiveSimulation.outcome()) above
## the `breakdown`. Whatever notice was up goes as the lurch begins.
func _end_dive(breakdown: Array) -> void:
	_outcome_lines = [OutcomeScreen.sentence(_sim.outcome()), ""] + breakdown
	_outcome_screen.start(_shake_m)
	_notice.visible = false
	_notice_left = 0.0


## Self-destruct has started: under way the Stations are taken off the crew
## and every bit of heat goes outward; stranded, the store goes into the hull.
## Either way a cancel puts the crew's settings back.
func _on_self_destruct_started(event: Dictionary) -> void:
	_holding_self_destruct = false
	_show_notice([
		"SELF-DESTRUCT",
		"The emergency store is dumping into the hull as heat." if event.stranded
			else "Reactor to full, all heat outward. The Stations are off the crew.",
		"%s at Thermal to cancel and put your settings back.  %s wait faster" % [
			KeyMap.label(&"self_destruct"), KeyMap.label(&"time_faster")],
	], NOTICE_S)


## Self-destruct cancelled: the Stations are the crew's again, set as they
## were just before it started; only the wear done (and the store spent) stay.
func _on_self_destruct_cancelled(event: Dictionary) -> void:
	_show_notice([
		"SELF-DESTRUCT CANCELLED",
		"The Stations are yours again, set as before it began. Pumps on store %d%%." % roundi(
				_sim.heat_split() * 100.0) if event.stranded
			else "The Stations are yours again, set as before it began: Drive %d%%, heat %d%% to the Column." % [
				roundi(_sim.power() * 100.0), roundi(_sim.heat_split() * 100.0)],
		"The store it spent stays spent, and the wear it did stays." if event.stranded
			else "The wear it did stays.",
	], NOTICE_S)


## However the Lithocraft reached the surface (surfaced, rescued, or brought
## home through the open tunnel) and the survey sold: under the outcome
## sentence, what this dive was paid and why, the repairs to its hull and Head
## and any rescue taken out, until the crew starts another dive.
func _on_paid(event: Dictionary) -> void:
	var lines := ["The survey is sold."]
	lines.append_array([
		"Paid for this dive: %.0f" % event.amount,
		"  up the link under way %.0f, carried home %.0f" % [event.by_link, event.carried_home],
		"  hull repair -%.0f, Head repair -%.0f" % [event.hull_repair, event.head_repair],
	])
	if event.rescue > 0.0:
		lines.append("  rescue -%.0f" % event.rescue)
	if event.covered > 0.0:
		lines.append("  the rest, %.0f beyond what the dive earned, is on us" % event.covered)
	lines.append("Column recorded %.0f m in %d stretches, quality %d%%" % [
			event.metres, event.stretches, roundi(event.mean_quality * 100.0)])
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
	lines.append("%s back to the start menu" % KeyMap.label(&"new_dive"))
	_end_dive(lines)


## Shows the centre notice; for `seconds` if above 0, else until replaced.
func _show_notice(lines: Array, seconds: float) -> void:
	_notice.text = "\n".join(lines)
	_notice.visible = true
	_notice_left = seconds


func _fade_notice(delta: float) -> void:
	if _notice_left <= 0.0:
		return
	_notice_left -= delta
	if _notice_left <= 0.0:
		_notice.visible = false


## The F1 controls in the lower left, hidden until asked for (story 52),
## each Station's keys headed by its own name.
func _build_controls() -> void:
	_controls.titles[KeyMap.ANYWHERE] = "Anywhere"
	for station in STATIONS:
		_controls.titles[station[2]] = station[0]
	_controls.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	_controls.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_controls.offset_left = 16.0
	_controls.offset_bottom = -16.0
	_controls.visible = false
	$Overlay.add_child(_controls)


## The checklist in the upper left, clear of the F1 controls and the debug
## menu, hidden until asked for; each Station named in its own colour.
func _build_checklist() -> void:
	_checklist.sim = _sim
	for station in STATIONS:
		if station[2] != &"":
			_checklist.stations[station[2]] = [station[0], station[1]]
	_checklist.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_checklist.offset_left = 16.0
	_checklist.offset_top = 16.0
	_checklist.visible = false
	$Overlay.add_child(_checklist)


## The numpad debug menu in the lower left, where the F1 controls go, hidden
## until asked for.
func _build_debug_menu() -> void:
	_debug_menu.sim = _sim
	_debug_menu.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	_debug_menu.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_debug_menu.offset_left = 16.0
	_debug_menu.offset_bottom = -16.0
	_debug_menu.visible = false
	$Overlay.add_child(_debug_menu)


## The centre dot, a small round mark at the middle of the screen, hidden
## until the mouse is captured.
func _build_dot() -> void:
	_dot = Panel.new()
	_dot.set_anchors_preset(Control.PRESET_CENTER)
	_dot.offset_left = -DOT_PX / 2.0
	_dot.offset_top = -DOT_PX / 2.0
	_dot.offset_right = DOT_PX / 2.0
	_dot.offset_bottom = DOT_PX / 2.0
	_dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var round := StyleBoxFlat.new()
	round.bg_color = Color.WHITE
	round.set_corner_radius_all(ceili(DOT_PX / 2.0))
	round.anti_aliasing = true
	_dot.add_theme_stylebox_override(&"panel", round)
	_dot.visible = false
	$Overlay.add_child(_dot)


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


## A bar of tenths: '#' power drawn, '-' asked for but not given, '.' unused.
static func _bar(requested: float, drawn: float) -> String:
	var got := roundi(drawn * 10.0)
	var asked := maxi(got, roundi(requested * 10.0))
	return "[%s%s%s]" % ["#".repeat(got), "-".repeat(asked - got), ".".repeat(maxi(0, 10 - asked))]


## Stand-in Bore Station control until it has its own: observe the next
## feature in the Column not yet recorded, nearest the Tail first, cycling.
func _observe_next_feature() -> void:
	var candidates := _sim.features_in_column().filter(
			func(f: ColumnFeature) -> bool: return not f.is_recorded())
	if candidates.is_empty():
		_sim.set_observed_feature(-1)
		return
	var ids := candidates.map(func(f: ColumnFeature) -> int: return f.id)
	var current := ids.find(_sim.observed_feature())
	_sim.set_observed_feature(ids[(current + 1) % ids.size()])


## Bore Station: which waiting survey data goes up the link first, cycling
## through UPLOAD_PRIORITIES.
func _cycle_upload_priority() -> void:
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
		lines.append("%s observe a feature" % KeyMap.label(&"observe"))
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


## The heat split, worked at the Thermal Station.
func _split_heat(to_column: float) -> void:
	_heat_split = clampf(snappedf(to_column, HEAT_SPLIT_STEP), 0.0, 1.0)
	_sim.set_heat_split(_heat_split)


## The Thermal Station's screen: the split, where the heat is going, the hull
## against the Medium and the temperature it can bear, and the hull's
## integrity and how fast it is creeping. It calls with its light while the
## simulation warns of heat damage.
func _show_thermal() -> void:
	var warning := _sim.heat_warning()
	var to_column := roundi(_heat_split * 10.0)
	var lines := [
		_power_line(_sim.thermal_request(), _sim.thermal_draw()),
		"Out [%s|%s] Column" % ["#".repeat(10 - to_column), "#".repeat(to_column)],
		"Heat %.2f > Column %.2f" % [_sim.heat_produced(), _sim.heat_to_column()],
		"Hull %.0f K, bears %.0f K  Medium %.0f K" % [_sim.vessel_temperature(),
			_sim.hull_damage_temperature(), _sim.surroundings_temperature()],
		"Integrity %.1f%%  creep %.2f%%/min" % [
			_sim.hull_integrity() * 100.0, _sim.hull_creep_rate() * PERCENT_PER_MIN],
	]
	if _sim.stranded():
		lines.append("Pumps on store %d%%" % roundi(_heat_split * 100.0))
	if _sim.stranded() or _sim.tunnel_sealed():
		lines.append(_race_line())
	var self_destruct := _self_destruct_line()
	if not self_destruct.is_empty():
		lines.append(self_destruct)
	if _sim.dead():
		lines.append("!! %s !!" % _death_headline())
	elif _sim.hull_creep_rate() > 0.0:
		lines.append("!! HULL CREEPING !!  over %.0f K" % (
			_sim.vessel_temperature() - _sim.hull_damage_temperature()))
	elif warning:
		lines.append("!! HEAT WARNING !!")
	_thermal.show_reading("\n".join(lines))


## How the crew died, as the notice heads it: by self-destruct or the heat.
func _death_headline() -> String:
	return "SELF-DESTRUCT" if _sim.cause_of_death() == &"self_destruct" else "HULL FAILED"


## Self-destruct at Thermal: the hold filling while K is held, the running
## self-destruct and how to cancel it, how to arm it, or why it cannot be
## (stranded with the store empty: nothing to dump). Empty once the dive is
## over.
func _self_destruct_line() -> String:
	if _sim.self_destructing():
		return "!! SELF-DESTRUCT !!  %s cancel" % KeyMap.label(&"self_destruct")
	if _sim.surfaced() or _sim.dead():
		return ""
	if not _sim.can_self_destruct():
		return "Self-destruct: store empty, nothing to dump into the hull"
	var held := _sim.self_destruct_hold()
	if held > 0.0:
		return "ARMING SELF-DESTRUCT %s  keep holding %s" % [_bar(1.0, held),
				KeyMap.label(&"self_destruct")]
	return "Self-destruct: hold %s %.0f s" % [KeyMap.label(&"self_destruct"),
			_sim.self_destruct_hold_length()]


## The stranding clock beside the rescue time, live: while stranded the race
## itself; sealed in but under way, what it would be if the plasma went now.
func _race_line() -> String:
	var clock := _sim.stranding_clock()
	var rescue := _sim.rescue_time()
	var line := "Hull lasts %s | Rescue %s" % [_duration(clock), _duration(rescue)]
	if not _sim.stranded():
		return "If stranded: " + line
	return line + ("  RESCUE FIRST" if rescue < clock else "  !! CLOCK FIRST !!")


## Seconds as h:mm:ss or m:ss; for ever as "holds".
static func _duration(seconds: float) -> String:
	if is_inf(seconds):
		return "holds"
	var s := roundi(seconds)
	if s >= 3600:
		return "%d:%02d:%02d" % [s / 3600, (s / 60) % 60, s % 60]
	return "%d:%02d" % [s / 60, s % 60]


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


## A Station place's angle round the Bore axis, radians from +X toward +Y.
## The places are spaced evenly and turned half a place off straight down,
## so level no Station hangs straight below or above the Bore, where its
## screen could not face it: the Reactor and the Drive sit either side of
## the floor.
static func place_angle(place: int) -> float:
	return TAU * (place - 0.5) / STATIONS.size() - PI / 2.0


## Where a Station place's gimbal pivots, STATION_HANG in from the outer wall.
static func pivot(place: int) -> Vector3:
	var a := place_angle(place)
	return Vector3(cos(a), sin(a), 0) * (OUTER_RADIUS - STATION_HANG)


func _build_stations() -> void:
	for i in STATIONS.size():
		var a := place_angle(i)
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
		station.position = pivot(i)
		add_child(station)
		_stations.append(station)
		if not station.station_name.is_empty():
			_in_use.append(station)
			_sim_names[station] = STATIONS[i][2]
			station.show_keys(KeyMap.bindings_at(STATIONS[i][2]))
		if station.station_name == "Reactor":
			_reactor = station
			_reactor.show_display(_make_plasma_display())
		elif station.station_name == "Drive":
			_drive = station
			_drive.show_display(_flight_display(station.hue), FlightDisplay.instrument_shares())
		elif station.station_name == "Bore Station":
			_bore_station = station
			_bore_station.show_display(_bore_display())
		elif station.station_name == "Thermal":
			_thermal = station
		elif station.station_name == "Navigation":
			_navigation = station
			var navigation_displays: Array[Texture2D] = [_scan_display(), _moving_map()]
			_navigation.show_displays(navigation_displays)


## The Reactor's waveform display for the Shift: the dial's ACTIVE and
## STANDBY channels.
func _make_plasma_display() -> Texture2D:
	var display := PlasmaDisplay.new()
	display.size = Vector2i(512, 242)
	display.sim = _sim
	display.hue = STATIONS[0][1]
	add_child(display)
	return display.get_texture()


## The Drive's primary flight display, shown on the Drive Station's screen.
func _flight_display(hue: Color) -> Texture2D:
	var display := FlightDisplay.new()
	display.sim = _sim
	display.hue = hue
	add_child(display)
	return display.get_texture()


## Navigation's point cloud display, drawn in its own world and shown on the
## left of the Navigation Station's screen.
func _scan_display() -> Texture2D:
	var display := ScanDisplay.new()
	display.size = _navigation_display_px()
	display.sim = _sim
	add_child(display)
	return display.get_texture()


## The size in pixels of each of Navigation's two displays side by side.
static func _navigation_display_px() -> Vector2i:
	return Vector2i((GimballedStation.display_rect(0, 2).size * DISPLAY_PX_PER_M).round())


## Navigation's moving map, a cross-section of the whole dive, shown on the
## right of its screen beside the point cloud.
func _moving_map() -> Texture2D:
	var map := MovingMap.new()
	map.size = _navigation_display_px()
	map.sim = _sim
	add_child(map)
	return map.get_texture()


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
