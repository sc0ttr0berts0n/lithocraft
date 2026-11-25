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

var _layout: MediumLayout
var _power := 0.0
var _depth := 0.0
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


func _init(layout: MediumLayout) -> void:
	_layout = layout


# --- Commands -------------------------------------------------------------

## Drive Station: the share of available power sent to advancing, 0 to 1.
func set_power(power: float) -> void:
	_power = clampf(power, 0.0, 1.0)


# --- Time step ------------------------------------------------------------

func advance(dt: float) -> void:
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


# --- State ----------------------------------------------------------------

## Metres below the surface. Increases as the Lithocraft dives.
func depth() -> float:
	return _depth


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


## The Bore Station's survey so far: one SurveyStretch per completed stretch of
## the path, oldest first. A copy; changing it does not change the record.
func survey() -> Array[SurveyStretch]:
	return _survey.duplicate()


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
	_survey.append(SurveyStretch.new(_stretch_start, length,
			_stretch_quality / length, composition, main_medium))
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
