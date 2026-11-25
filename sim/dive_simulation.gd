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


func _init(layout: MediumLayout) -> void:
	_layout = layout


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


# --- Time step ------------------------------------------------------------

func advance(dt: float) -> void:
	_pitch = move_toward(_pitch, _pitch_setting, _PITCH_RATE * dt)
	var medium := _layout.medium_at(_depth)
	# The grip waves can only push as hard as the wall holds; the rest slips.
	var grip := medium.strength * _GRIP_PER_STRENGTH
	var gripped_power := minf(_power, grip)
	_slip = 0.0 if _power <= 0.0 else (_power - gripped_power) / _power
	_speed = _FULL_POWER_SPEED * gripped_power / medium.hardness
	var travelled := _speed * dt
	_depth += travelled
	_record_survey(_distance, _distance + travelled)
	_distance += travelled
	_update_tunnel()
	_upload(link_rate() * dt)


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
			_stretch_quality / length, composition, main_medium)
	_survey.append(stretch)
	_waiting.append(stretch)
	_sending = null  # The new stretch may now be the one to send first.
	_stretch_start += length
	_stretch_minerals = {}
	_stretch_media = {}
	_stretch_quality = 0.0


## How well the Bore Station records the Column right now, 0 to 1. Pristine
## until something spoils the Column: heat sent into it (ticket #7) and Quiet
## Ship shuttering the Bore instruments (ticket #13) lower it here.
func _recording_quality() -> float:
	return 1.0


## The Medium of the Column at a distance along the path. The path is straight
## down for now, so distance is depth.
func _medium_at_distance(along_path: float) -> Medium:
	return _layout.medium_at(along_path)
