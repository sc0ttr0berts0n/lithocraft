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

## Length of the Column inside the vessel, from the Head to the Tail, in
## metres. A guess for play (ADR 0001); tests read column_length().
const _HEAD_TO_TAIL_M := 9.0
## Seconds of observation the Bore Station needs to record a feature in full
## at pristine recording quality. Tuned for play (ADR 0001) so that at full
## power a feature can slip out through the Tail half recorded.
const _FEATURE_RECORD_S := 15.0

## Habitat frame: the fixed axes of the vessel that felt_acceleration() is
## given in. TOWARD_HEAD runs along the Bore toward the Head. TOWARD_UNDERSIDE
## is the outer wall that is underneath when the vessel is level.
const TOWARD_HEAD := Vector3.FORWARD
const TOWARD_UNDERSIDE := Vector3.DOWN

## How fast the vessel pitches toward its setting, degrees per second.
## Slow enough to keep footing as "down" turns. Tuned for play (ADR 0001);
## tests must not depend on its value.
const _PITCH_RATE := 5.0

## Earth's surface gravity, m/s^2.
const _GRAVITY := 9.81

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
## Features of interest the Head has found, in the order found.
var _features: Array[ColumnFeature] = []
## Layout feature templates already found, so crossing one again adds nothing.
var _found_templates := {}
## The id of the feature the Bore Station is observing, or -1 for none.
var _observed := -1


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


## Bore Station: which feature in the Column to observe and record, by id
## (see features_in_column()). -1, or a feature not now in the Column, observes
## nothing. Observing records; nothing is ever cut out of the Column.
func set_observed_feature(id: int) -> void:
	if id >= 0 and id < _features.size() and _in_column(_features[id]):
		_observed = id
	else:
		_observed = -1


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
	var depth_before := _depth
	_depth += travelled
	_record_survey(_distance, _distance + travelled)
	_record_observed_feature(dt, travelled)
	_find_features(depth_before, _depth, travelled)
	_distance += travelled


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


## Metres of Column inside the vessel, from the Head to the Tail. A feature is
## in the Column while it is between 0 and this far behind the Head.
func column_length() -> float:
	return _HEAD_TO_TAIL_M


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
		var inside := minf(behind_after, _HEAD_TO_TAIL_M) - maxf(behind_before, 0.0)
		seconds_inside = maxf(inside, 0.0) / travelled * dt
	feature.recorded = minf(1.0,
			feature.recorded + seconds_inside * _recording_quality() / _FEATURE_RECORD_S)
	if behind_after > _HEAD_TO_TAIL_M:
		_observed = -1


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
	return behind >= 0.0 and behind <= _HEAD_TO_TAIL_M


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
