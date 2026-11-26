## The simulation of one dive. Knows nothing of scenes, rendering or input.
##
## Interface shape, copied by every later ticket:
##   commands in   - one method per Station command, e.g. set_power()
##   time step     - advance(dt), dt in simulated seconds
##   state out     - read-only query methods, e.g. depth()
##   events out    - take_events(): events since the last call, then cleared.
##                   Each a Dictionary with a `type` StringName plus fields.
## Heat (Heat), the plasma and the Shift (Plasma), and stranding (Stranding)
## are its own subsystems, reached only through this interface; see
## docs/conventions.md, "Subsystems".
class_name DiveSimulation
extends RefCounted

## Speed in metres per second at full power through a Medium of hardness 1.
## Tuned for play (ADR 0001); tests must not depend on its value.
const _FULL_POWER_SPEED := 2.0
## How much Drive power the grip waves can put into a wall of strength 1
## before the wall gives way and they slip. Tuned for play (ADR 0001).
const _GRIP_PER_STRENGTH := 2.0
## Length of path the Bore Station records as one survey entry, in metres.
## Tuned for play (ADR 0001).
const _SURVEY_STRETCH_M := 10.0

## Seconds of observation the Bore Station needs to record a feature in full
## at pristine recording quality. Tuned for play (ADR 0001) so that at full
## power a feature can slip out through the Tail half recorded.
const _FEATURE_RECORD_S := 20.0

## Habitat frame: the fixed axes of the vessel that felt_acceleration() is
## given in. TOWARD_HEAD runs along the Bore toward the Head. TOWARD_UNDERSIDE
## is the outer wall that is underneath when the vessel is level.
const TOWARD_HEAD := Vector3.FORWARD
const TOWARD_UNDERSIDE := Vector3.DOWN

## Steering. The Head turns the Lithocraft by heating one side of its rim
## harder than the other, so the vessel cuts faster on that side and its path
## bends. The tightest arc it can cut, in metres of radius. Tuned for play
## (ADR 0001); tests read minimum_turn_radius(), never this.
const _MIN_TURN_RADIUS_M := 250.0
## How fast the uneven heating builds up or dies away, as a share of full
## steering per second: the vessel answers the Drive slowly. Tuned for play.
const _STEER_RESPONSE := 0.1
## Within this many degrees of the setting the steering eases off, so the
## vessel settles onto its heading instead of swinging past. Tuned for play.
const _STEER_EASE_DEG := 10.0
## The most the Drive's autopilot steers, as a share of full steering: it
## follows the Course on a wide, cool arc rather than spend power and heat
## turning hard. Tuned for play (ADR 0001).
const _AUTOPILOT_STEERING_EFFORT := 0.25
## The power the Drive's autopilot sets on being engaged: slow and safe, well
## inside what loose sand can grip. Tuned for play (ADR 0001).
const _AUTOPILOT_DRIVE_POWER := 0.3
## Extra Drive power at full steering, as a share of its setting: the hot side
## of the Head runs hotter than the cool side is eased, and that extra goes
## into heat, not push. Tuned for play.
const _STEER_HEAT := 0.5
## The path the Column was cut along is remembered as points at least this
## far apart (straight runs are merged into one piece). Metres.
const _PATH_SAMPLE_M := 0.5

## Upload priorities for set_upload_priority(): which waiting survey stretch
## goes up the link next.
const UPLOAD_OLDEST_FIRST := &"oldest_first"
const UPLOAD_NEWEST_FIRST := &"newest_first"
const UPLOAD_MOST_VALUABLE_FIRST := &"most_valuable_first"

## Earth's surface gravity, m/s^2.
const _GRAVITY := 9.81

## Length of the Lithocraft from Head to Tail, in metres: how far behind the
## Head the tunnel is made. Tuned for play (ADR 0001).
const _VESSEL_LENGTH_M := 12.0
## Below this porosity the Medium has no pore space to take the melt as a
## glass lining, so the melt is pumped aft and fills the tunnel. Sandstone is
## above it and granite below. Tuned for play (ADR 0001).
const _SEAL_POROSITY := 0.1
## Survey metres per second the light link up an open, glass-lined tunnel
## carries. Tuned for play (ADR 0001).
const _FAST_LINK_RATE := 2.0
## Survey metres per second sound through rock carries, in a Medium whose
## sound_carrying is 1. Far below the fast link. Tuned for play (ADR 0001).
const _SLOW_LINK_RATE := 0.02
## What the link draws while sending, in the units of set_power(). Counted
## only once the plasma is lost, when it runs on the emergency store. Real
## basis: a sound source strong enough to carry through rock takes power.
## Tuned for play (ADR 0001): the store sends a few stretches, or pays for a
## relight or two, not both.
const _LINK_DRAW := 0.05

## Navigation's power request: the scanner's draw while it listens, in the same
## units as set_power(), with the cost of its pulses averaged in. Tuned for
## play (ADR 0001).
const _NAVIGATION_DRAW := 0.05

## The power budget. The Reactor's output in the units of set_power() with the
## Head running steadily, and with it idling under Quiet Ship. Sized so the
## Drive at full, Navigation and Thermal's base pumps just fit while the Head
## runs, and pumping heat into the Column does not. Tuned for play (ADR 0001).
const _REACTOR_FULL_OUTPUT := 1.1
const _REACTOR_IDLE_OUTPUT := 0.1
## Thermal's power request: its pumps always run, and pumping heat into the
## Column costs more for each share of heat sent there. Tuned for play
## (ADR 0001).
const _THERMAL_BASE_DRAW := 0.03
const _THERMAL_COLUMN_DRAW := 0.2

## How fast the Head spins down to idle under Quiet Ship, and back up after,
## as a share of full running per second. The vessel coasts while it spins
## down. Tuned for play (ADR 0001).
const _HEAD_SPIN_RATE := 0.25
## The vessel's own noise, heard by Navigation: the Head's hum while it runs,
## and the grip waves' noise per share of Drive power, louder when they slip.
## Tuned for play (ADR 0001).
const _HEAD_HUM := 0.1
const _DRIVE_NOISE := 0.5
## How good the survey record is while Quiet Ship shutters the Bore
## instruments, 0 to 1. Tuned for play (ADR 0001).
const _SHUTTERED_QUALITY := 0.2

## The scan. A pulse is sent as this many rays in a cone this wide (half-angle,
## degrees) round the heading. Tuned for play (ADR 0001).
const _PULSE_RAYS := 300
const _PULSE_CONE_DEG := 35.0
## Metres a pulse carries through a Medium of sound-carrying 1 before its echo
## has faded to 1/e (out and back counts twice). Tuned for play (ADR 0001).
const _SCAN_REACH_M := 500.0
## Echoes weaker than this (1 = a perfect reflection close by) are lost.
const _ECHO_CUTOFF := 0.01
## Echo strength that reads as even odds against the scanner's own noise
## floor, even with the vessel silent. Tuned for play (ADR 0001).
const _SCAN_NOISE_FLOOR := 0.15
## How far an uncertain point strays from its echo, per metre of range at zero
## confidence. Tuned for play (ADR 0001).
const _SCAN_SCATTER := 0.08
## Step for finding Boundaries along the depth a pulse can reach, metres.
const _BOUNDARY_SEARCH_STEP_M := 1.0

## Boundaries. A Boundary this many metres of depth ahead is announced, so the
## Reactor Station can prepare for the Shift. Tuned for play (ADR 0001).
const _BOUNDARY_APPROACH_M := 30.0

## A Checklist step's state, as checklist() gives it: still to do, done, or
## missed (its phase was left behind first).
const STEP_PENDING := Checklist.PENDING
const STEP_DONE := Checklist.DONE
const STEP_MISSED := Checklist.MISSED

## The Stations, as named in set_attended(), set_autopilot(), call_urgency()
## and calls.
const STATION_REACTOR := &"reactor"
const STATION_DRIVE := &"drive"
const STATION_THERMAL := &"thermal"
const STATION_NAVIGATION := &"navigation"
const STATION_BORE := &"bore"
const STATIONS: Array[StringName] = [STATION_REACTOR, STATION_DRIVE, STATION_THERMAL,
		STATION_NAVIGATION, STATION_BORE]
## Share of the heat split Thermal's autopilot moves into the Column per
## second while the hull warns: its steadying rule, slow on purpose so a
## sudden heat outruns it. Tuned for play (ADR 0001).
const _AUTOPILOT_SPLIT_RATE := 0.01
## Why an autopilot disengaged, as &"autopilot_off" carries it: a crew command
## that changed that Station's setting, or the crew's own switch.
const AUTOPILOT_OFF_BY_COMMAND := &"command"
const AUTOPILOT_OFF_BY_SWITCH := &"switch"
## How urgently each kind of call is made, 0 to 1: x when it begins, y at its
## worst (the hull at the damage temperature, a Station given nothing, the Tail
## about to leave the tunnel open, a feature about to leave through the Tail,
## the Shift's window long closed, the Boundary reached). So the Reactor's
## Shift and a hot hull always call louder than a feature passing by. Losing
## the plasma calls as loudly as anything can. Tuned for play (ADR 0001).
const _HEAT_WARNING_CALL := Vector2(0.5, 1.0)
const _STARVED_CALL := Vector2(0.3, 0.8)
const _SEAL_COMING_CALL := Vector2(0.4, 0.9)
const _FEATURE_CALL := Vector2(0.2, 0.6)
const _SHIFT_DUE_CALL := Vector2(0.6, 1.0)
const _BOUNDARY_AHEAD_CALL := Vector2(0.2, 0.5)
const _EMERGENCY_CALL_URGENCY := 1.0
## The fastest the simulation may be run, as a multiple of normal. Turns take
## minutes at normal rate. Tuned for play (ADR 0001).
const _MAX_TIME_RATE := 64.0
## Longest step taken while running fast, in simulated seconds, so a fast rate
## costs a few steps a frame, not one per normal-rate frame.
const _FAST_STEP_S := 0.25
## Self-destruct. Seconds the crew must hold the command at Thermal to arm
## it, in real time (advance()'s dt, whatever the time rate), so it is never
## set off by a slip of the hand. The developer's design value (25 November
## 2026), not a constant tuned for play under ADR 0001.
const _SELF_DESTRUCT_HOLD_S := 3.0
## Stranded, how fast self-destruct dumps the emergency store into the hull as
## heat, in the units of set_power(): all the stored energy goes through a
## resistive load and becomes heat (real basis), so a full store is spent in
## well under a minute. Tuned for play (ADR 0001).
const _SELF_DESTRUCT_DUMP := 5.0
## Debug commands (see "Debug commands" below). The hull's wear at the brink
## of failure, all but worn through. Not tuned for play: a debug setting.
const _DEBUG_BRINK_WEAR := 0.98
## How far past a Boundary debug_next_boundary() leaves the Head, in metres of
## depth, the share of straight down the Head must point for it to jump (less
## is near level, where no Boundary lies ahead), and the pieces it moves in.
const _DEBUG_PAST_BOUNDARY_M := 0.5
const _DEBUG_LEAST_DESCENT := 0.05
const _DEBUG_TRAVEL_PIECE_M := 1.0
## What a new dive keeps; every other variable starts over as a fresh dive.
## The world (the layout), what was paid for, and events not yet taken.
const _KEPT_BETWEEN_DIVES: Array[StringName] = [&"_layout", &"_paid", &"_uploaded", &"_events",
		# Where the crew is: the view tells the simulation, not the dive.
		&"_attended",
		# The luck of relights runs on from dive to dive.
		&"_relight_random",
		# The Scenario being played; each new dive starts its Checklist afresh.
		&"_scenario"]

var _layout: MediumLayout
var _power := 0.0
## Where the Head is in the world frame (see head_position()) and the way it
## points there, unit length. Starts at the surface, Head straight down.
var _position := Vector3.ZERO
var _direction := Vector3.DOWN
## The Course Navigation plots: the pitch and compass heading to follow, degrees.
var _course_pitch := 90.0
var _course_heading := 0.0
## The Drive's override, steered toward instead of the Course while it lasts:
## heading and pitch in degrees. Only an attended Drive can begin one; it
## holds until ended, or until the Drive's autopilot is engaged.
var _overriding := false
var _override_heading := 0.0
var _override_pitch := 0.0
## The last compass heading the vessel had while not pointing straight up or
## down, where heading has no meaning. Degrees, 0 along -Z, 90 along +X.
var _bearing := 0.0
## How hard the Head is steering: 0 even heating, 1 the tightest arc.
var _steering := 0.0
## The Drive's call: the hardest it will steer toward the Course, 0 to 1.
var _steering_effort := 1.0
## The path so far as (distance along it, depth) points, for the Column.
var _path_distances := PackedFloat64Array([0.0])
var _path_depths := PackedFloat64Array([0.0])
var _speed := 0.0
var _slip := 0.0
## Thermal: the share of heat sent into the Column; the rest goes outward.
var _heat_split := 0.0
## The vessel's heat and the hull it passes through (sim/heat.gd).
var _heat: Heat
## Metres travelled along the path since the dive began.
var _distance := 0.0
## Completed survey entries, oldest first.
var _survey: Array[SurveyStretch] = []
## The stretch being recorded now: where it began, and per-metre sums of what
## the Column held (mineral -> metres, Medium name -> metres, quality x metres).
var _stretch_start := 0.0
var _stretch_minerals := {}
var _stretch_media := {}
var _stretch_quality := 0.0
## Features of interest the Head has found, in the order found.
var _features: Array[ColumnFeature] = []
## Layout feature templates already found, so crossing one again adds nothing.
var _found_templates := {}
## The id of the feature the Bore Station is observing, or -1 for none.
var _observed := -1
## Running total of what the recorded survey is worth (completed stretches and
## features recorded in full), so survey_value() never scans the whole survey.
var _survey_value := 0.0
var _stretch_shuttered := false
## True once the melt has filled the tunnel somewhere behind: from then on no
## continuous open tunnel reaches the surface.
var _tunnel_sealed := false
## Metres of the tunnel behind the Tail the melt has filled, and how far along
## the path the Tail has left the tunnel so far.
var _sealed_metres := 0.0
var _tail_at := 0.0
## Survey stretches whose data has reached the surface, in the order they
## arrived, and what was paid for them all.
var _uploaded: Array[SurveyStretch] = []
var _paid := 0.0
## Completed stretches still aboard, oldest first, and the one the link is
## sending now (null when it must be chosen again).
var _waiting: Array[SurveyStretch] = []
var _sending: SurveyStretch = null
## Stretch -> metres of it that have already reached the surface. A stretch
## is paid for only once all of it is up.
var _sent := {}
var _upload_priority := UPLOAD_OLDEST_FIRST
## Whether the link sends the survey aboard up (set_uploading()).
var _uploading := true
## Events raised since the last take_events(), oldest first.
var _events: Array[Dictionary] = []
## Quiet Ship: set by Navigation; the Head spins down and the Bore shutters.
var _quiet_ship := false
## How hard the Head is running, 0 (idle) to 1 (running). Starts running.
var _head_activity := 1.0
## The vessel's own noise during the last step, 0 when silent.
var _noise := 0.0
## The power budget during the last step: the Reactor's output, and what each
## Station asked for and was given, in the units of set_power().
var _reactor_output := 0.0
var _drive_request := 0.0
var _thermal_request := 0.0
var _navigation_request := 0.0
var _drive_draw := 0.0
var _thermal_draw := 0.0
var _navigation_draw := 0.0
## The Head's plasma and the Shift, and the Head's wear (sim/plasma.gd).
var _plasma: Plasma
## Navigation's point cloud, oldest first, and whether a pulse is waiting to
## be sent on the next step.
var _points: Array[ScanPoint] = []
var _pulse_pending := false
var _pulses_sent := 0
## Fixed seed, so a dive's scan is the same every run.
var _scan_random := RandomNumberGenerator.new()
## Depth of the Boundary last announced as approaching, or NAN for none.
var _announced_boundary := NAN
## Stranding, rescue and death: what losing the plasma or the hull comes to
## (sim/stranding.gd).
var _stranding := Stranding.new()
## A relight asked for since the last step.
var _relight_asked := false
## The luck of relights. Fixed seed, so a run is the same every time; kept
## between dives, so each dive does not replay the last one's luck.
var _relight_random := RandomNumberGenerator.new()
## Stations a crew member is at (StringName -> true).
var _attended := {}
## Stations whose autopilot is engaged (StringName -> true). All start off.
var _autopilot := {}
## How many times normal the simulation runs, 1 or more.
var _time_rate := 1.0
## Each calling Station's call: StringName -> [reason StringName, urgency].
var _calls := {}
## Path distance at which the Head entered Medium that will seal the tunnel
## when the Tail leaves it, or NAN while none is coming.
var _seal_coming_at := NAN
## True once the Head has come back up to the surface: the dive is over and
## its survey sold. Nothing moves until new_dive().
var _surfaced := false
## Where this dive's entries begin in _uploaded, and what had been paid before
## it began: so the payment on surfacing covers this dive alone.
var _dive_uploaded_from := 0
var _paid_before_dive := 0.0
## What this dive's survey has been paid as it reached the surface up the link.
var _paid_by_link := 0.0
## Self-destruct: whether the crew holds the command now, how long they have
## held it (real seconds), whether a hold must be let go before another
## counts (after arming or cancelling), and whether it is running.
var _self_destruct_held := false
var _self_destruct_hold := 0.0
var _self_destruct_needs_release := false
var _self_destructing := false
## The crew's settings from just before self-destruct started, which a cancel
## restores: power, heat_split, quiet_ship.
var _crew_settings := {}
## Why the crew died (&"heat" or &"self_destruct"), or &"" while alive.
var _death_cause := &""
## The Scenario being played (an empty one by default: no Orders, no
## Checklist) and this dive's progress through it; see set_scenario().
var _scenario := Scenario.new()
var _checklist: Checklist
## How many of _events the Checklist has already been shown, and events
## taken (take_events()) before it saw them, which it sees next.
var _events_checked := 0
var _events_unseen: Array[Dictionary] = []
## The Reactor's Shift dial, in hertz: the frequency the next Shift is made at.
var _shift_dial := 0.0
## How the dive ended (see outcome()), set once it ends; empty under way.
var _outcome := {}


func _init(layout: MediumLayout) -> void:
	_layout = layout
	_heat = Heat.new(surroundings_temperature())
	_scan_random.seed = 13
	_relight_random.seed = 29
	_plasma = Plasma.new(plasma_frequency())
	_shift_dial = _plasma.tuning()
	_checklist = Checklist.new(_scenario)
	_share_power()


# --- Commands -------------------------------------------------------------

## Drive Station: the share of available power sent to advancing, 0 to 1.
func set_power(power: float) -> void:
	if _off_the_crew():
		return
	_disengage_on_command(STATION_DRIVE)
	_power = clampf(power, 0.0, 1.0)


## Navigation: plots the Course, the compass heading and pitch the Drive steers
## toward, in degrees. Heading 0 along the world's -Z, 90 along +X; pitch +90
## the Head straight down (diving), 0 level, -90 straight up (climbing). The
## vessel turns toward it along an arc no tighter than minimum_turn_radius(),
## and only while it moves. Heading has no effect while the pitch is straight
## up or down.
func set_course(heading_degrees: float, pitch_degrees: float) -> void:
	if _off_the_crew():
		return
	_disengage_on_command(STATION_NAVIGATION)
	_course_heading = fposmod(heading_degrees, 360.0)
	_course_pitch = clampf(pitch_degrees, -90.0, 90.0)
	_events.append({type = &"course_plotted", heading = _course_heading, pitch = _course_pitch})


## Drive: how hard to steer toward the Course, 0 (not at all) to 1 (the
## tightest arc). Steering harder turns sooner but spends more power, and so
## makes more heat. The Drive's autopilot never steers harder than a gentle
## share of full, whatever this is.
func set_steering_effort(effort: float) -> void:
	if _off_the_crew():
		return
	_disengage_on_command(STATION_DRIVE)
	_steering_effort = clampf(effort, 0.0, 1.0)


## Drive: steers toward this heading and pitch (degrees, as set_course())
## instead of the Course, until end_override() or until the Drive's autopilot
## is engaged. Ignored while nobody is at the Drive.
func override_course(heading_degrees: float, pitch_degrees: float) -> void:
	if _off_the_crew():
		return
	if not attended(STATION_DRIVE):
		return
	_disengage_on_command(STATION_DRIVE)
	_overriding = true
	_override_heading = fposmod(heading_degrees, 360.0)
	_override_pitch = clampf(pitch_degrees, -90.0, 90.0)


## Drive: gives up an override and steers toward the Course again.
func end_override() -> void:
	if _off_the_crew():
		return
	_disengage_on_command(STATION_DRIVE)
	_overriding = false


## Bore Station: which feature in the Column to observe and record, by id
## (see features_in_column()). -1, or a feature not now in the Column, observes
## nothing. Observing records; nothing is ever cut out of the Column. A
## reading, not a setting: it leaves the Bore Station's autopilot as it is.
func set_observed_feature(id: int) -> void:
	if id >= 0 and id < _features.size() and _in_column(_features[id]):
		_observed = id
	else:
		_observed = -1


## Bore Station: which waiting survey data goes up the link first, one of the
## UPLOAD_* priorities. Anything else is ignored. Data part-way up keeps what
## it has sent.
func set_upload_priority(priority: StringName) -> void:
	if priority in [UPLOAD_OLDEST_FIRST, UPLOAD_NEWEST_FIRST, UPLOAD_MOST_VALUABLE_FIRST]:
		_disengage_on_command(STATION_BORE)
		_upload_priority = priority
		_sending = null


## Bore Station: whether the link sends the survey aboard up to the surface.
## On at the start of a dive. While stranded the link runs on the emergency
## store, so stopping it keeps the store for a relight.
func set_uploading(on: bool) -> void:
	_disengage_on_command(STATION_BORE)
	_uploading = on


## Thermal Station: the share of the heat sent into the Column, 0 to 1. The
## rest goes outward into the surrounding Medium through the hull. While
## stranded it is how hard the pumps run on the emergency store, carrying the
## heat soaking into the hull into the Column (see stranding_clock()); they
## stop when the plasma is lost, so stranding sets it to 0.
func set_heat_split(to_column: float) -> void:
	if _off_the_crew():
		return
	_disengage_on_command(STATION_THERMAL)
	_heat_split = clampf(to_column, 0.0, 1.0)


## Navigation: send one sound pulse ahead. Its echoes are added to the point
## cloud on the next step. A reading, not a setting: it leaves Navigation's
## autopilot as it is.
func pulse() -> void:
	if _off_the_crew():
		return
	_pulse_pending = true


## Navigation: Quiet Ship on or off. On, the Head spins down to idle and the
## vessel halts whatever the Drive asks, so a pulse is not drowned by the
## vessel's own noise; the Bore instruments are shuttered while it lasts. Off,
## the Head spins back up and the Drive's power setting applies again.
func set_quiet_ship(on: bool) -> void:
	if _off_the_crew():
		return
	_disengage_on_command(STATION_NAVIGATION)
	_quiet_ship = on


## Whether a crew member is at this Station (one of STATIONS) to work it.
## Being there matters only for commands that need the crew present (the
## Drive's override, self-destruct's hold); whether a Station steadies itself
## is its autopilot's switch alone (set_autopilot()). All start unattended.
func set_attended(station: StringName, attended: bool) -> void:
	if station in STATIONS:
		_attended[station] = attended


## Engages or disengages this Station's autopilot (one of STATIONS): the
## crew's switch. Engaged, the Station applies its steadying rule: the
## Reactor makes an overdue Shift on frequency but late, so poorly; Thermal
## slowly sends heat into the Column while the hull warns; the Drive follows
## the Course (ending any override) at slow, safe power, steering gently, and
## backs its power off to the grip limit while it slips. Navigation's and the
## Bore Station's have no rule yet. Off, a Station holds its setting and does
## nothing more; its calls still come. Any crew command at a Station that
## changes its setting or acts (a Shift, a relight) disengages its autopilot;
## taking a reading (a pulse, observing a feature) does not. Every autopilot starts off each dive.
## Disengaging raises &"autopilot_off".
func set_autopilot(station: StringName, engaged: bool) -> void:
	if not station in STATIONS or (station != STATION_BORE and _off_the_crew()):
		return
	if not engaged:
		_disengage(station, AUTOPILOT_OFF_BY_SWITCH)
		return
	if autopilot(station):
		return
	_autopilot[station] = true
	if station == STATION_DRIVE:
		_overriding = false
		_power = _AUTOPILOT_DRIVE_POWER


## The crew has taken this Station's controls (any command but a reading):
## its autopilot lets go.
func _disengage_on_command(station: StringName) -> void:
	_disengage(station, AUTOPILOT_OFF_BY_COMMAND)


func _disengage(station: StringName, cause: StringName) -> void:
	if not autopilot(station):
		return
	_autopilot.erase(station)
	_events.append({type = &"autopilot_off", station = station, cause = cause})


## How many times normal to run the simulation: advance(dt) then runs
## dt x rate simulated seconds. Clamped to 1..max_time_rate(). Any Station call
## returns it to 1, and while any Station is still calling it cannot be raised
## above 1: time runs fast only through quiet stretches. Stranded, it can be:
## the crew wait on the link and the store, and nothing else moves. So it can
## while self-destruct runs, with the Stations off the crew: calls neither
## hold it down nor return it to 1.
func set_time_rate(rate: float) -> void:
	var fastest := _MAX_TIME_RATE if _calls.is_empty() or stranded() or _self_destructing \
			else 1.0
	_time_rate = clampf(rate, 1.0, fastest)


## Start another dive after surfacing (under its own power, brought home
## through the open tunnel, or rescued), or after death in a rebought
## Lithocraft: it is at the surface ready to dive with a whole hull, every
## Station setting back at its start. What was paid is kept. Ignored unless surfaced() or dead(). Raises &"new_dive".
func new_dive() -> void:
	if not (_surfaced or dead()):
		return
	_start_fresh()
	_begin_scenario()
	_events.append({type = &"new_dive", paid = _paid})


## Resets every script variable to a fresh simulation's except those kept
## between dives (_KEPT_BETWEEN_DIVES), and starts counting a new dive's pay.
func _start_fresh() -> void:
	var fresh := DiveSimulation.new(_layout)
	for property in get_property_list():
		if property.usage & PROPERTY_USAGE_SCRIPT_VARIABLE \
				and not StringName(property.name) in _KEPT_BETWEEN_DIVES:
			set(property.name, fresh.get(property.name))
	_dive_uploaded_from = _uploaded.size()
	_paid_before_dive = _paid


## Reactor Station: try to relight the Head on the next step. Only while
## stranded: the pulse that strikes the plasma (relight_cost()) comes from the
## emergency store, and a relight the store cannot pay for is refused. It
## lights with relight_chance(); lit, the stranding ends and the dive goes on;
## failed, the energy is spent. Raises &"relight_result".
func relight() -> void:
	if _off_the_crew():
		return
	if stranded():  # Only stranded does a relight do anything.
		_disengage_on_command(STATION_REACTOR)
	_relight_asked = true


## Plays this Scenario from here: its Orders and Checklist start afresh and
## its start state (Scenario.prepare) is applied. Kept for every later dive,
## each starting its Checklist afresh. Scenario.start() builds a dive and
## calls this.
func set_scenario(scenario: Scenario) -> void:
	_scenario = scenario
	_begin_scenario()


func _begin_scenario() -> void:
	_checklist = Checklist.new(_scenario)
	_events_checked = _events.size()  # Events from before are not this dive's.
	_events_unseen = []
	_scenario.prepare.call(self)


## The crew has read the Orders (the view sends it when the Checklist is first
## opened). Raises &"orders_read".
func read_orders() -> void:
	_events.append({type = &"orders_read"})


## Reactor Station: turns the Shift dial to this frequency in hertz, the one
## the next Shift is made at (the view shows shift_dial() and passes it to
## shift(), so the two never disagree). A
## selector, not a setting the Reactor acts on: like turning an A320's heading
## knob, it leaves the Reactor's autopilot engaged.
func set_shift_dial(frequency: float) -> void:
	if _off_the_crew():
		return
	_shift_dial = maxf(frequency, 0.0)


## Reactor Station: perform a Shift, setting the Reactor to hold the plasma
## at this frequency in hertz, on the next step. The closer it matches the
## plasma's wobble (plasma_frequency()), and the sooner after a Boundary, the
## better it grades; see the &"shift_result" event.
func shift(frequency: float) -> void:
	if _off_the_crew():
		return
	_disengage_on_command(STATION_REACTOR)
	_plasma.ask_shift(frequency)


## Thermal Station: whether the crew is holding the self-destruct command now.
## Held at an attended Thermal for self_destruct_hold_length() seconds of
## advance() (real time, whatever the time rate), it starts self-destruct;
## let go sooner, the hold starts again from nothing. After it starts, or is
## cancelled, the command must be let go before a new hold counts. Under way,
## self-destruct is the vessel mismanaging itself on purpose: the Drive at
## full power, Quiet Ship off and every bit of heat sent outward through the
## hull, the Stations taken off the crew (their commands are ignored, the
## Reactor's Shifts left to its autopilot) so the hull fails. Stranded, with
## the Head dark, it dumps the emergency store into the hull as heat, the
## pumps stopped; with the store empty it would do nothing, so the hold does
## not count (can_self_destruct()). Raises &"self_destruct_started".
func hold_self_destruct(held: bool) -> void:
	_self_destruct_held = held
	if not held:
		_self_destruct_hold = 0.0
		_self_destruct_needs_release = false


## Thermal Station: cancels a running self-destruct. It is not a one-way
## door: the Stations return to the crew with the settings they had just
## before it started (the Drive's power, the heat split or the pumps, Quiet
## Ship), except that pumps stopped by losing the plasma meanwhile stay
## stopped. Only the wear done, and the store spent, stay. Raises
## &"self_destruct_cancelled".
func cancel_self_destruct() -> void:
	if not _self_destructing:
		return
	_self_destructing = false
	_self_destruct_hold = 0.0
	_self_destruct_needs_release = true
	_power = _crew_settings.power
	_heat_split = _crew_settings.heat_split
	_quiet_ship = _crew_settings.quiet_ship
	_events.append({type = &"self_destruct_cancelled", stranded = stranded()})


## Counts the self-destruct hold over dt real seconds, and starts it once held
## long enough at an attended Thermal. A hold that could do nothing (see
## can_self_destruct()) does not count.
func _tend_self_destruct_hold(dt: float) -> void:
	if _self_destructing or _self_destruct_needs_release or not _self_destruct_held \
			or not attended(STATION_THERMAL) or not can_self_destruct():
		_self_destruct_hold = 0.0
		return
	_self_destruct_hold += dt
	if _self_destruct_hold >= _SELF_DESTRUCT_HOLD_S:
		_start_self_destruct()


## Self-destruct starts: the Stations are off the crew until it is cancelled
## or the hull fails, and their settings are kept for a cancel to restore.
## The command must be let go before another hold counts.
func _start_self_destruct() -> void:
	_self_destructing = true
	_self_destruct_hold = 0.0
	_self_destruct_needs_release = true
	_crew_settings = {power = _power, heat_split = _heat_split, quiet_ship = _quiet_ship}
	_time_rate = 1.0
	_events.append({type = &"self_destruct_started", stranded = stranded()})


## True while self-destruct has the Stations: a Station's command returns
## early on it (the Bore Station's stay the crew's, so the link can still
## send). The one guard for that rule.
func _off_the_crew() -> bool:
	return _self_destructing


# --- Debug commands -------------------------------------------------------
# The developer's shortcuts for testing a dive by hand (the view's numpad
# debug menu). Not crew controls: no Station works them, they ignore
# attendance and self-destruct's hold on the Stations, and each reaches the
# state it names at once rather than on the next step. Every one is named
# debug_* and returns why it could not act, or &"" when it did, so the menu
# can say so: &"dive_over" once the dive is over (surfaced() or dead(), for
# every one of them), &"plasma_lost", &"stranded", &"tail_at_surface",
# &"self_destructing", &"store_empty", &"level", &"no_boundary_ahead". See
# docs/conventions.md, "Debug commands".

## Debug: wears the hull by `amount` (negative mends it), clamped to whole and
## worn through. Worn through, it fails on the next step.
func debug_wear_hull(amount: float) -> StringName:
	if _debug_dive_over():
		return &"dive_over"
	_heat.debug_set_wear(_heat.vessel_wear() + amount)
	return &""


## Debug: brings the hull to the brink of failure: all but worn through, so it
## still holds while it bears its heat, and the first heat it cannot bear (or
## a stranding's soak) fails it within moments.
func debug_hull_to_brink() -> StringName:
	if _debug_dive_over():
		return &"dive_over"
	_heat.debug_set_wear(maxf(_heat.vessel_wear(), _DEBUG_BRINK_WEAR))
	return &""


## Debug: wears the Head by `amount` (negative mends it), clamped to fresh
## and worn through. It narrows the Shift and lowers the relight chance as
## poor Shifts' wear does, but does not itself lose the plasma.
func debug_wear_head(amount: float) -> StringName:
	if _debug_dive_over():
		return &"dive_over"
	_plasma.debug_set_wear(_plasma.head_wear() + amount)
	return &""


## Debug: the plasma goes out here and now, by the plasma's own loss path,
## and what that comes to follows at once: brought home with the tunnel open
## behind, stranded sealed in. Raises &"plasma_lost", then what follows as a
## lost plasma's events. Refused once it is lost.
func debug_lose_plasma() -> StringName:
	if _debug_dive_over():
		return &"dive_over"
	if plasma_lost():
		return &"plasma_lost"
	_plasma.debug_lose(_events, depth(), _distance)
	_share_power()
	_check_stranded()
	if stranded():
		_update_calls()
	return &""


## Debug: strands the Lithocraft here: the whole tunnel behind is sealed (if
## it was not already), then the plasma is lost (debug_lose_plasma()), so the
## rescue must cut down through all of it. Refused while stranded, or until
## the Tail has left the surface, when there is no tunnel behind to seal.
func debug_strand() -> StringName:
	if _debug_dive_over():
		return &"dive_over"
	if stranded():
		return &"stranded"
	if _tail_at <= 0.0:
		return &"tail_at_surface"
	if not _tunnel_sealed:
		_tunnel_sealed = true
		_sealed_metres = _tail_at
		_events.append({type = &"tunnel_sealed", distance = _tail_at})
	return debug_lose_plasma()


## Debug: fills the emergency store, whether or not it is being drawn on.
func debug_refill_store() -> StringName:
	if _debug_dive_over():
		return &"dive_over"
	_stranding.debug_refill()
	return &""


## Debug: the dive ends at the surface now. Under way the Head comes up as
## any surfacing does: the survey aboard sold and the repairs billed; raises
## &"surfaced", then &"paid". Stranded, the rescue arrives now, by the real
## rescue (_rescue()), its line billed as for a rescue that ran its course;
## raises &"rescued", then &"paid".
func debug_surface() -> StringName:
	if _debug_dive_over():
		return &"dive_over"
	if stranded():
		_rescue()
	else:
		_surface()
	return &""


## Debug: runs the dive on `seconds` of simulated time at once, in the steps a
## raised time rate takes. Unlike a raised rate, a Station call does not cut
## it short; it stops only if the dive ends. The Stations are as they were:
## those whose autopilot is engaged steady themselves (the Reactor's
## autopilot Shifts).
func debug_skip(seconds: float) -> StringName:
	if _debug_dive_over():
		return &"dive_over"
	var steps := ceili(seconds / _FAST_STEP_S)
	for i in steps:
		if _surfaced or dead():
			break
		_step(seconds / steps)
	return &""


## Debug: starts self-destruct now, as a full hold at Thermal would, whoever
## is at Thermal. The crew cancel it as ever. Refused while it runs, or when
## it could do nothing (see can_self_destruct()). Raises
## &"self_destruct_started".
func debug_self_destruct() -> StringName:
	if _debug_dive_over():
		return &"dive_over"
	if _self_destructing:
		return &"self_destructing"
	if not can_self_destruct():
		return &"store_empty"
	_start_self_destruct()
	return &""


## Debug: a Shift is due now: the Reactor is mistuned well wide of the
## plasma's wobble, its window just opened, as after crossing a Boundary.
## Refused while the plasma is lost.
func debug_shift_due() -> StringName:
	if _debug_dive_over():
		return &"dive_over"
	if plasma_lost():
		return &"plasma_lost"
	_plasma.debug_mistune(plasma_frequency())
	return &""


## Debug: the Head jumps along the way it points to just past the next
## Boundary ahead (deeper diving, shallower climbing), as if it had cut there
## in no time: the Column it passed is recorded, its features found, the
## tunnel behind made (and sealed in dense rock), the Boundary crossed (a
## Shift comes due), but no heat is made and no survey goes up the link.
## Refused while stranded, travelling level, or with no Boundary ahead.
func debug_next_boundary() -> StringName:
	if _debug_dive_over():
		return &"dive_over"
	if stranded():
		return &"stranded"
	var down := -_direction.y
	if absf(down) < _DEBUG_LEAST_DESCENT:
		return &"level"
	var target := NAN
	for b in _layout.boundary_depths():
		if down > 0.0 and b > depth():
			target = b
			break
		if down < 0.0 and b < depth():
			target = b
	if is_nan(target):
		return &"no_boundary_ahead"
	var beyond := target + signf(down) * _DEBUG_PAST_BOUNDARY_M
	var left := (beyond - depth()) / down
	# In short pieces, each moved as a step moves the Head but taking no time.
	while left > 0.0:
		var piece := minf(left, _DEBUG_TRAVEL_PIECE_M)
		left -= piece
		var depth_before := depth()
		_position += _direction * piece
		_follow_the_head(depth_before, piece, 0.0)
	return &""


## The one guard every debug command starts with: the dive is over (surfaced
## or dead), so none of them acts.
func _debug_dive_over() -> bool:
	return _surfaced or dead()


# --- Time step ------------------------------------------------------------

## Runs dt x time_rate() simulated seconds. At normal rate that is one step of
## dt; faster, it is split into steps no longer than dt or _FAST_STEP_S,
## whichever is longer. A Station call returns the rate to normal and the rest
## of the time is not run.
func advance(dt: float) -> void:
	if dead():
		return
	if _surfaced:
		_tend_checklist(dt)  # Nothing moves, but messages still arrive.
		return
	_tend_self_destruct_hold(dt)
	if _time_rate <= 1.0:
		_step(dt)
		_tend_checklist(dt)
		return
	var total := dt * _time_rate
	var steps := ceili(total / maxf(dt, _FAST_STEP_S))
	for i in steps:
		_step(total / steps)
		_tend_checklist(total / steps)
		if _time_rate <= 1.0:
			return


## Shows the Checklist what happened since it last looked; its own events
## join the rest.
func _tend_checklist(dt: float) -> void:
	var fresh := _events_unseen + _events.slice(_events_checked)
	_events_unseen = []
	_checklist.tend(self, fresh, dt, _events)
	_events_checked = _events.size()


func _step(dt: float) -> void:
	if _surfaced or dead():
		return  # The dive is over; nothing moves until new_dive().
	if stranded():
		_step_stranded(dt)
		return
	_relight_asked = false  # Only a lost plasma can be relit.
	if _self_destructing:
		_mismanage()
	_head_activity = move_toward(_head_activity, 0.0 if _quiet_ship else 1.0,
			_HEAD_SPIN_RATE * dt)
	_plasma.tend(dt, plasma_frequency(), autopilot(STATION_REACTOR) or _self_destructing,
			_heat.hull_heat_share(surroundings_temperature()), _events, depth(), _distance)
	_share_power()
	# Steering heats one side of the Head harder; that share of the Drive's
	# draw goes into heat, not into pushing.
	var power := _drive_draw / (1.0 + _STEER_HEAT * _steering)
	var medium := _layout.medium_at(depth())
	# The grip waves can only push as hard as the wall holds; the rest slips.
	var grip := medium.strength * _GRIP_PER_STRENGTH
	var gripped_power := minf(power, grip)
	_slip = 0.0 if power <= 0.0 else (power - gripped_power) / power
	_speed = _FULL_POWER_SPEED * gripped_power / medium.hardness
	# Every system that draws power makes heat: the Drive (power lost to slip
	# included; less while the Head idles; more while it steers), Thermal and
	# Navigation. A poor Shift's grinding adds a spike.
	# Heat reaches the Column only as far as Thermal's pumps are powered; the
	# rest goes out through the hull.
	_heat.step(power_drawn(), _plasma.heat_spike(), _heat_split, thermal_supplied(),
			surroundings_temperature(), depth(), dt)
	_noise = _head_activity * _HEAD_HUM + _DRIVE_NOISE * power * (1.0 + _slip)
	var depth_before := depth()
	# The Head moves along its arc, turning toward the Drive's settings.
	_steer(_speed, dt)
	_follow_the_head(depth_before, _speed * dt, dt)
	_upload(link_rate() * dt)
	# A hull that fails on the step the Head surfaces is death all the same
	# (_check_stranded() below), not a surfacing.
	if depth_before > 0.0 and depth() <= 0.0 and not _heat.failed():
		_surface()
		return
	if _pulse_pending:
		_pulse_pending = false
		_send_pulse()
	_steady_autopilots(dt)
	_check_stranded()
	if _surfaced or dead():
		return  # Brought home through the open tunnel, or the hull failed.
	_update_calls()


## What follows the Head having moved `travelled` metres along the path from
## `depth_before`, over `dt` seconds: the Column it passed recorded (and the
## observed feature, for the time it spent), the features it cut past found,
## the path remembered, Boundaries crossed or coming, and the tunnel behind.
## The one movement sequence, for a step (_step()) and a debug jump
## (debug_next_boundary(), taking no time).
func _follow_the_head(depth_before: float, travelled: float, dt: float) -> void:
	_record_survey(_distance, _distance + travelled)
	_record_observed_feature(dt, travelled)
	_find_features(depth_before, depth(), travelled)
	_distance += travelled
	_remember_path()
	_watch_boundaries(depth_before)
	_update_tunnel()


# --- State ----------------------------------------------------------------

## Whether a crew member is at this Station; see set_attended().
func attended(station: StringName) -> bool:
	return _attended.get(station, false)


## Whether this Station's autopilot is engaged; see set_autopilot().
func autopilot(station: StringName) -> bool:
	return _autopilot.get(station, false)


## How many times normal the simulation runs now.
func time_rate() -> float:
	return _time_rate


## The fastest the simulation may be run, as a multiple of normal.
func max_time_rate() -> float:
	return _MAX_TIME_RATE


## How urgently this Station calls for attention, 0 (not calling) to 1.
func call_urgency(station: StringName) -> float:
	return _calls[station][1] if _calls.has(station) else 0.0


## Why this Station calls: &"boundary_approaching", &"shift_due",
## &"plasma_lost", &"stranded" (Reactor); &"heat_warning", &"starved" (Thermal);
## &"starved" (Navigation); &"tunnel_about_to_seal", &"feature_in_column"
## (Bore). &"" when not calling.
func call_reason(station: StringName) -> StringName:
	return _calls[station][0] if _calls.has(station) else &""


## The Thermal Station's heat split now: share of heat sent into the Column.
func heat_split() -> float:
	return _heat_split


## Metres below the surface. Increases as the Lithocraft dives.
func depth() -> float:
	return -_position.y


## Degrees. +90 is the Head straight down (diving), 0 level, -90 straight up.
## The pitch of the path itself: the way the Head is cutting.
func pitch() -> float:
	return rad_to_deg(asin(clampf(-_direction.y, -1.0, 1.0)))


## Compass heading in degrees, 0 to 360: 0 along the world's -Z, 90 along +X.
## While the Head points straight up or down, the last heading it had.
func heading_degrees() -> float:
	return _bearing


## The Course's compass heading, degrees 0 to 360; see set_course().
func course_heading() -> float:
	return _course_heading


## The Course's pitch, degrees -90 (climbing) to +90 (diving); see set_course().
func course_pitch() -> float:
	return _course_pitch


## The Course as a unit direction in the world frame (as heading()), for
## drawing it among the points.
func course_direction() -> Vector3:
	return _direction_of(_course_heading, _course_pitch)


## True while the Drive steers toward its own override, not the Course.
func overriding() -> bool:
	return _overriding


## The compass heading the Drive steers toward now: the override's while there
## is one, else the Course's. Degrees 0 to 360.
func steered_heading() -> float:
	return _override_heading if _overriding else _course_heading


## The pitch the Drive steers toward now: the override's while there is one,
## else the Course's. Degrees.
func steered_pitch() -> float:
	return _override_pitch if _overriding else _course_pitch


## Drive power setting, 0 to 1.
func power() -> float:
	return _power


## Radius in metres of the tightest arc the Lithocraft can cut. No command
## turns it tighter, however slow or fast it goes.
func minimum_turn_radius() -> float:
	return _MIN_TURN_RADIUS_M


## The Drive's steering effort setting, 0 to 1; see set_steering_effort().
func steering_effort() -> float:
	return _steering_effort


## How hard the Head is steering now, 0 (heated evenly, going straight) to 1
## (the tightest arc). Builds up and dies away slowly.
func steering() -> float:
	return _steering


## The acceleration the crew feel in the Habitat, in m/s^2 in the Habitat
## frame, pointing the way things fall: the crew's "down". Gravity seen from
## inside the vessel (turns are too wide for their own pull to be felt), plus
## the shudder of a poor Shift's lurch along the Bore.
func felt_acceleration() -> Vector3:
	var th := deg_to_rad(pitch())
	return (TOWARD_UNDERSIDE * cos(th) + TOWARD_HEAD * sin(th)) * _GRAVITY \
			+ TOWARD_HEAD * lurch() * _plasma.shudder()


## How hard a poor Shift's lurch is jolting the vessel now, in m/s^2: sharp at
## the Shift, gone in a moment. 0 after a clean one.
func lurch() -> float:
	return _plasma.lurch()


## Wear on the Head from poor Shifts, 0 (none) to 1. It only accumulates; a
## worn Head holds the plasma less steadily; a rough Shift on a badly worn
## Head can lose it, and one that wears the Head through does.
func head_wear() -> float:
	return _plasma.head_wear()


## True once the plasma has been lost: the Reactor supplies nothing, so the
## vessel halts. It stays lost.
func plasma_lost() -> bool:
	return _plasma.lost()


## Metres per second along the path during the last step.
func speed() -> float:
	return _speed


## Share of Drive power lost to the grip waves slipping on the tunnel wall in
## the last step, 0 (all gripped) to 1 (all slipping).
func slip() -> float:
	return _slip


## The Medium the Lithocraft is in now.
func medium() -> Medium:
	return _layout.medium_at(depth())


## Metres travelled along the path since the dive began.
func distance() -> float:
	return _distance


## The Medium of the Column at the given distance behind the Head, in metres
## (0 = at the Head, increasing toward the Tail). The Column is the uncut
## Medium the Head passed through there, so a Boundary the Head has crossed
## slides back through the Bore at the vessel's speed. Behind the start of the
## dive it is the Medium at the surface.
func column_at(behind_head: float) -> Medium:
	return _medium_at_distance(_distance - behind_head)


## Whether Quiet Ship is set.
func quiet_ship() -> bool:
	return _quiet_ship


## Whether the Bore instruments are shuttered now (while Quiet Ship lasts).
func shuttered() -> bool:
	return _quiet_ship


## The vessel's own noise as Navigation hears it, during the last step. 0 is
## silent (Quiet Ship, Head idle); it grows with the Drive's power and slip.
## Pulses sent while it is loud return less confident points.
func noise() -> float:
	return _noise


## The Reactor's output during the last step: the power the Stations share,
## in the units of set_power(). Lower while the Head idles under Quiet Ship,
## and with an unsteady plasma.
func reactor_output() -> float:
	return _reactor_output


## The Reactor's output with its plasma steady and the Head running: the most
## it supplies, and the whole that each Station's power is read as a share of.
func reactor_full_output() -> float:
	return _REACTOR_FULL_OUTPUT


## How steady the Head's plasma is, 0 (lost) to 1 (steady).
func plasma_stability() -> float:
	return _plasma.stability()


## The frequency, in hertz, of the wobble the load on the Head excites in the
## plasma now. Harder rock loads the Head more and wobbles it faster, so
## crossing a Boundary changes it. A Shift matches it.
func plasma_frequency() -> float:
	return Plasma.frequency_in(_layout.medium_at(depth()))


## The frequency, in hertz, the Reactor is tuned to hold the plasma at: the
## opposing wave it drives. Set by the last Shift.
func plasma_tuning() -> float:
	return _plasma.tuning()


## True while the tuning no longer holds the plasma's wobble (after crossing a
## Boundary, or after a Shift wide of the mark) and a Shift is due.
func shift_due() -> bool:
	return _plasma.due(plasma_frequency())


## Seconds left in the window in which a due Shift loses nothing to lateness;
## 0 when no Shift is due or the window has closed.
func shift_window() -> float:
	return _plasma.window(plasma_frequency())


## How closely a Shift to `frequency` hertz would match the plasma's wobble
## now (plasma_frequency()), 1 (exactly) falling toward 0 the further off: the
## match a Shift is graded on, before lateness. A worn Head reads the same
## frequency as a poorer match. The Reactor screen shows it for the dial.
func shift_match(frequency: float) -> float:
	return _plasma.match_to(frequency, plasma_frequency())


## Seconds the window for a Shift stays open once one is due, on the Head as
## it is now: a worn Head narrows it (and grades a Shift harsher).
func shift_window_length() -> float:
	return _plasma.window_length()


## How hard the Head is running, 0 (idle, Quiet Ship) to 1 (running).
func head_activity() -> float:
	return _head_activity


## Power every Station asked for in the last step. May exceed reactor_output().
func power_requested() -> float:
	return _drive_request + _thermal_request + _navigation_request


## Power every Station was given in the last step. Never exceeds
## reactor_output().
func power_drawn() -> float:
	return _drive_draw + _thermal_draw + _navigation_draw


## Power each Station asked for in the last step. The Drive asks for its power
## setting (less while the Head idles, more while it steers); Thermal for its
## pumps, more the more heat it sends into the Column; Navigation for the
## scanner.
func drive_request() -> float:
	return _drive_request


func thermal_request() -> float:
	return _thermal_request


func navigation_request() -> float:
	return _navigation_request


## Power each Station was given in the last step: its request, unless the
## Reactor ran short (see _share_power() for the rule).
func drive_draw() -> float:
	return _drive_draw


func thermal_draw() -> float:
	return _thermal_draw


func navigation_draw() -> float:
	return _navigation_draw


## Share of its request each Station was given in the last step, 0 to 1. Below
## 1 the Station is starved.
func drive_supplied() -> float:
	return _supplied(_drive_draw, _drive_request)


func thermal_supplied() -> float:
	return _supplied(_thermal_draw, _thermal_request)


func navigation_supplied() -> float:
	return _supplied(_navigation_draw, _navigation_request)


## Navigation's point cloud: every point every pulse has returned this dive,
## oldest first. A copy; changing it does not change the cloud.
func points() -> Array[ScanPoint]:
	return _points.duplicate()


## How many points the cloud holds; cheaper than points() for a view that
## only needs to know whether a pulse has added any.
func point_count() -> int:
	return _points.size()


## Where the Head is in the world frame the point cloud is given in: metres
## from where the dive began, +Y up (so y = -depth), compass heading 0 along -Z.
func head_position() -> Vector3:
	return _position


## The way the Head points in the world frame, unit length: straight down (-Y)
## diving, along -Z travelling level at heading 0.
func heading() -> Vector3:
	return _direction


## The Bore Station's survey so far: one SurveyStretch per completed stretch of
## the path, oldest first. A copy; changing it does not change the record.
func survey() -> Array[SurveyStretch]:
	return _survey.duplicate()


## Every feature of interest the Head has found so far, in the order found,
## including those that have left through the Tail. Copies.
func found_features() -> Array[ColumnFeature]:
	var result: Array[ColumnFeature] = []
	for feature in _features:
		result.append(feature.copy())
	return result


## The features now between the Head and the Tail, nearest the Tail first.
## Copies.
func features_in_column() -> Array[ColumnFeature]:
	var result: Array[ColumnFeature] = []
	for feature in _features:
		if _in_column(feature):
			result.append(feature.copy())
	return result


## The id of the feature the Bore Station is observing, or -1 for none.
func observed_feature() -> int:
	return _observed


## What the survey recorded so far is worth, aboard or already up: every
## completed stretch's SurveyStretch.value(), plus the worth of every feature
## recorded in full. A feature only part recorded adds nothing. What is
## actually paid is paid(), for data that has reached the surface.
func survey_value() -> float:
	return _survey_value


## Events raised since the last call, oldest first, then forgotten. Each is a
## Dictionary with a `type` StringName and its own fields:
##   &"tunnel_sealed" {distance}: the melt has filled the tunnel behind the
##       Tail; the link to the surface is now the slow one.
##   &"boundary_approaching", &"boundary_crossed", &"shift_result",
##       &"plasma_lost" {cause, depth, distance}: see ticket #11
##       (shift_test.gd); `cause` as outcome()'s plasma_lost_by.
##   &"station_call" {station, reason, urgency}: a Station has begun calling,
##       or calls for a new reason (see call_reason()). The time rate returns
##       to normal.
##   &"stranded" {depth, distance, aboard, aboard_stretches, paid,
##       rescue_time, clock}: the plasma was lost while sealed in; the
##       Lithocraft is on the emergency store and a rescue is called.
##       `aboard` is the value of the unsold survey still aboard
##       (`aboard_stretches` stretches of it): the rescue brings it home, the
##       hull failing first loses what the link has not sent. `paid` is kept.
##       `rescue_time` is how long the rescue will take, `clock` the stranding
##       clock (stranding_clock()) as it stands.
##   &"rescued" {depth, distance, rescue_time}: the rescue reached the
##       Lithocraft at `depth` after `rescue_time` seconds and brought the
##       crew and everything aboard to the surface. Followed by &"paid", whose
##       `rescue` line is the rescue's cost. The dive is over as after
##       surfacing (surfaced() is true); new_dive() starts another.
##   &"relight_result" {outcome, chance, spent, store}: a relight asked for
##       while stranded. `outcome` &"lit" (the stranding is over), &"failed"
##       (the pulse spent, still stranded) or &"refused" (the store held less
##       than the pulse; nothing spent). `chance` it had, `spent` from the
##       store, `store` left.
##   &"surfaced" {distance}: the Head has come back up to the surface; the
##       dive is over.
##   &"brought_home" {depth, distance}: the plasma was lost with the tunnel
##       still open, so the crew and the Lithocraft were brought home up it
##       from `depth`. Followed by &"paid". The dive is over as after
##       surfacing (surfaced() is true); new_dive() starts another.
##   &"paid" {arrival, amount, by_link, carried_home, hull_repair,
##       head_repair, rescue, covered, stretches, metres, mean_quality, features,
##       feature_worth, lost_to_quality, by_medium, total_paid}: right after
##       the Lithocraft reaches the surface (`arrival`, the &"surfaced",
##       &"rescued" or &"brought_home" event just raised), what this dive was
##       paid (`amount` = `by_link`, paid while under way, + `carried_home`,
##       the survey sold at the surface, - `hull_repair` and `head_repair`,
##       the dive's wear repaired in proportion to it, - `rescue`, a rescue in
##       proportion to how long it took, 0 when there was none, +
##       `covered`, what those bills came to beyond what the dive earned,
##       which is not charged: `amount` is never below 0) and why:
##       Column recorded and its length-weighted quality, features recorded
##       and their worth, the value heat and shuttering took off pristine
##       records, and pay per Medium name. `total_paid` is paid() across
##       every dive.
##   &"hull_failed" {cause, depth, distance, lost, lost_stretches, rebuy,
##       rebuy_charged, amount, total_paid}: heat wore the hull through and
##       the crew died at `depth`. `cause` is &"self_destruct" when it ran
##       to the end, else &"heat". The unsold survey is lost (`lost`, of
##       `lost_stretches` stretches); what reached the surface stays paid
##       (`amount` this dive, `total_paid` across every dive). `rebuy` is
##       what replacing the Lithocraft costs; `rebuy_charged` what was taken
##       for it, nothing while there is no balance to take it from. The dive
##       is over (dead() is true); new_dive() starts another.
##   &"new_dive" {paid}: new_dive() has the Lithocraft ready at the surface.
##   &"autopilot_off" {station, cause}: that Station's autopilot disengaged;
##       `cause` AUTOPILOT_OFF_BY_COMMAND (a crew command changed its
##       setting) or AUTOPILOT_OFF_BY_SWITCH (the crew switched it off).
##   &"course_plotted" {heading, pitch}: Navigation plotted the Course.
##   &"pulse_sent" {quiet_ship}: Navigation's pulse went out, under Quiet
##       Ship or not.
##   &"orders_read": see read_orders().
##   &"checklist_step", &"checklist_phase", &"goal_achieved",
##       &"surface_message": the Scenario's progress; see Checklist.tend().
##   &"self_destruct_started" {stranded}, &"self_destruct_cancelled"
##       {stranded}: the crew held the command long enough at Thermal, or
##       cancelled it (see hold_self_destruct()); `stranded` whether with the
##       Head dark.
func take_events() -> Array[Dictionary]:
	var taken := _events
	_events_unseen.append_array(_events.slice(_events_checked))
	_events = []
	_events_checked = 0
	return taken


## The survey data aboard that has not reached the surface, stretches and
## records of features alike, in the order recorded. Unpaid for. A copy.
func unsold_survey() -> Array[SurveyStretch]:
	return _waiting.duplicate()


## What the survey data aboard would be paid once up: the sum of
## unsold_survey()'s values.
func unsold_value() -> float:
	var total := 0.0
	for stretch in _waiting:
		total += stretch.value()
	return total


## True once the plasma has been lost while sealed in: the Lithocraft cannot
## move and no tunnel leads up. Time runs on the emergency store until the
## Head is relit, the rescue arrives (rescue_time()) or heat soaking in fails
## the hull (stranding_clock()).
func stranded() -> bool:
	return _stranding.stranded()


## True once heat has worn the hull through (hull_integrity() 0): the crew is
## dead, the unsold survey lost, and the dive over; time no longer advances
## it. new_dive() starts another in a rebought Lithocraft.
func dead() -> bool:
	return _stranding.dead()


## True while self-destruct runs (see hold_self_destruct()), until it is
## cancelled or the hull fails.
func self_destructing() -> bool:
	return _self_destructing


## Whether self-destruct would do anything if started now, so whether a hold
## counts: not once the dive is over, nor stranded with the emergency store
## empty, when there is nothing left to dump into the hull.
func can_self_destruct() -> bool:
	if _surfaced or dead():
		return false
	return not (stranded() and emergency_store() <= 0.0)


## Why the crew died: &"heat" or &"self_destruct" (as the &"hull_failed"
## event's `cause`), or &"" while they live.
func cause_of_death() -> StringName:
	return _death_cause


## How the dive ended and why, in one Dictionary, for the outcome screen:
##   ending: &"under_way" (not over yet), &"surfaced" (under its own power),
##       &"brought_home" (the plasma lost with the tunnel open), &"rescued" or
##       &"dead".
##   cause: why it ended so. Dead: &"heat" or &"self_destruct" (as
##       cause_of_death()). Brought home or rescued: why the plasma was lost
##       (as plasma_lost_by). Surfaced or under way: &"".
##   plasma_lost_by: why the plasma is lost, &"disrupted" (a rough Shift on a
##       badly worn Head), &"worn_through" (a poor Shift wore the Head through)
##       or &"debug"; &"" while it holds (or was relit).
##   stranded_for: seconds the crew was stranded: rescued, what the rescue
##       took; dead, how long they waited before the hull failed; stranded
##       under way, so far; otherwise 0.
##   depth: where the dive ended, in metres (0 surfaced; the depth now under
##       way).
## It holds until new_dive().
func outcome() -> Dictionary:
	if not _outcome.is_empty():
		return _outcome.duplicate()
	return _ended(&"under_way", &"", _stranding.stranded_for() if stranded() else 0.0, depth())


## An outcome() for this `ending`, its `cause`, the seconds stranded and the
## depth it ended at; the plasma's state is read now.
func _ended(ending: StringName, cause: StringName, stranded_for: float,
		at_depth: float) -> Dictionary:
	return {ending = ending, cause = cause, plasma_lost_by = _plasma.lost_by(),
			stranded_for = stranded_for, depth = at_depth}


## How far the crew has held the self-destruct command toward starting it, 0
## (not held) to 1 (started). For the Thermal screen and the groans.
func self_destruct_hold() -> float:
	return clampf(_self_destruct_hold / _SELF_DESTRUCT_HOLD_S, 0.0, 1.0)


## Seconds the self-destruct command must be held to start it.
func self_destruct_hold_length() -> float:
	return _SELF_DESTRUCT_HOLD_S


## True once the Head has come back up to the surface, under its own power or
## brought back through the open tunnel after losing the plasma, and the
## survey has been sold: the dive is over and time no longer advances it.
## new_dive() starts another.
func surfaced() -> bool:
	return _surfaced


## True once the plasma is lost and the Lithocraft has fallen back on the
## emergency store for power: the link, a relight (and anything else that runs
## with the Head dark) draw on it. False again once the Head is relit. The
## same as plasma_lost(), named for what the store's gauges ask.
func on_emergency_store() -> bool:
	return plasma_lost()


## Energy left in the emergency store, in the units of set_power() x seconds.
## Full at the start of a dive; spent only once the plasma is lost.
func emergency_store() -> float:
	return _stranding.store()


## Energy the emergency store holds when full.
func emergency_store_capacity() -> float:
	return _stranding.store_capacity()


## Energy a relight's pulse takes from the emergency store.
func relight_cost() -> float:
	return _plasma.relight_cost()


## The share of a full emergency store a relight's pulse takes, 0 to 1.
func relight_store_share() -> float:
	return relight_cost() / emergency_store_capacity()


## The chance a relight strikes the plasma on the Head as it is now, 0 to 1:
## a healthy Head almost always relights; the odds fall with head_wear().
func relight_chance() -> float:
	return _plasma.relight_chance()


## True once the tunnel behind has been filled somewhere, so no continuous open
## tunnel reaches the surface. It stays sealed for the rest of the dive.
func tunnel_sealed() -> bool:
	return _tunnel_sealed


## Seconds until a rescue reaches the Lithocraft. While stranded it counts
## down from the stranding; under way, what a rescue would take if the plasma
## were lost now. A fast run down the open tunnel behind plus a slow cut
## through the length the melt sealed, so a longer sealed length is slower.
func rescue_time() -> float:
	if stranded():
		return _stranding.rescue_left()
	return Stranding.rescue_time(_tail_at - _sealed_metres, _sealed_metres)


## Metres from the Head back to the Tail, where the tunnel behind is made.
func vessel_length() -> float:
	return _VESSEL_LENGTH_M


## The porosity below which the Medium the Tail leaves fills the tunnel in.
## For instruments that show the porosity trend against it.
func seal_porosity() -> float:
	return _SEAL_POROSITY


## How fast survey data goes up to the surface now, in metres of survey per
## second. Light up the open glass-lined tunnel is fast; once sealed, it is
## sound through the rock: a trickle that follows how well the Medium the
## Lithocraft is in carries sound. 0 while the link is stopped
## (set_uploading()), or stranded with the emergency store spent.
func link_rate() -> float:
	if not _uploading or (stranded() and _stranding.store() <= 0.0):
		return 0.0
	return link_capacity()


## How fast the link could carry, in metres of survey per second, whether or
## not it is sending: light up the open tunnel, a trickle of sound through
## sealed rock. Surface control's messages come down at this rate.
func link_capacity() -> float:
	if not _tunnel_sealed:
		return _FAST_LINK_RATE
	return _SLOW_LINK_RATE * medium().sound_carrying


## What this dive has been paid so far: by the link under way, and at the
## surface for what was carried home.
func paid_this_dive() -> float:
	return _paid - _paid_before_dive


## The Reactor's Shift dial, in hertz; see set_shift_dial().
func shift_dial() -> float:
	return _shift_dial


## The title of the Scenario being played, "" for none.
func scenario_title() -> String:
	return _checklist.title()


## The Orders' goals in order, each {id, text, achieved}.
func orders() -> Array[Dictionary]:
	return _checklist.orders()


## The Checklist's phases in order, each {title, steps}; each step {id, text,
## station (&"" for none), action (the key-map action that does it, &"" for
## none), state (STEP_PENDING, STEP_DONE or STEP_MISSED)}.
func checklist() -> Array[Dictionary]:
	return _checklist.phases()


## The index of the phase now running in checklist().
func checklist_phase() -> int:
	return _checklist.phase()


## The next step to do, as a step of checklist() plus {phase, step} indices,
## or {} when none is left.
func next_step() -> Dictionary:
	return _checklist.next_step()


## Surface control's messages that have arrived this dive, oldest first.
func surface_messages() -> Array[String]:
	return _checklist.arrived()


## How many of surface control's messages are still coming down the link.
func messages_on_the_way() -> int:
	return _checklist.on_the_way()


## What has been paid so far for survey data that has reached the surface.
## Data still aboard earns nothing.
func paid() -> float:
	return _paid


## Whether the link sends the survey aboard up; see set_uploading().
func uploading() -> bool:
	return _uploading


## The upload priority in force, one of the UPLOAD_* priorities.
func upload_priority() -> StringName:
	return _upload_priority


## The survey stretches whose data has reached the surface and been paid for,
## in the order they arrived. A copy.
func uploaded_survey() -> Array[SurveyStretch]:
	return _uploaded.duplicate()


## Heat made in the last step by everything that draws power, per second.
func heat_produced() -> float:
	return _heat.produced()


## Heat sent into the Column in the last step, per second.
func heat_to_column() -> float:
	return _heat.to_column()


## Heat sent outward through the hull in the last step, per second.
func heat_outward() -> float:
	return _heat.outward()


## The hull's temperature in kelvin. Heat sent outward warms it until it is hot
## enough above the surrounding Medium to shed that heat.
func vessel_temperature() -> float:
	return _heat.vessel_temperature()


## Temperature in kelvin of the Medium around the vessel now: the Medium's own
## temperature plus the planet's warming with depth, so it rises even within
## one Medium and the hull has less room to shed heat the deeper it goes.
func surroundings_temperature() -> float:
	return Heat.surroundings(_layout.medium_at(depth()), depth())


## Damage heat has done to the vessel so far, 0 (none) to 1. It only grows
## while the hull is hotter than it can bear.
func vessel_wear() -> float:
	return _heat.vessel_wear()


## What is left of the hull, 1 (whole) to 0 (failed): heat wear taken away.
## At 0 the hull fails and the crew dies.
func hull_integrity() -> float:
	return 1.0 - _heat.vessel_wear()


## How fast the hull is losing integrity now, per second: 0 while it bears its
## heat; above its rated temperature, faster the further over and the deeper
## down, where the rock's pressure stresses it harder.
func hull_creep_rate() -> float:
	return _heat.creep_rate()


## True while heat is wearing the hull now (hull_creep_rate() above 0) and
## time runs: stranded too, as heat soaks in with the Head dark; false once
## the crew is dead or surfaced, when advance() no longer steps. The view's
## sparks and shake play exactly while this holds.
func hull_taking_damage() -> bool:
	return _heat.taking_damage() and not (dead() or surfaced())


## The stress the rock's pressure puts on the hull now, 1 at the surface and
## greater deeper down. It multiplies how fast an overheated hull creeps, and
## how hard the hull groans.
func hull_stress() -> float:
	return _heat.stress()


## True while heat threatens the vessel: the hull is close to the temperature
## at which heat damages it, or the heat now sent outward will take it past
## that if nothing changes. Comes on before any damage is done.
func heat_warning() -> bool:
	return _heat.warning()


## Hull temperature in kelvin at which heat_warning() comes on regardless of
## where the hull is heading. For gauges.
func hull_warning_temperature() -> float:
	return _heat.warning_temperature()


## Hull temperature in kelvin above which heat wears the vessel. For gauges.
func hull_damage_temperature() -> float:
	return _heat.damage_temperature()


## The stranding clock: seconds until heat soaking in from the melt and rock
## round the vessel fails the hull with the Head dark. Shorter deeper, where
## the rock is hotter and presses harder, and the more worn the hull. While
## stranded it runs live, with Thermal's pumps cooling at the heat split for
## as long as the emergency store lasts (the link, and a running
## self-destruct dumping it into the hull, drawing on it too, as
## _step_stranded() draws them); under way, what it would be if the plasma
## were lost now, the pumps stopped. INF if the hull would bear the heat for
## ever.
func stranding_clock() -> float:
	if dead():
		return 0.0
	if not stranded() or (_heat_split <= 0.0 and _dump_draw() <= 0.0):
		return _heat.time_to_fail(surroundings_temperature(), depth(), 0.0, 0.0)
	var lasts := _stranding.store() / (_dump_draw() + _cooling_draw() + _link_draw())
	return _heat.time_to_fail(surroundings_temperature(), depth(), _heat_split, lasts,
			_dump_draw())


# --- Steering -------------------------------------------------------------

## The direction the Drive steers toward, in the world frame.
func _wanted_direction() -> Vector3:
	return _direction_of(steered_heading(), steered_pitch())


## A unit vector in the world frame for a compass heading and pitch, degrees.
static func _direction_of(heading_degrees: float, pitch_degrees: float) -> Vector3:
	var p := deg_to_rad(pitch_degrees)
	var h := deg_to_rad(heading_degrees)
	return Vector3(cos(p) * sin(h), -sin(p), -cos(p) * cos(h)).normalized()


## Turns the Head toward the Course (or the Drive's override) for dt seconds at
## this speed, and moves it along the arc. The steering builds toward what the
## remaining turn needs, no harder than the Drive's effort, at a limited rate,
## and the path bends by at most speed / minimum radius radians per second, so
## a stopped vessel cannot turn and none turns tighter than its minimum arc. The Head only ever moves the way it points.
func _steer(speed: float, dt: float) -> void:
	var wanted := _wanted_direction()
	var remaining := _direction.angle_to(wanted)
	var effort := minf(_steering_effort, _AUTOPILOT_STEERING_EFFORT) \
			if autopilot(STATION_DRIVE) else _steering_effort
	var needed := clampf(rad_to_deg(remaining) / _STEER_EASE_DEG, 0.0, effort)
	_steering = move_toward(_steering, needed, _STEER_RESPONSE * dt)
	var turn := minf(remaining, _steering * speed / _MIN_TURN_RADIUS_M * dt)
	var before := _direction
	if turn > 0.0:
		if turn >= remaining:
			_direction = wanted
		else:
			_direction = _direction.rotated(_turn_axis(wanted), turn).normalized()
	# Along the arc: the chord points halfway between the two directions and
	# is a little shorter than the arc.
	var travelled := speed * dt
	if turn > 1e-9:
		var chord := 2.0 * sin(turn / 2.0) / turn
		_position += (before + _direction).normalized() * travelled * chord
	else:
		_position += _direction * travelled
	if Vector2(_direction.x, _direction.z).length() > 1e-4:
		_bearing = fposmod(rad_to_deg(atan2(_direction.x, -_direction.z)), 360.0)


## The axis to turn about to bring the Head round toward wanted. A straight
## about-turn goes round sideways when the Head is not vertical, and over the
## bearing when it points straight up or down.
func _turn_axis(wanted: Vector3) -> Vector3:
	var axis := _direction.cross(wanted)
	if axis.length() > 1e-6:
		return axis.normalized()
	var sideways := Vector3.UP - _direction * _direction.dot(Vector3.UP)
	if sideways.length() > 1e-4:
		return sideways.normalized()
	var h := deg_to_rad(_bearing)
	return Vector3(cos(h), 0.0, sin(h)) * signf(-_direction.y)


## Adds the Head's place to the remembered path, merging short or straight
## pieces so a long dive stays small.
func _remember_path() -> void:
	var last := _path_distances.size() - 1
	var piece := _distance - _path_distances[last]
	if piece <= 0.0:
		return
	var mergeable := false
	if last > 0:
		var previous := _path_distances[last] - _path_distances[last - 1]
		var previous_slope := (_path_depths[last] - _path_depths[last - 1]) / previous
		var slope := (depth() - _path_depths[last]) / piece
		mergeable = previous < _PATH_SAMPLE_M or absf(slope - previous_slope) < 1e-9
	if mergeable:
		_path_distances[last] = _distance
		_path_depths[last] = depth()
	else:
		_path_distances.append(_distance)
		_path_depths.append(depth())


## Depth of the path at a distance along it. Behind the start of the dive the
## path is taken as straight down from the surface.
func _depth_at_distance(along_path: float) -> float:
	if along_path <= 0.0:
		return along_path
	var last := _path_distances.size() - 1
	if along_path >= _path_distances[last]:
		return _path_depths[last]
	var i := _path_distances.bsearch(along_path, false)
	var d0 := _path_distances[i - 1]
	var d1 := _path_distances[i]
	return lerpf(_path_depths[i - 1], _path_depths[i], (along_path - d0) / (d1 - d0))


# --- Power ----------------------------------------------------------------

## Shares the Reactor's output among the Stations for this step. The shortfall
## rule: when the Stations ask for more than the Reactor supplies, they are
## served in a fixed order, Navigation, then Thermal, then the Drive, each
## given all it asks for while power lasts, the next whatever is left. So
## asking more of the Drive only throttles the Drive, while Thermal or
## Navigation asking more takes power from the Drive, and only a Reactor short
## of even their needs starves them.
func _share_power() -> void:
	_reactor_output = _plasma.stability() * lerpf(_REACTOR_IDLE_OUTPUT,
			_REACTOR_FULL_OUTPUT, _head_activity)
	_navigation_request = _NAVIGATION_DRAW
	_thermal_request = _THERMAL_BASE_DRAW + _THERMAL_COLUMN_DRAW * _heat_split
	_drive_request = _power * _head_activity * (1.0 + _STEER_HEAT * _steering)
	var left := _reactor_output
	_navigation_draw = minf(_navigation_request, left)
	left -= _navigation_draw
	_thermal_draw = minf(_thermal_request, left)
	left -= _thermal_draw
	_drive_draw = minf(_drive_request, left)


static func _supplied(drawn: float, requested: float) -> float:
	return 1.0 if requested <= 0.0 else drawn / requested


# --- Column features ------------------------------------------------------

## Records the observed feature for as much of this step as it spends between
## the Head and the Tail. The slower the vessel, the longer it stays.
func _record_observed_feature(dt: float, travelled: float) -> void:
	if _observed < 0:
		return
	var feature := _features[_observed]
	var behind_before := _distance - feature.at
	var behind_after := behind_before + travelled
	var seconds_inside := 0.0
	if travelled <= 0.0:
		seconds_inside = dt if _in_column(feature) else 0.0
	else:
		var inside := minf(behind_after, _VESSEL_LENGTH_M) - maxf(behind_before, 0.0)
		seconds_inside = maxf(inside, 0.0) / travelled * dt
	var was_recorded := feature.is_recorded()
	feature.recorded = minf(1.0,
			feature.recorded + seconds_inside * _recording_quality() / _FEATURE_RECORD_S)
	if feature.is_recorded() and not was_recorded:
		_queue_feature_record(feature)
	if behind_after > _VESSEL_LENGTH_M:
		_observed = -1


## A feature recorded in full joins the survey data waiting for the link, as an
## entry of its own worth feature.worth, sent and paid for like a stretch.
func _queue_feature_record(feature: ColumnFeature) -> void:
	var record := SurveyStretch.feature_record(feature,
			_medium_at_distance(feature.at).name)
	_waiting.append(record)
	_sending = null  # It may now be the one to send first.
	_survey_value += record.value()


## Adds the features the Head cut past in this step, placed along the path
## where it met them.
func _find_features(depth_before: float, depth_after: float, travelled: float) -> void:
	for entry in _layout.features_between(depth_before, depth_after):
		var template: ColumnFeature = entry[1]
		if _found_templates.has(template):
			continue
		_found_templates[template] = true
		var feature := template.copy()
		feature.id = _features.size()
		var share := inverse_lerp(depth_before, depth_after, entry[0])
		feature.at = _distance + travelled * share
		_features.append(feature)


func _in_column(feature: ColumnFeature) -> bool:
	var behind := _distance - feature.at
	return behind >= 0.0 and behind <= _VESSEL_LENGTH_M


# --- Boundaries -----------------------------------------------------------

## Raises boundary_crossed when this step took the Head into another Medium,
## and boundary_approaching once for each Boundary that comes within reach
## ahead in the direction the Head's depth is changing.
func _watch_boundaries(depth_before: float) -> void:
	var before := _layout.medium_at(depth_before)
	var after := _layout.medium_at(depth())
	if after != before:
		_announced_boundary = NAN
		_events.append({type = &"boundary_crossed", from = before.name, to = after.name,
				depth = depth(), distance = _distance})
		_on_boundary_crossed(before, after)
	if is_equal_approx(depth(), depth_before):
		return
	var downward := depth() > depth_before
	var ahead := NAN
	for b in _layout.boundary_depths():
		var gap := b - depth() if downward else depth() - b
		if gap > 0.0 and gap <= _BOUNDARY_APPROACH_M and (is_nan(ahead) or gap < absf(ahead - depth())):
			ahead = b
	if is_nan(ahead) or ahead == _announced_boundary:
		return
	_announced_boundary = ahead
	var beyond := _layout.medium_at(ahead + (0.01 if downward else -0.01))
	_events.append({type = &"boundary_approaching", from = after.name, to = beyond.name,
			depth = ahead, depth_to_go = absf(ahead - depth())})


## The load on the Head has changed, so the plasma's wobble has too: a new
## window for the Shift opens.
func _on_boundary_crossed(from: Medium, to: Medium) -> void:
	_plasma.open_window()
	if not _tunnel_sealed and to.porosity < _SEAL_POROSITY and from.porosity >= _SEAL_POROSITY:
		_seal_coming_at = _distance


# --- Autopilots and calls -------------------------------------------------

## The steadying rules of Stations whose autopilot is engaged (the Reactor's
## is in Plasma.tend(), the Drive's gentle steering in _steer()). Steady
## conditions leave every setting as it was. The Drive backs its power off to
## what the wall can grip once the grip waves slip: the slipped share only
## made heat and noise.
func _steady_autopilots(dt: float) -> void:
	if _self_destructing:
		return  # Self-destruct holds every setting.
	if autopilot(STATION_DRIVE) and _slip > 0.0:
		_power *= 1.0 - _slip
	if autopilot(STATION_THERMAL) and heat_warning():
		_heat_split = minf(1.0, _heat_split + _AUTOPILOT_SPLIT_RATE * dt)


## Works out which Stations call, why and how urgently, from the state after
## this step. A call that begins, or changes reason, is announced and returns
## the time rate to normal.
func _update_calls() -> void:
	var calls := {}
	_reactor_call(calls)
	if heat_warning():
		var over := (vessel_temperature() - hull_warning_temperature()) \
				/ (hull_damage_temperature() - hull_warning_temperature())
		_offer_call(calls, STATION_THERMAL, &"heat_warning", _urgency(_HEAT_WARNING_CALL, over))
	for starved in [[STATION_THERMAL, thermal_supplied()], [STATION_NAVIGATION, navigation_supplied()]]:
		if starved[1] < 1.0:
			_offer_call(calls, starved[0], &"starved", _urgency(_STARVED_CALL, 1.0 - starved[1]))
	if _tunnel_sealed:
		_seal_coming_at = NAN
	elif not is_nan(_seal_coming_at):
		var tail_to_go := (_distance - _seal_coming_at) / _VESSEL_LENGTH_M
		_offer_call(calls, STATION_BORE, &"tunnel_about_to_seal",
				_urgency(_SEAL_COMING_CALL, tail_to_go))
	if _observed < 0:
		for feature in _features:
			if not feature.is_recorded() and _in_column(feature):
				var to_tail := (_distance - feature.at) / _VESSEL_LENGTH_M
				_offer_call(calls, STATION_BORE, &"feature_in_column",
						_urgency(_FEATURE_CALL, to_tail))
	for station in calls:
		var was: StringName = _calls[station][0] if _calls.has(station) else &""
		if calls[station][0] != was:
			_events.append({type = &"station_call", station = station,
					reason = calls[station][0], urgency = calls[station][1]})
			if not _self_destructing:
				_time_rate = 1.0
	_calls = calls


func _reactor_call(calls: Dictionary) -> void:
	if stranded():
		_offer_call(calls, STATION_REACTOR, &"stranded", _EMERGENCY_CALL_URGENCY)
	elif plasma_lost():
		_offer_call(calls, STATION_REACTOR, &"plasma_lost", _EMERGENCY_CALL_URGENCY)
	elif shift_due():
		_offer_call(calls, STATION_REACTOR, &"shift_due", _urgency(_SHIFT_DUE_CALL,
				_plasma.overdue_share()))
	elif not is_nan(_announced_boundary):
		var to_go := absf(_announced_boundary - depth()) / _BOUNDARY_APPROACH_M
		_offer_call(calls, STATION_REACTOR, &"boundary_approaching",
				_urgency(_BOUNDARY_AHEAD_CALL, 1.0 - to_go))


## A call's urgency from its range (x when it begins, y at its worst) and how
## far along that range things have gone, 0 to 1.
static func _urgency(call_range: Vector2, share: float) -> float:
	return lerpf(call_range.x, call_range.y, clampf(share, 0.0, 1.0))


## Keeps the most urgent call for each Station.
static func _offer_call(calls: Dictionary, station: StringName, reason: StringName,
		urgency: float) -> void:
	if not calls.has(station) or calls[station][1] < urgency:
		calls[station] = [reason, urgency]


# --- Self-destruct --------------------------------------------------------

## Self-destruct under way: the vessel mismanaging itself on purpose, the
## Reactor at full power with all heat outward (the design record's intent).
## The Reactor has no power setting of its own: it runs at full output while
## the Head runs (Quiet Ship off) and the plasma holds, and the Drive at full
## beside the other Stations' base loads draws nearly all of it, all of which
## becomes heat. Thermal sends all that heat outward through the hull. Should the
## plasma be lost meanwhile and the Lithocraft strand, self-destruct runs on
## as the stranded dump (_step_stranded()).
func _mismanage() -> void:
	_power = 1.0
	_quiet_ship = false
	_heat_split = 0.0


# --- Stranding -----------------------------------------------------------

## A relight, asked for while stranded: refused if the store cannot pay its
## pulse; otherwise the pulse is spent and the plasma lights or not by its
## chance. Lit, the stranding is over. Raises &"relight_result".
func _try_relight() -> void:
	var cost := relight_cost()
	var chance := relight_chance()
	var outcome := &"refused"
	if _stranding.pay(cost):
		outcome = &"failed"
		if _plasma.relight(plasma_frequency(), _relight_random.randf()):
			outcome = &"lit"
			_stranding.relit()
	_events.append({type = &"relight_result", outcome = outcome, chance = chance,
			spent = 0.0 if outcome == &"refused" else cost, store = emergency_store()})


## Carries out what losing the plasma or the hull comes to, as the Stranding
## decides: death when the hull fails (_die()), stranded while sealed in
## (_strand()), or brought home through the open tunnel (_bring_home()).
func _check_stranded() -> void:
	var outcome := _stranding.check(plasma_lost(), _tunnel_sealed, _heat.failed())
	if outcome == Stranding.DIED:
		_die()
	elif outcome == Stranding.STRANDED:
		_strand()
	elif outcome == Stranding.BROUGHT_HOME:
		_bring_home()


## Losing the plasma while sealed in strands the Lithocraft, on the emergency
## store, and calls the rescue. The survey data not yet up the link stays
## aboard: the link can still send it, on the store, as insurance against the
## hull failing before the rescue arrives.
func _strand() -> void:
	_speed = 0.0
	_slip = 0.0
	# Thermal's pumps stop with the Head; the crew restarts them on the store.
	# A self-destruct running on as the dump would restore them on a cancel,
	# so the pumps it keeps for the crew stop too.
	_heat_split = 0.0
	if _self_destructing:
		_crew_settings.heat_split = 0.0
	_stranding.call_rescue(Stranding.rescue_time(_tail_at - _sealed_metres, _sealed_metres))
	_events.append({type = &"stranded", depth = depth(), distance = _distance,
			aboard = unsold_value(), aboard_stretches = _stretches_aboard(), paid = _paid,
			rescue_time = rescue_time(), clock = stranding_clock()})


## A step while stranded: nothing moves and the Head is dark. Heat soaks into
## the hull from the melt and rock round it, and Thermal's pumps carry it into
## the Column at the heat split, on the emergency store. The link sends the
## survey aboard on the store too, as far as it pays for both. The hull worn
## through, the crew dies.
func _step_stranded(dt: float) -> void:
	if _relight_asked:
		_relight_asked = false
		_try_relight()
		if not stranded():
			_update_calls()
			return
	var dumped := 0.0
	if _self_destructing:
		_heat_split = 0.0  # The pumps stop: every bit of the store's heat stays in.
		dumped = _stranding.draw(_dump_draw() * dt) / dt
	var cooling := 0.0
	var cooling_draw := _cooling_draw() * dt
	if cooling_draw > 0.0:
		cooling = _heat_split * _stranding.draw(cooling_draw) / cooling_draw
	_heat.soak(surroundings_temperature(), cooling, depth(), dt, dumped)
	var link_draw := _link_draw() * dt
	if link_draw > 0.0:
		_upload(link_rate() * dt * _stranding.draw(link_draw) / link_draw)
	_check_stranded()
	if dead():
		return
	if _stranding.wait_for_rescue(dt):
		_rescue()
		return
	_update_calls()


## What self-destruct dumps from the emergency store into the hull per second
## while stranded, else 0. Drawn first. The one reckoning of it:
## _step_stranded() draws it and stranding_clock() counts on it.
func _dump_draw() -> float:
	return _SELF_DESTRUCT_DUMP if _self_destructing and stranded() else 0.0


## What Thermal's pumps draw from the emergency store per second at the heat
## split while stranded. The one reckoning of it: _step_stranded() draws it
## and stranding_clock() counts on it.
func _cooling_draw() -> float:
	return _THERMAL_COLUMN_DRAW * _heat_split


## What the link draws from the emergency store per second while stranded:
## its draw while it has survey aboard to send, else 0. The one reckoning of
## it: _step_stranded() draws it and stranding_clock() counts on it.
func _link_draw() -> float:
	if _waiting.is_empty() or link_rate() <= 0.0:
		return 0.0
	return _LINK_DRAW


## The hull has failed and the crew is dead. The survey data not yet up the
## link is lost with them; what reached the surface stays paid. The rebuy is
## shown but not charged: there is no balance yet to take it from. Raises
## &"hull_failed".
func _die() -> void:
	var lost_stretches := _stretches_aboard()
	var lost := _lose_unsold()
	var cause := &"self_destruct" if _self_destructing else &"heat"
	_death_cause = cause
	_outcome = _ended(&"dead", cause, _stranding.stranded_for(), depth())
	_self_destructing = false
	_speed = 0.0
	_slip = 0.0
	_calls = {}
	_time_rate = 1.0
	_events.append({type = &"hull_failed", cause = cause, depth = depth(), distance = _distance,
			lost = lost, lost_stretches = lost_stretches, rebuy = _stranding.rebuy(),
			rebuy_charged = 0.0, amount = paid_this_dive(), total_paid = _paid})


## How many stretches of Column the survey aboard holds, feature records aside.
func _stretches_aboard() -> int:
	return _waiting.filter(
			func(s: SurveyStretch) -> bool: return not s.is_feature_record()).size()


## Discards the survey data still aboard, which never reached the surface, and
## returns its value.
func _lose_unsold() -> float:
	var lost_value := unsold_value()
	var lost := {}
	for stretch in _waiting:
		lost[stretch] = true
	_survey_value -= lost_value
	_survey.assign(_survey.filter(func(s: SurveyStretch) -> bool: return not lost.has(s)))
	_waiting.clear()
	_sent.clear()
	_sending = null
	return lost_value


## The plasma is lost but the tunnel behind is open all the way up: the
## Lithocraft is brought home up it to the surface with the crew and everything
## aboard, as after surfacing (_come_home()). Raises &"brought_home", then
## &"paid".
func _bring_home() -> void:
	var from_depth := depth()
	_position = Vector3.ZERO
	_come_home({type = &"brought_home", depth = from_depth, distance = _distance})


## The rescue has reached the stranded Lithocraft and brought it, the crew
## and everything aboard back up to the surface, as after surfacing
## (_come_home()), the rescue billed in proportion to how long it took. Raises
## &"rescued", then &"paid".
func _rescue() -> void:
	var from_depth := depth()
	var took := _stranding.rescue_took()
	_stranding.rescued()
	_position = Vector3.ZERO
	_come_home({type = &"rescued", depth = from_depth, distance = _distance,
			rescue_time = took}, took)


# --- Surfacing and the sale -----------------------------------------------

## The Head has come back up to the surface under its own power
## (_come_home()). Raises &"surfaced", then &"paid".
func _surface() -> void:
	_position.y = 0.0  # The Head rests at the surface.
	_come_home({type = &"surfaced", distance = _distance})


## The Lithocraft is at the surface, however it got there: it rests there, the
## `arrival` event is raised, the survey still aboard (the last part-stretch
## included) is sold, the dive's repairs (and a rescue that took
## `rescue_seconds`) are paid for out of it, and &"paid" is raised with what
## this dive was paid and why. The dive is over; new_dive() starts another.
func _come_home(arrival: Dictionary, rescue_seconds := 0.0) -> void:
	_outcome = _ended(arrival.type, &"" if arrival.type == &"surfaced" else _plasma.lost_by(),
			rescue_seconds, arrival.get("depth", 0.0))
	_rest_at_surface()
	_events.append(arrival)
	var carried := _sell_aboard()
	_events.append(_payment(arrival, carried, _pay_for_repairs(rescue_seconds)))


## The dive is over with the Lithocraft at the surface: it stops, no Station
## calls, and time runs at normal rate until new_dive().
func _rest_at_surface() -> void:
	_speed = 0.0
	_slip = 0.0
	_surfaced = true
	_self_destructing = false  # Home alive: nothing left to destroy.
	_calls = {}
	_time_rate = 1.0


## Sells the survey still aboard, the last part-stretch included, and returns
## what it was paid.
func _sell_aboard() -> float:
	var part := _distance - _stretch_start
	if part > 0.0:
		_close_stretch(part)
	var carried := 0.0
	for stretch in _waiting:
		carried += stretch.value()
		_uploaded.append(stretch)
	_paid += carried
	_waiting.clear()
	_sent.clear()
	_sending = null
	return carried


## What putting right a dive that reached the surface cost, each part billed
## by Stranding: the hull's wear from heat and the Head's from poor Shifts,
## each in proportion to the wear, and a rescue in proportion to its time.
## `covered` is the part of the bill beyond what the dive earned, which is not
## charged: a dive's pay never goes below 0 (the game models no debt).
class Repairs:
	var hull := 0.0
	var head := 0.0
	var rescue := 0.0
	var covered := 0.0

	func _init(hull_cost: float, head_cost: float, rescue_cost: float) -> void:
		hull = hull_cost
		head = head_cost
		rescue = rescue_cost

	## Everything the repairs cost together.
	func total() -> float:
		return hull + head + rescue


## Takes what repairing the dive's wear costs out of what this dive earned, a
## rescue that took `rescue_seconds` included, and returns the Repairs. It
## never takes more than the dive earned: the rest is covered, so the dive
## pays at least 0.
func _pay_for_repairs(rescue_seconds := 0.0) -> Repairs:
	var repairs := Repairs.new(_stranding.hull_repair(vessel_wear()),
			_stranding.head_repair(head_wear()), _stranding.rescue_cost(rescue_seconds))
	var charged := minf(repairs.total(), maxf(paid_this_dive(), 0.0))
	repairs.covered = repairs.total() - charged
	_paid -= charged
	return repairs


## The &"paid" event for this dive, which came home as `arrival` (that event):
## everything it was paid, by link while under way and for the survey
## `carried_home`, less the `repairs`, and why: how much Column was recorded
## and how well, what the features were worth, what each Medium paid, and
## what heat and shuttering cost against pristine records.
func _payment(arrival: Dictionary, carried_home: float, repairs: Repairs) -> Dictionary:
	var by_medium := {}
	var stretches := 0
	var metres := 0.0
	var quality_metres := 0.0
	var features := 0
	var feature_worth := 0.0
	var lost_to_quality := 0.0
	for i in range(_dive_uploaded_from, _uploaded.size()):
		var stretch := _uploaded[i]
		by_medium[stretch.medium_name] = by_medium.get(stretch.medium_name, 0.0) + stretch.value()
		lost_to_quality += stretch.pristine_value() - stretch.value()
		if stretch.is_feature_record():
			features += 1
			feature_worth += stretch.feature_worth
		else:
			stretches += 1
			metres += stretch.length
			quality_metres += stretch.quality * stretch.length
	return {type = &"paid", arrival = arrival, amount = paid_this_dive(),
			by_link = _paid_by_link, carried_home = carried_home, hull_repair = repairs.hull,
			head_repair = repairs.head, rescue = repairs.rescue, covered = repairs.covered,
			stretches = stretches,
			metres = metres,
			mean_quality = quality_metres / metres if metres > 0.0 else 0.0,
			features = features, feature_worth = feature_worth,
			lost_to_quality = lost_to_quality, by_medium = by_medium, total_paid = _paid}


# --- The tunnel behind ----------------------------------------------------

## The Tail leaves the tunnel behind it: lined and open in porous Medium,
## filled with melt in dense Medium. Once filled, it stays filled; the filled
## metres are counted, for the rescue to cut through.
func _update_tunnel() -> void:
	var tail := _distance - _VESSEL_LENGTH_M
	if tail <= _tail_at:
		return  # The Tail has not yet left the surface, or not moved.
	var left := tail - _tail_at
	_tail_at = tail
	if _medium_at_distance(tail).porosity >= _SEAL_POROSITY:
		return
	_sealed_metres += left
	if not _tunnel_sealed:
		_tunnel_sealed = true
		_events.append({type = &"tunnel_sealed", distance = tail})


# --- The link to the surface --------------------------------------------

## Sends up to `metres` of survey data up the link, a stretch at a time in
## the chosen priority, and pays for each stretch as the last of it reaches the
## surface.
func _upload(metres: float) -> void:
	while metres > 0.0:
		if _sending == null:
			_sending = _next_to_send()
			if _sending == null:
				return  # Nothing waiting aboard.
		var stretch := _sending
		var sent: float = _sent.get(stretch, 0.0)
		var piece := minf(metres, stretch.length - sent)
		metres -= piece
		sent += piece
		if sent >= stretch.length:
			_sent.erase(stretch)
			_waiting.erase(stretch)
			_sending = null
			_uploaded.append(stretch)
			_paid += stretch.value()
			_paid_by_link += stretch.value()
		else:
			_sent[stretch] = sent


## The waiting stretch the chosen priority sends next, or null if all of the
## survey is up.
func _next_to_send() -> SurveyStretch:
	if _waiting.is_empty():
		return null
	match _upload_priority:
		UPLOAD_NEWEST_FIRST:
			return _waiting.back()
		UPLOAD_MOST_VALUABLE_FIRST:
			var best: SurveyStretch = _waiting[0]
			for stretch in _waiting:
				if stretch.value() > best.value():
					best = stretch
			return best
	return _waiting[0]


# --- Survey ---------------------------------------------------------------

## Records the Column passing through the Bore between two distances along the
## path, closing a survey entry each time a whole stretch has been travelled.
func _record_survey(from: float, to: float) -> void:
	while from < to:
		var stretch_end := _stretch_start + _SURVEY_STRETCH_M
		var piece_end := minf(to, stretch_end)
		var piece := piece_end - from
		var medium := _medium_at_distance((from + piece_end) * 0.5)
		for mineral in medium.composition:
			_stretch_minerals[mineral] = _stretch_minerals.get(mineral, 0.0) 					+ medium.composition[mineral] * piece
		_stretch_media[medium.name] = _stretch_media.get(medium.name, 0.0) + piece
		_stretch_quality += _recording_quality() * piece
		_stretch_shuttered = _stretch_shuttered or shuttered()
		from = piece_end
		if piece_end >= stretch_end:
			_close_stretch()


func _close_stretch(length := _SURVEY_STRETCH_M) -> void:
	var composition := {}
	for mineral in _stretch_minerals:
		composition[mineral] = _stretch_minerals[mineral] / length
	var main_medium: StringName = &""
	for medium_name in _stretch_media:
		if main_medium == &"" or _stretch_media[medium_name] > _stretch_media[main_medium]:
			main_medium = medium_name
	var stretch := SurveyStretch.new(_stretch_start, length,
			_stretch_quality / length, composition, main_medium, _stretch_shuttered)
	_survey.append(stretch)
	_waiting.append(stretch)
	_sending = null  # The new stretch may now be the one to send first.
	_survey_value += stretch.value()
	_stretch_start += length
	_stretch_minerals = {}
	_stretch_media = {}
	_stretch_quality = 0.0
	_stretch_shuttered = false


## How well the Bore Station records the Column right now, 0 to 1. Pristine
## until something spoils the Column: heat sent into it (ticket #7) and Quiet
## Ship shuttering the Bore instruments (ticket #13) lower it here.
func _recording_quality() -> float:
	var shutter := _SHUTTERED_QUALITY if shuttered() else 1.0
	return shutter * _heat.unheated_share(_speed)


## The Medium of the Column at a distance along the path: the Medium at the
## depth the path had there.
func _medium_at_distance(along_path: float) -> Medium:
	return _layout.medium_at(_depth_at_distance(along_path))


# --- Scan -----------------------------------------------------------------

## Sends one pulse as a cone of rays round the heading. Each echo comes from a
## Boundary, where the Medium changes and part of the sound is reflected. An
## echo is weaker the further it travelled and the worse the Media carried
## it; its confidence is its strength against the vessel's own noise. Weak
## echoes are often missed (sparse at range) and stray from where they came
## from (uncertain at range).
func _send_pulse() -> void:
	var origin := head_position()
	var ahead := heading()
	var side := ahead.cross(Vector3.RIGHT if absf(ahead.x) < 0.9 else Vector3.UP).normalized()
	var other_side := ahead.cross(side)
	var boundaries := _boundaries_near(depth())
	var min_cos := cos(deg_to_rad(_PULSE_CONE_DEG))
	for ray in _PULSE_RAYS:
		var c := _scan_random.randf_range(min_cos, 1.0)
		var s := sqrt(1.0 - c * c)
		var turn := _scan_random.randf() * TAU
		var direction := ahead * c + (side * cos(turn) + other_side * sin(turn)) * s
		for echo in _echoes_along(direction, boundaries):
			var r: float = echo[0]
			# A starved scanner listens less keenly: its echoes come back weaker.
			var strength: float = echo[1] * navigation_supplied()
			var confidence := strength / (strength + _noise + _SCAN_NOISE_FLOOR)
			if _scan_random.randf() > confidence:
				continue
			var stray := Vector3(_scan_random.randfn(), _scan_random.randfn(),
					_scan_random.randfn()) * (1.0 - confidence) * r * _SCAN_SCATTER
			_points.append(ScanPoint.new(origin + direction * r + stray, confidence, r,
					_pulses_sent))
	_pulses_sent += 1
	_events.append({type = &"pulse_sent", quiet_ship = _quiet_ship})


## The echoes one ray returns: [range m, strength] for each Boundary it
## crosses in reach, nearest first. Strength falls with the sound lost to each
## Medium on the way out and back, and with what earlier Boundaries reflected.
func _echoes_along(direction: Vector3, boundaries: Array) -> Array:
	var down := -direction.y
	if absf(down) < 0.0001:
		return []
	var crossings := []
	for b in boundaries:
		var r: float = (b - depth()) / down
		if r > 0.0:
			crossings.append(r)
	crossings.sort()
	var echoes := []
	var faded := 0.0
	var passed := 1.0
	var travelled := 0.0
	for r in crossings:
		var depth_at: float = depth() + down * r
		var before := _layout.medium_at(depth_at - signf(down) * 0.01)
		var after := _layout.medium_at(depth_at + signf(down) * 0.01)
		faded += 2.0 * (r - travelled) / (before.sound_carrying * _SCAN_REACH_M)
		travelled = r
		var strength := exp(-faded)
		if strength < _ECHO_CUTOFF:
			break
		var reflected := _reflection(before, after)
		echoes.append([r, passed * reflected * strength])
		passed *= 1.0 - reflected * reflected
	return echoes


## Depths of the Boundaries a pulse sent from this depth could reach.
func _boundaries_near(depth: float) -> Array:
	# No echo returns from further than the cutoff allows in a Medium that
	# carries sound perfectly.
	var reach := -log(_ECHO_CUTOFF) * _SCAN_REACH_M / 2.0
	var found := []
	var d := depth - reach
	var above := _layout.medium_at(d)
	while d < depth + reach:
		var below := _layout.medium_at(d + _BOUNDARY_SEARCH_STEP_M)
		if below != above:
			# Narrow it down to a centimetre.
			var lo := d
			var hi := d + _BOUNDARY_SEARCH_STEP_M
			while hi - lo > 0.01:
				var mid := (lo + hi) * 0.5
				if _layout.medium_at(mid) == above:
					lo = mid
				else:
					hi = mid
			found.append(hi)
		above = below
		d += _BOUNDARY_SEARCH_STEP_M
	return found


## Share of sound a Boundary reflects, from the contrast in acoustic impedance
## (density times sound speed) across it. Stiffer, less open rock is denser and
## faster, so hardness times solid fraction stands in for impedance.
static func _reflection(from: Medium, to: Medium) -> float:
	var z1 := from.hardness * (1.0 - from.porosity)
	var z2 := to.hardness * (1.0 - to.porosity)
	return absf(z2 - z1) / (z2 + z1)
