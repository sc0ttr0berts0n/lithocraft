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

## Habitat frame: the fixed axes of the vessel that felt_acceleration() is
## given in. TOWARD_HEAD runs along the Bore toward the Head. TOWARD_UNDERSIDE
## is the outer wall that is underneath when the vessel is level.
const TOWARD_HEAD := Vector3.FORWARD
const TOWARD_UNDERSIDE := Vector3.DOWN

## How fast the vessel pitches toward its setting, degrees per second.
## Slow enough to keep footing as "down" turns. Tuned for play (ADR 0001);
## tests must not depend on its value.
const _PITCH_RATE := 5.0

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
var _depth := 0.0
var _pitch := 90.0
var _pitch_setting := 90.0
var _speed := 0.0
var _slip := 0.0
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
## Navigation's point cloud, oldest first, and whether a pulse is waiting to
## be sent on the next step.
var _points: Array[ScanPoint] = []
var _pulse_pending := false
var _pulses_sent := 0
## Fixed seed, so a dive's scan is the same every run.
var _scan_random := RandomNumberGenerator.new()


func _init(layout: MediumLayout) -> void:
	_layout = layout
	_scan_random.seed = 13


# --- Commands -------------------------------------------------------------

## Drive Station: the share of available power sent to advancing, 0 to 1.
func set_power(power: float) -> void:
	_power = clampf(power, 0.0, 1.0)


## Drive: the pitch to steer toward, in degrees. +90 is nose straight down
## (diving), 0 is level, -90 is nose straight up (climbing).
func set_pitch(degrees: float) -> void:
	_pitch_setting = clampf(degrees, -90.0, 90.0)


## Bore Station: which waiting survey data goes up the link first, one of the
## UPLOAD_* priorities. Anything else is ignored. Data part-way up keeps what
## it has sent.
func set_upload_priority(priority: StringName) -> void:
	if priority in [UPLOAD_OLDEST_FIRST, UPLOAD_NEWEST_FIRST, UPLOAD_MOST_VALUABLE_FIRST]:
		_upload_priority = priority
		_sending = null


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
	_pitch = move_toward(_pitch, _pitch_setting, _PITCH_RATE * dt)
	_head_activity = move_toward(_head_activity, 0.0 if _quiet_ship else 1.0,
			_HEAD_SPIN_RATE * dt)
	var power := _power * _head_activity
	var medium := _layout.medium_at(_depth)
	# The grip waves can only push as hard as the wall holds; the rest slips.
	var grip := medium.strength * _GRIP_PER_STRENGTH
	var gripped_power := minf(power, grip)
	_slip = 0.0 if power <= 0.0 else (power - gripped_power) / power
	_speed = _FULL_POWER_SPEED * gripped_power / medium.hardness
	_noise = _head_activity * _HEAD_HUM + _DRIVE_NOISE * power * (1.0 + _slip)
	var travelled := _speed * dt
	_depth += travelled
	_record_survey(_distance, _distance + travelled)
	_distance += travelled
	_update_tunnel()
	_upload(link_rate() * dt)
	if _pulse_pending:
		_pulse_pending = false
		_send_pulse()


# --- State ----------------------------------------------------------------

## Metres below the surface. Increases as the Lithocraft dives.
func depth() -> float:
	return _depth


## Degrees. +90 is nose straight down (diving), 0 level, -90 nose straight up.
func pitch() -> float:
	return _pitch


## The acceleration the crew feel in the Habitat, in m/s^2 in the Habitat
## frame, pointing the way things fall: the crew's "down". Gravity seen from
## inside the vessel.
func felt_acceleration() -> Vector3:
	var th := deg_to_rad(_pitch)
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
	return _layout.medium_at(_depth)


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
## from where the dive began, +Y up (so y = -depth), the vessel's level
## heading along -Z. The path is straight down until ticket #8 bends it.
func head_position() -> Vector3:
	return Vector3(0.0, -_depth, 0.0)


## The way the Head points in the world frame, unit length, from the pitch:
## straight down (-Y) diving, along -Z level.
func heading() -> Vector3:
	var th := deg_to_rad(_pitch)
	return Vector3(0.0, -sin(th), -cos(th))


## The Bore Station's survey so far: one SurveyStretch per completed stretch of
## the path, oldest first. A copy; changing it does not change the record.
func survey() -> Array[SurveyStretch]:
	return _survey.duplicate()


## Events raised since the last call, oldest first, then forgotten. Each is a
## Dictionary with a `type` StringName and its own fields:
##   &"tunnel_sealed" {distance}: the melt has filled the tunnel behind the
##       Tail; the link to the surface is now the slow one.
func take_events() -> Array[Dictionary]:
	var taken := _events
	_events = []
	return taken


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
	var stretch := SurveyStretch.new(_stretch_start, length,
			_stretch_quality / length, composition, main_medium, _stretch_shuttered)
	_survey.append(stretch)
	_waiting.append(stretch)
	_sending = null  # The new stretch may now be the one to send first.
	_stretch_start += length
	_stretch_minerals = {}
	_stretch_media = {}
	_stretch_quality = 0.0
	_stretch_shuttered = false


## How well the Bore Station records the Column right now, 0 to 1. Pristine
## until something spoils the Column: heat sent into it (ticket #7) and Quiet
## Ship shuttering the Bore instruments (ticket #13) lower it here.
func _recording_quality() -> float:
	return _SHUTTERED_QUALITY if shuttered() else 1.0


## The Medium of the Column at a distance along the path. The path is straight
## down for now, so distance is depth.
func _medium_at_distance(along_path: float) -> Medium:
	return _layout.medium_at(along_path)


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
	var boundaries := _boundaries_near(_depth)
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
		var r: float = (b - _depth) / down
		if r > 0.0:
			crossings.append(r)
	crossings.sort()
	var echoes := []
	var faded := 0.0
	var passed := 1.0
	var travelled := 0.0
	for r in crossings:
		var depth_at: float = _depth + down * r
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
