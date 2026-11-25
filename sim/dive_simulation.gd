## The simulation of one dive. Knows nothing of scenes, rendering or input.
##
## Interface shape, copied by every later ticket:
##   commands in   - one method per Station command, e.g. set_power()
##   time step     - advance(dt), dt in simulated seconds
##   state out     - read-only query methods, e.g. depth()
##   events out    - take_events(): events since the last call, then cleared.
##                   Added by the first ticket that raises an event.
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
## steering per second: the vessel answers the helm slowly. Tuned for play.
const _STEER_RESPONSE := 0.1
## Within this many degrees of the setting the steering eases off, so the
## vessel settles onto its heading instead of swinging past. Tuned for play.
const _STEER_EASE_DEG := 10.0
## Extra heat at full steering, as a share of the Drive's own heat: the hot
## side of the Head runs hotter than the cool side is eased. Tuned for play.
const _STEER_HEAT := 0.5
## The path the Column was cut along is remembered as points at least this
## far apart (straight runs are merged into one piece). Metres.
const _PATH_SAMPLE_M := 0.5

## Earth's surface gravity, m/s^2.
const _GRAVITY := 9.81

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

## Navigation's power draw: the share of the Reactor's output the scanner takes
## while it listens, in the same units as set_power(), with the cost of its
## pulses averaged in. The power budget (ticket #10) counts this against the
## Reactor through navigation_draw(). Tuned for play (ADR 0001).
const _NAVIGATION_DRAW := 0.05

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

var _layout: MediumLayout
var _power := 0.0
## Where the Head is in the world frame (see head_position()) and the way it
## points there, unit length. Starts at the surface, nose straight down.
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
## Metres travelled along the path since the dive began. The path is straight
## down until steering lands (ticket #8), so for now it equals depth.
var _distance := 0.0
## Completed survey entries, oldest first.
var _survey: Array[SurveyStretch] = []
## The stretch being recorded now: where it began, and per-metre sums of what
## the Column held (mineral -> metres, Medium name -> metres, quality x metres).
var _stretch_start := 0.0
var _stretch_minerals := {}
var _stretch_media := {}
var _stretch_quality := 0.0
var _stretch_shuttered := false
## Quiet Ship: set by Navigation; the Head spins down and the Bore shutters.
var _quiet_ship := false
## How hard the Head is running, 0 (idle) to 1 (running). Starts running.
var _head_activity := 1.0
## The vessel's own noise during the last step, 0 when silent.
var _noise := 0.0
## Navigation's point cloud, oldest first, and whether a pulse is waiting to
## be sent on the next step.
var _points: Array[ScanPoint] = []
var _pulse_pending := false
var _pulses_sent := 0
## Fixed seed, so a dive's scan is the same every run.
var _scan_random := RandomNumberGenerator.new()


func _init(layout: MediumLayout) -> void:
	_layout = layout
	_vessel_temperature = surroundings_temperature()
	_hull_settling_at = _vessel_temperature
	_scan_random.seed = 13


# --- Commands -------------------------------------------------------------

## Drive Station: the share of available power sent to advancing, 0 to 1.
func set_power(power: float) -> void:
	_power = clampf(power, 0.0, 1.0)


## Drive: the pitch to steer toward, in degrees. +90 is nose straight down
## (diving), 0 is level, -90 is nose straight up (climbing). The vessel turns
## toward it along an arc no tighter than minimum_turn_radius(), and only
## while it moves.
func set_pitch(degrees: float) -> void:
	_pitch_setting = clampf(degrees, -90.0, 90.0)


## Drive: the compass heading to steer toward, in degrees: 0 along the world's
## -Z, 90 along +X. Turned toward like pitch. Has no effect while the pitch
## setting is straight up or down.
func set_heading(degrees: float) -> void:
	_heading_setting = fposmod(degrees, 360.0)


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


# --- Time step ------------------------------------------------------------

func advance(dt: float) -> void:
	_head_activity = move_toward(_head_activity, 0.0 if _quiet_ship else 1.0,
			_HEAD_SPIN_RATE * dt)
	var power := _power * _head_activity
	var medium := _layout.medium_at(depth())
	# The grip waves can only push as hard as the wall holds; the rest slips.
	var grip := medium.strength * _GRIP_PER_STRENGTH
	var gripped_power := minf(power, grip)
	_slip = 0.0 if power <= 0.0 else (power - gripped_power) / power
	_speed = _FULL_POWER_SPEED * gripped_power / medium.hardness
	# Every system that draws power makes heat: the Drive (power lost to slip
	# included; less while the Head idles) and Navigation.
	# Steering heats one side of the Head harder, so turning costs heat. The
	# Head moves along its arc here too.
	_steer(_speed, dt)
	_heat_produced = (power * (1.0 + _STEER_HEAT * _steering) + navigation_draw()) \
			* _HEAT_PER_POWER
	_heat_to_column = _heat_produced * _heat_split
	_shed_heat_outward(_heat_produced - _heat_to_column, dt)
	_noise = _head_activity * _HEAD_HUM + _DRIVE_NOISE * power * (1.0 + _slip)
	var travelled := _speed * dt
	_record_survey(_distance, _distance + travelled)
	_distance += travelled
	_remember_path()
	if _pulse_pending:
		_pulse_pending = false
		_send_pulse()


# --- State ----------------------------------------------------------------

## Metres below the surface. Increases as the Lithocraft dives.
func depth() -> float:
	return -_position.y


## Degrees. +90 is nose straight down (diving), 0 level, -90 nose straight up.
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
## inside the vessel. Turns are too wide for their own pull to be felt.
func felt_acceleration() -> Vector3:
	var th := deg_to_rad(pitch())
	return (TOWARD_UNDERSIDE * cos(th) + TOWARD_HEAD * sin(th)) * _GRAVITY


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


## Navigation's power draw, as a share of the Reactor's output in the same
## units as set_power(). For the power budget (ticket #10) to count.
func navigation_draw() -> float:
	return _NAVIGATION_DRAW


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


func _close_stretch() -> void:
	var length := _SURVEY_STRETCH_M
	var composition := {}
	for mineral in _stretch_minerals:
		composition[mineral] = _stretch_minerals[mineral] / length
	var main_medium: StringName = &""
	for medium_name in _stretch_media:
		if main_medium == &"" or _stretch_media[medium_name] > _stretch_media[main_medium]:
			main_medium = medium_name
	_survey.append(SurveyStretch.new(_stretch_start, length,
			_stretch_quality / length, composition, main_medium, _stretch_shuttered))
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
			var strength: float = echo[1]
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
