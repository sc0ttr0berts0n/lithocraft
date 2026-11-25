## The simulation of one dive. Knows nothing of scenes, rendering or input.
##
## Interface shape, copied by every later ticket:
##   commands in   - one method per Station command, e.g. set_power()
##   time step     - advance(dt), dt in simulated seconds
##   state out     - read-only query methods, e.g. depth()
##   events out    - take_events(): events since the last call, then cleared.
##                   Each a Dictionary with a `type` StringName plus fields.
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

## Heat made per second for each unit of power drawn. Every system that draws
## power makes heat. Tuned for play (ADR 0001).
const _HEAT_PER_POWER := 1.0
## Heat per metre of Column that halves the quality the Bore Station can
## record. Tuned for play (ADR 0001).
const _COLUMN_COOK_HEAT_PER_M := 2.0
## How much heat per second the hull sheds into the surrounding Medium for each
## kelvin it is hotter than the Medium. Tuned for play (ADR 0001).
const _HULL_SHED_PER_K := 1.0 / 400.0
## Heat it takes to warm the hull by one kelvin, so the hull warms and cools
## over a minute or so rather than at once. Tuned for play (ADR 0001).
const _HULL_HEAT_PER_K := 0.15
## Hull temperature in kelvin above which heat damages the vessel. Tuned for
## play (ADR 0001).
const _HULL_DAMAGE_K := 600.0
## How far below _HULL_DAMAGE_K the hull's own temperature brings on the heat
## warning. Tuned for play (ADR 0001).
const _HULL_WARNING_MARGIN_K := 50.0
## How much warmer the ground gets per metre of depth, in kelvin. Earth's crust
## warms by about 0.025 K/m; tuned for play (ADR 0001).
const _GEOTHERMAL_K_PER_M := 0.03
## Wear per second for each kelvin the hull is above _HULL_DAMAGE_K. Tuned for
## play (ADR 0001).
const _WEAR_PER_K_S := 1.0e-5

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

## The plasma and the Shift. The load on the Head excites the plasma into a
## wobble whose frequency rises with the hardness of the Medium being cut; the
## Reactor holds it steady by driving an opposing wave at the frequency it is
## tuned to. Frequency of the wobble per root of hardness, in hertz (a
## frequency a crew can see on a screen, not a real plasma mode). Tuned for
## play (ADR 0001).
const _PLASMA_HZ_PER_ROOT_HARDNESS := 0.8
## How far the tuning may be from the wobble, as a share of its frequency, and
## still hold the plasma: beyond it a Shift is due. A Shift this far off
## matches 1/e. Tuned for play (ADR 0001).
const _SHIFT_TOLERANCE := 0.12
## Mistuning (share of the wobble's frequency) at which the plasma, and so the
## Reactor's output, is half as steady. Tuned for play (ADR 0001).
const _MISTUNING_HALF := 0.4
## Seconds from crossing a Boundary in which a Shift loses nothing to lateness.
const _SHIFT_WINDOW_S := 10.0
## Seconds after the window closes over which a late Shift's grade falls to
## 1/e. Tuned for play (ADR 0001).
const _SHIFT_LATE_S := 4.0
## Seconds after the window closes at which the Reactor's autopilot makes the
## Shift itself: on frequency, but late, so poorly. Tuned for play (ADR 0001).
const _AUTOPILOT_LATE_S := 6.0
## Grade at or above which a Shift is clean and passes smoothly.
const _CLEAN_SHIFT_GRADE := 0.8
## What a poor Shift costs at its roughest (roughness 1; a Shift just short of
## clean is barely rough). The heat spike's heat per second at its peak and
## the seconds it takes to fade to 1/e; the lurch's jolt along the Bore in
## m/s^2 at its peak, how fast it shudders and how soon it fades; the wear on
## the Head. Tuned for play (ADR 0001): left to the autopilot, the way down
## through two Boundaries survives even with the hull hot, but a third poor
## Shift with the hull hot (or a few more with it cool) loses the plasma.
const _SHIFT_SPIKE_HEAT := 2.0
const _SHIFT_SPIKE_S := 1.5
const _LURCH_ACCELERATION := 14.0
const _LURCH_HZ := 3.0
const _LURCH_S := 0.4
const _SHIFT_WEAR := 0.3
## How much worse a poor Shift wears the Head with the hull at the temperature
## it can bear than with it as cool as the Medium around it. Bad conditions.
const _HOT_SHIFT_WEAR := 1.0
## How much a fully worn Head unsteadies the plasma even when tuned.
const _WEAR_UNSTEADINESS := 0.3
## What repairing a Head worn through costs, in the units of paid(), charged
## in proportion to the wear when the crew is brought home through the open
## tunnel. About a few hundred metres of good survey. Tuned for play
## (ADR 0001).
const _HEAD_REPAIR_COST := 500.0

## The Stations, as named in set_attended(), call_urgency() and calls.
const STATION_REACTOR := &"reactor"
const STATION_DRIVE := &"drive"
const STATION_THERMAL := &"thermal"
const STATION_NAVIGATION := &"navigation"
const STATION_BORE := &"bore"
const STATIONS: Array[StringName] = [STATION_REACTOR, STATION_DRIVE, STATION_THERMAL,
		STATION_NAVIGATION, STATION_BORE]
## Share of the heat split an unattended Thermal Station moves into the Column
## per second while the hull warns: its steadying rule, slow on purpose so a
## sudden heat outruns it. Tuned for play (ADR 0001).
const _UNATTENDED_SPLIT_RATE := 0.01
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
## What a recovery keeps; every other variable starts over as a fresh dive.
## The world (the layout), what was paid for, and events not yet taken.
const _KEPT_ON_RECOVERY: Array[StringName] = [&"_layout", &"_paid", &"_uploaded", &"_events",
		# Where the crew is: the view tells the simulation, not the dive.
		&"_attended"]

var _layout: MediumLayout
var _power := 0.0
## Where the Head is in the world frame (see head_position()) and the way it
## points there, unit length. Starts at the surface, Head straight down.
var _position := Vector3.ZERO
var _direction := Vector3.DOWN
## Drive settings: the pitch and compass heading to steer toward, degrees.
var _pitch_setting := 90.0
var _heading_setting := 0.0
## The last compass heading the vessel had while not pointing straight up or
## down, where heading has no meaning. Degrees, 0 along -Z, 90 along +X.
var _bearing := 0.0
## How hard the Head is steering: 0 even heating, 1 the tightest arc.
var _steering := 0.0
## The path so far as (distance along it, depth) points, for the Column.
var _path_distances := PackedFloat64Array([0.0])
var _path_depths := PackedFloat64Array([0.0])
var _speed := 0.0
var _slip := 0.0
## Thermal: the share of heat sent into the Column; the rest goes outward.
var _heat_split := 0.0
## Heat made in the last step, per second.
var _heat_produced := 0.0
## Heat sent into the Column in the last step, per second.
var _heat_to_column := 0.0
## The hull's temperature in kelvin. Heat sent outward passes through it.
var _vessel_temperature := 0.0
## The temperature the hull is heading for at the heat now sent outward.
var _hull_settling_at := 0.0
## Damage done to the vessel by heat, 0 (none) to 1.
var _vessel_wear := 0.0
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
## How steady the Head's plasma is, 0 (lost) to 1 (steady). The Reactor's
## output scales with it. Always steady until the Shift (ticket #11).
var _plasma_stability := 1.0
## Navigation's point cloud, oldest first, and whether a pulse is waiting to
## be sent on the next step.
var _points: Array[ScanPoint] = []
var _pulse_pending := false
var _pulses_sent := 0
## Fixed seed, so a dive's scan is the same every run.
var _scan_random := RandomNumberGenerator.new()
## Depth of the Boundary last announced as approaching, or NAN for none.
var _announced_boundary := NAN
## The frequency the Reactor is tuned to hold the plasma at, in hertz.
var _tuning := 0.0
## Seconds the plasma has been mistuned (a Shift due), 0 while tuned.
var _mistuned_for := 0.0
## A Shift asked for since the last step (its frequency), or NAN.
var _shift_asked := NAN
## Wear on the Head from poor Shifts, 0 (none) to 1 (the plasma is lost).
var _head_wear := 0.0
## True once the Head's plasma has gone out. It stays out.
var _plasma_lost := false
## True once the plasma is lost while sealed in: the dive is over until
## recover() (ticket #12).
var _stranded := false
## Extra heat per second from the last poor Shift, fading.
var _heat_spike := 0.0
## The last poor Shift's lurch: its peak jolt in m/s^2 and seconds since.
var _lurch_peak := 0.0
var _lurch_age := 0.0
## Stations a crew member is at (StringName -> true).
var _attended := {}
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


func _init(layout: MediumLayout) -> void:
	_layout = layout
	_vessel_temperature = surroundings_temperature()
	_hull_settling_at = _vessel_temperature
	_scan_random.seed = 13
	_tuning = plasma_frequency()
	_share_power()


# --- Commands -------------------------------------------------------------

## Drive Station: the share of available power sent to advancing, 0 to 1.
func set_power(power: float) -> void:
	_power = clampf(power, 0.0, 1.0)


## Drive: the pitch to steer toward, in degrees. +90 is the Head straight down
## (diving), 0 is level, -90 is the Head straight up (climbing). The vessel turns
## toward it along an arc no tighter than minimum_turn_radius(), and only
## while it moves.
func set_pitch(degrees: float) -> void:
	_pitch_setting = clampf(degrees, -90.0, 90.0)


## Drive: the compass heading to steer toward, in degrees: 0 along the world's
## -Z, 90 along +X. Turned toward like pitch. Has no effect while the pitch
## setting is straight up or down.
func set_heading(degrees: float) -> void:
	_heading_setting = fposmod(degrees, 360.0)


## Bore Station: which feature in the Column to observe and record, by id
## (see features_in_column()). -1, or a feature not now in the Column, observes
## nothing. Observing records; nothing is ever cut out of the Column.
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
		_upload_priority = priority
		_sending = null


## Thermal Station: the share of the heat sent into the Column, 0 to 1. The
## rest goes outward into the surrounding Medium through the hull.
func set_heat_split(to_column: float) -> void:
	_heat_split = clampf(to_column, 0.0, 1.0)


## Navigation: send one sound pulse ahead. Its echoes are added to the point
## cloud on the next step.
func pulse() -> void:
	_pulse_pending = true


## Navigation: Quiet Ship on or off. On, the Head spins down to idle and the
## vessel halts whatever the Drive asks, so a pulse is not drowned by the
## vessel's own noise; the Bore instruments are shuttered while it lasts. Off,
## the Head spins back up and the Drive's power setting applies again.
func set_quiet_ship(on: bool) -> void:
	_quiet_ship = on


## Whether a crew member is at this Station (one of STATIONS) to work it.
## An unattended Station holds its last setting and applies a simple
## steadying rule: the Reactor's autopilot makes a Shift on frequency but
## late, so poorly; Thermal slowly sends heat into the Column while the hull
## warns; the Drive backs its power off to the grip limit while it slips.
## Attended, a Station leaves everything to the crew. All start
## unattended.
func set_attended(station: StringName, attended: bool) -> void:
	if station in STATIONS:
		_attended[station] = attended


## How many times normal to run the simulation: advance(dt) then runs
## dt x rate simulated seconds. Clamped to 1..max_time_rate(). Any Station call
## returns it to 1, and while any Station is still calling it cannot be raised
## above 1: time runs fast only through quiet stretches.
func set_time_rate(rate: float) -> void:
	var fastest := 1.0 if not _calls.is_empty() else _MAX_TIME_RATE
	_time_rate = clampf(rate, 1.0, fastest)


## The recovery after a stranding: the crew and the Lithocraft are brought
## back to the surface, ready to dive again as at the start of a dive, with
## every Station setting back at its start. What was paid (paid(),
## uploaded_survey()) is kept; the lost survey stays lost. Ignored unless
## stranded(). Raises &"recovered".
func recover() -> void:
	if not _stranded:
		return
	_start_fresh()
	_events.append({type = &"recovered", paid = _paid})


## Start another dive after surfacing: the Lithocraft is at the surface ready
## to dive, every Station setting back at its start, as after a recovery.
## What was paid is kept. Ignored unless surfaced(). Raises &"new_dive".
func new_dive() -> void:
	if not _surfaced:
		return
	_start_fresh()
	_events.append({type = &"new_dive", paid = _paid})


## Resets every script variable to a fresh simulation's except those kept
## between dives (_KEPT_ON_RECOVERY), and starts counting a new dive's pay.
func _start_fresh() -> void:
	var fresh := DiveSimulation.new(_layout)
	for property in get_property_list():
		if property.usage & PROPERTY_USAGE_SCRIPT_VARIABLE \
				and not StringName(property.name) in _KEPT_ON_RECOVERY:
			set(property.name, fresh.get(property.name))
	_dive_uploaded_from = _uploaded.size()
	_paid_before_dive = _paid


## Reactor Station: perform a Shift, setting the Reactor to hold the plasma
## at this frequency in hertz, on the next step. The closer it matches the
## plasma's wobble (plasma_frequency()), and the sooner after a Boundary, the
## better it grades; see the &"shift_result" event.
func shift(frequency: float) -> void:
	_shift_asked = maxf(frequency, 0.0)


# --- Time step ------------------------------------------------------------

## Runs dt x time_rate() simulated seconds. At normal rate that is one step of
## dt; faster, it is split into steps no longer than dt or _FAST_STEP_S,
## whichever is longer. A Station call returns the rate to normal and the rest
## of the time is not run.
func advance(dt: float) -> void:
	if _time_rate <= 1.0:
		_step(dt)
		return
	var total := dt * _time_rate
	var steps := ceili(total / maxf(dt, _FAST_STEP_S))
	for i in steps:
		_step(total / steps)
		if _time_rate <= 1.0:
			return


func _step(dt: float) -> void:
	if _stranded or _surfaced:
		return  # The dive is over; nothing moves until recover() or new_dive().
	_head_activity = move_toward(_head_activity, 0.0 if _quiet_ship else 1.0,
			_HEAD_SPIN_RATE * dt)
	_tend_plasma(dt)
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
	_heat_produced = power_drawn() * _HEAT_PER_POWER + _heat_spike
	# Heat reaches the Column only as far as Thermal's pumps are powered; the
	# rest goes out through the hull.
	_heat_to_column = _heat_produced * _heat_split * thermal_supplied()
	_shed_heat_outward(_heat_produced - _heat_to_column, dt)
	_noise = _head_activity * _HEAD_HUM + _DRIVE_NOISE * power * (1.0 + _slip)
	var depth_before := depth()
	# The Head moves along its arc, turning toward the Drive's settings.
	_steer(_speed, dt)
	var travelled := _speed * dt
	_record_survey(_distance, _distance + travelled)
	_record_observed_feature(dt, travelled)
	_find_features(depth_before, depth(), travelled)
	_distance += travelled
	_remember_path()
	_watch_boundaries(depth_before)
	_update_tunnel()
	_upload(link_rate() * dt)
	if depth_before > 0.0 and depth() <= 0.0:
		_surface()
		return
	if _pulse_pending:
		_pulse_pending = false
		_send_pulse()
	_steady_unattended(dt)
	_check_stranded()
	if _surfaced:
		return  # Brought home through the open tunnel.
	_update_calls()


# --- State ----------------------------------------------------------------

## Whether a crew member is at this Station; see set_attended().
func attended(station: StringName) -> bool:
	return _attended.get(station, false)


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


## Drive power setting, 0 to 1.
func power() -> float:
	return _power


## Radius in metres of the tightest arc the Lithocraft can cut. No command
## turns it tighter, however slow or fast it goes.
func minimum_turn_radius() -> float:
	return _MIN_TURN_RADIUS_M


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
			+ TOWARD_HEAD * lurch() * cos(TAU * _LURCH_HZ * _lurch_age)


## How hard a poor Shift's lurch is jolting the vessel now, in m/s^2: sharp at
## the Shift, gone in a moment. 0 after a clean one.
func lurch() -> float:
	return _lurch_peak * exp(-_lurch_age / _LURCH_S)


## Wear on the Head from poor Shifts, 0 (none) to 1. It only accumulates; a
## worn Head holds the plasma less steadily, and a Head worn through loses it.
func head_wear() -> float:
	return _head_wear


## True once the plasma has been lost: the Reactor supplies nothing, so the
## vessel halts. It stays lost.
func plasma_lost() -> bool:
	return _plasma_lost


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


## How steady the Head's plasma is, 0 (lost) to 1 (steady).
func plasma_stability() -> float:
	return _plasma_stability


## The frequency, in hertz, of the wobble the load on the Head excites in the
## plasma now. Harder rock loads the Head more and wobbles it faster, so
## crossing a Boundary changes it. A Shift matches it.
func plasma_frequency() -> float:
	return _PLASMA_HZ_PER_ROOT_HARDNESS * sqrt(_layout.medium_at(depth()).hardness)


## The frequency, in hertz, the Reactor is tuned to hold the plasma at: the
## opposing wave it drives. Set by the last Shift.
func plasma_tuning() -> float:
	return _tuning


## True while the tuning no longer holds the plasma's wobble (after crossing a
## Boundary, or after a Shift wide of the mark) and a Shift is due.
func shift_due() -> bool:
	return _mistuning() > _SHIFT_TOLERANCE


## Seconds left in the window in which a due Shift loses nothing to lateness;
## 0 when no Shift is due or the window has closed.
func shift_window() -> float:
	return maxf(0.0, _SHIFT_WINDOW_S - _mistuned_for) if shift_due() else 0.0


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
##       &"plasma_lost": see ticket #11 (shift_test.gd).
##   &"station_call" {station, reason, urgency}: a Station has begun calling,
##       or calls for a new reason (see call_reason()). The time rate returns
##       to normal.
##   &"stranded" {depth, distance, lost, lost_stretches, paid}: the plasma was
##       lost while sealed in. `lost` is the value of the unsold survey
##       discarded (`lost_stretches` stretches of it); `paid` is kept.
##   &"recovered" {paid}: recover() has brought the crew back to the surface
##       with `paid` kept, ready to dive again.
##   &"surfaced" {distance}: the Head has come back up to the surface; the
##       dive is over.
##   &"paid" {amount, by_link, carried_home, stretches, metres, mean_quality,
##       features, feature_worth, lost_to_quality, by_medium, total_paid}:
##       right after surfaced, what this dive was paid (`amount` = `by_link`,
##       paid while under way, + `carried_home`, the survey sold on
##       surfacing) and why: Column recorded and its length-weighted quality,
##       features recorded and their worth, the value heat and shuttering
##       took off pristine records, and pay per Medium name. `total_paid` is
##       paid() across every dive.
##   &"recovered_through_tunnel" {depth, distance, carried_home, head_repair,
##       amount, total_paid}: the plasma was lost with the tunnel still open,
##       so the crew and the Lithocraft were brought back up it from `depth`.
##       The survey aboard was sold (`carried_home`) and the worn Head's
##       repair paid for out of it; `amount` is this dive's pay after the
##       repair, `total_paid` paid() across every dive. The dive is over as
##       after surfacing (surfaced() is true); new_dive() starts another.
##   &"new_dive" {paid}: new_dive() has the Lithocraft ready at the surface.
func take_events() -> Array[Dictionary]:
	var taken := _events
	_events = []
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
## move and no tunnel leads up. The dive is over; time no longer advances it.
## recover() brings the crew back to the surface.
func stranded() -> bool:
	return _stranded


## True once the Head has come back up to the surface, under its own power or
## brought back through the open tunnel after losing the plasma, and the
## survey has been sold: the dive is over and time no longer advances it.
## new_dive() starts another.
func surfaced() -> bool:
	return _surfaced


## True once the tunnel behind has been filled somewhere, so no continuous open
## tunnel reaches the surface. It stays sealed for the rest of the dive.
func tunnel_sealed() -> bool:
	return _tunnel_sealed


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
## Lithocraft is in carries sound.
func link_rate() -> float:
	if not _tunnel_sealed:
		return _FAST_LINK_RATE
	return _SLOW_LINK_RATE * medium().sound_carrying


## What has been paid so far for survey data that has reached the surface.
## Data still aboard earns nothing.
func paid() -> float:
	return _paid


## The upload priority in force, one of the UPLOAD_* priorities.
func upload_priority() -> StringName:
	return _upload_priority


## The survey stretches whose data has reached the surface and been paid for,
## in the order they arrived. A copy.
func uploaded_survey() -> Array[SurveyStretch]:
	return _uploaded.duplicate()


## Heat made in the last step by everything that draws power, per second.
func heat_produced() -> float:
	return _heat_produced


## Heat sent into the Column in the last step, per second.
func heat_to_column() -> float:
	return _heat_to_column


## Heat sent outward through the hull in the last step, per second.
func heat_outward() -> float:
	return _heat_produced - _heat_to_column


## The hull's temperature in kelvin. Heat sent outward warms it until it is hot
## enough above the surrounding Medium to shed that heat.
func vessel_temperature() -> float:
	return _vessel_temperature


## Temperature in kelvin of the Medium around the vessel now: the Medium's own
## temperature plus the planet's warming with depth, so it rises even within
## one Medium and the hull has less room to shed heat the deeper it goes.
func surroundings_temperature() -> float:
	return _layout.medium_at(depth()).temperature + _GEOTHERMAL_K_PER_M * depth()


## Damage heat has done to the vessel so far, 0 (none) to 1. It only grows
## while the hull is hotter than it can bear.
func vessel_wear() -> float:
	return _vessel_wear


## True while heat threatens the vessel: the hull is close to the temperature
## at which heat damages it, or the heat now sent outward will take it past
## that if nothing changes. Comes on before any damage is done.
func heat_warning() -> bool:
	return _vessel_temperature >= hull_warning_temperature() \
			or _hull_settling_at > hull_damage_temperature()


## Hull temperature in kelvin at which heat_warning() comes on regardless of
## where the hull is heading. For gauges.
func hull_warning_temperature() -> float:
	return _HULL_DAMAGE_K - _HULL_WARNING_MARGIN_K


## Hull temperature in kelvin above which heat wears the vessel. For gauges.
func hull_damage_temperature() -> float:
	return _HULL_DAMAGE_K


# --- Steering -------------------------------------------------------------

## The direction the settings ask for, in the world frame.
func _wanted_direction() -> Vector3:
	var p := deg_to_rad(_pitch_setting)
	var h := deg_to_rad(_heading_setting)
	return Vector3(cos(p) * sin(h), -sin(p), -cos(p) * cos(h)).normalized()


## Turns the Head toward the settings for dt seconds at this speed, and moves
## it along the arc. The steering builds toward what the remaining turn needs
## at a limited rate, and the path bends by at most speed / minimum radius
## radians per second, so a stopped vessel cannot turn and none turns tighter
## than its minimum arc. The Head only ever moves the way it points.
func _steer(speed: float, dt: float) -> void:
	var wanted := _wanted_direction()
	var remaining := _direction.angle_to(wanted)
	var needed := clampf(rad_to_deg(remaining) / _STEER_EASE_DEG, 0.0, 1.0)
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
	_reactor_output = _plasma_stability * lerpf(_REACTOR_IDLE_OUTPUT,
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
	_mistuned_for = 0.0
	if not _tunnel_sealed and to.porosity < _SEAL_POROSITY and from.porosity >= _SEAL_POROSITY:
		_seal_coming_at = _distance


# --- Unattended Stations and calls ----------------------------------------

## The steadying rules of Stations no one is at. Steady conditions leave every
## setting as it was. The Drive backs its power off to what the wall can
## grip once the grip waves slip: the slipped share only made heat and noise.
func _steady_unattended(dt: float) -> void:
	if not attended(STATION_DRIVE) and _slip > 0.0:
		_power *= 1.0 - _slip
	if not attended(STATION_THERMAL) and heat_warning():
		_heat_split = minf(1.0, _heat_split + _UNATTENDED_SPLIT_RATE * dt)


## Works out which Stations call, why and how urgently, from the state after
## this step. A call that begins, or changes reason, is announced and returns
## the time rate to normal.
func _update_calls() -> void:
	var calls := {}
	_reactor_call(calls)
	if heat_warning():
		var over := (_vessel_temperature - hull_warning_temperature()) \
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
			_time_rate = 1.0
	_calls = calls


func _reactor_call(calls: Dictionary) -> void:
	if _stranded:
		_offer_call(calls, STATION_REACTOR, &"stranded", _EMERGENCY_CALL_URGENCY)
	elif _plasma_lost:
		_offer_call(calls, STATION_REACTOR, &"plasma_lost", _EMERGENCY_CALL_URGENCY)
	elif shift_due():
		_offer_call(calls, STATION_REACTOR, &"shift_due", _urgency(_SHIFT_DUE_CALL,
				_mistuned_for / (_SHIFT_WINDOW_S + _AUTOPILOT_LATE_S)))
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


# --- The plasma and the Shift ---------------------------------------------

## Once a step, before the power is shared: times the mistuned plasma, takes
## a Shift asked for, lets the autopilot make an overdue one, and sets how
## steady the plasma is.
func _tend_plasma(dt: float) -> void:
	_mistuned_for = _mistuned_for + dt if shift_due() else 0.0
	_lurch_age += dt
	_heat_spike *= exp(-dt / _SHIFT_SPIKE_S)
	if _plasma_lost:
		_shift_asked = NAN
		_plasma_stability = 0.0
		return
	if not is_nan(_shift_asked):
		_make_shift(_shift_asked, false)
		_shift_asked = NAN
	if shift_due() and not attended(STATION_REACTOR) \
			and _mistuned_for >= _SHIFT_WINDOW_S + _AUTOPILOT_LATE_S:
		_make_shift(plasma_frequency(), true)
	if _plasma_lost:
		_plasma_stability = 0.0
		return
	_plasma_stability = (1.0 - _WEAR_UNSTEADINESS * _head_wear) \
			/ (1.0 + _mistuning() / _MISTUNING_HALF)


## Makes the Shift to `frequency` and grades it: how closely it
## matches the plasma's wobble, times how late it came after the window.
func _make_shift(frequency: float, by_autopilot: bool) -> void:
	var target := plasma_frequency()
	var error := absf(frequency - target) / target
	var matched := exp(-pow(error / _SHIFT_TOLERANCE, 2.0))
	var late := maxf(0.0, _mistuned_for - _SHIFT_WINDOW_S) if shift_due() else 0.0
	var grade := matched * exp(-late / _SHIFT_LATE_S)
	_tuning = frequency
	if not shift_due():
		_mistuned_for = 0.0
	# A poor Shift grinds: the rougher, the bigger the heat spike, the harder
	# the lurch and the more wear on the Head. A clean one does nothing at all.
	var roughness := clampf((_CLEAN_SHIFT_GRADE - grade) / _CLEAN_SHIFT_GRADE, 0.0, 1.0)
	var wear := roughness * _SHIFT_WEAR * (1.0 + _HOT_SHIFT_WEAR * _hull_heat_share())
	if roughness > 0.0:
		_heat_spike += roughness * _SHIFT_SPIKE_HEAT
		_lurch_peak = roughness * _LURCH_ACCELERATION
		_lurch_age = 0.0
		_head_wear = minf(1.0, _head_wear + wear)
	_events.append({type = &"shift_result", grade = grade,
			clean = roughness <= 0.0, late = late, autopilot = by_autopilot,
			wear = wear if roughness > 0.0 else 0.0})
	if _head_wear >= 1.0:
		_plasma_lost = true
		_events.append({type = &"plasma_lost", depth = depth(), distance = _distance})


## How hot the hull is, from as cool as the Medium around it (0) to the
## temperature it can bear (1). A Shift with the hull hot is under bad
## conditions.
func _hull_heat_share() -> float:
	var cool := surroundings_temperature()
	return clampf((_vessel_temperature - cool) / (_HULL_DAMAGE_K - cool), 0.0, 1.0)


## How far the tuning is from the plasma's wobble, as a share of its frequency.
func _mistuning() -> float:
	var target := plasma_frequency()
	return absf(_tuning - target) / target


# --- Stranding -----------------------------------------------------------

## Losing the plasma while sealed in strands the Lithocraft. The survey data
## not yet up the link is lost with it; what reached the surface stays paid.
## Losing it with the tunnel still open behind, the crew is brought home
## through the tunnel instead (_recover_through_tunnel()).
func _check_stranded() -> void:
	if _stranded or not _plasma_lost:
		return
	if not _tunnel_sealed:
		_recover_through_tunnel()
		return
	_stranded = true
	var lost_value := unsold_value()
	var lost_stretches := _waiting.filter(
			func(s: SurveyStretch) -> bool: return not s.is_feature_record()).size()
	var lost := {}
	for stretch in _waiting:
		lost[stretch] = true
	_survey_value -= lost_value
	_survey.assign(_survey.filter(func(s: SurveyStretch) -> bool: return not lost.has(s)))
	_waiting.clear()
	_sent.clear()
	_sending = null
	_events.append({type = &"stranded", depth = depth(), distance = _distance,
			lost = lost_value, lost_stretches = lost_stretches, paid = _paid})


## The plasma is lost but the tunnel behind is open all the way up: the
## Lithocraft is hauled back up it to the surface with the crew and everything
## aboard. The survey aboard is kept and sold on return, as on surfacing, and
## the worn Head's repair is paid for out of it. The dive is over, as after
## surfacing; new_dive() starts another. Raises &"recovered_through_tunnel".
func _recover_through_tunnel() -> void:
	var from_depth := depth()
	_position = Vector3.ZERO
	_rest_at_surface()
	var carried := _sell_aboard()
	var repair := _head_wear * _HEAD_REPAIR_COST
	_paid -= repair
	_events.append({type = &"recovered_through_tunnel", depth = from_depth,
			distance = _distance, carried_home = carried, head_repair = repair,
			amount = _paid - _paid_before_dive, total_paid = _paid})


# --- Surfacing and the sale -----------------------------------------------

## The Head has come back up to the surface: the Lithocraft stops there, the
## survey still aboard (the last part-stretch included) is sold, and the dive
## is over. Raises &"surfaced", then &"paid" with what this dive was paid and
## why.
func _surface() -> void:
	_position.y = 0.0  # The Head rests at the surface.
	_rest_at_surface()
	_events.append({type = &"surfaced", distance = _distance})
	_events.append(_payment(_sell_aboard()))


## The dive is over with the Lithocraft at the surface: it stops, no Station
## calls, and time runs at normal rate until new_dive().
func _rest_at_surface() -> void:
	_speed = 0.0
	_slip = 0.0
	_surfaced = true
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


## The &"paid" event for this dive: everything it was paid, by link while
## under way and for the survey carried home, and why: how much Column was
## recorded and how well, what the features were worth, what each Medium paid,
## and what heat and shuttering cost against pristine records.
func _payment(carried_home: float) -> Dictionary:
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
	var amount := _paid - _paid_before_dive
	return {type = &"paid", amount = amount, by_link = amount - carried_home,
			carried_home = carried_home, stretches = stretches, metres = metres,
			mean_quality = quality_metres / metres if metres > 0.0 else 0.0,
			features = features, feature_worth = feature_worth,
			lost_to_quality = lost_to_quality, by_medium = by_medium, total_paid = _paid}


# --- The tunnel behind ----------------------------------------------------

## The Tail leaves the tunnel behind it: lined and open in porous Medium,
## filled with melt in dense Medium. Once filled, it stays filled.
func _update_tunnel() -> void:
	if _tunnel_sealed:
		return
	var tail := _distance - _VESSEL_LENGTH_M
	if tail < 0.0:
		return  # The Tail has not yet left the surface.
	if _medium_at_distance(tail).porosity < _SEAL_POROSITY:
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


# --- Heat -----------------------------------------------------------------

## Passes heat outward through the hull for dt seconds. The hull settles toward
## the temperature at which it sheds that heat into the Medium, and wears for
## as long as it is above the temperature it can bear.
func _shed_heat_outward(heat: float, dt: float) -> void:
	_hull_settling_at = surroundings_temperature() + heat / _HULL_SHED_PER_K
	var toward := exp(-dt * _HULL_SHED_PER_K / _HULL_HEAT_PER_K)
	_vessel_temperature = _hull_settling_at \
			+ (_vessel_temperature - _hull_settling_at) * toward
	var overheat := _vessel_temperature - _HULL_DAMAGE_K
	if overheat > 0.0:
		_vessel_wear = minf(1.0, _vessel_wear + _WEAR_PER_K_S * overheat * dt)


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
	return shutter * _unheated_share()


## How much of the Column's record survives the heat sent into it, 0 to 1. What
## spoils it is the heat each metre of Column takes up: the same heat spread
## over more Column (moving faster) cooks each metre less.
func _unheated_share() -> float:
	if _heat_to_column <= 0.0:
		return 1.0
	if _speed <= 0.0:
		return 0.0
	var heat_per_metre := _heat_to_column / _speed
	return 1.0 / (1.0 + heat_per_metre / _COLUMN_COOK_HEAT_PER_M)


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
