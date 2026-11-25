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

## How fast the vessel pitches toward its setting, degrees per second.
## Slow enough to keep footing as "down" turns. Tuned for play (ADR 0001);
## tests must not depend on its value.
const _PITCH_RATE := 5.0

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
## How much warmer the ground gets per metre of depth, in kelvin. Earth's crust
## warms by about 0.025 K/m; tuned for play (ADR 0001).
const _GEOTHERMAL_K_PER_M := 0.03
## Wear per second for each kelvin the hull is above _HULL_DAMAGE_K. Tuned for
## play (ADR 0001).
const _WEAR_PER_K_S := 1.0e-5

var _layout: MediumLayout
var _power := 0.0
var _depth := 0.0
var _pitch := 90.0
var _pitch_setting := 90.0
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


func _init(layout: MediumLayout) -> void:
	_layout = layout
	_vessel_temperature = surroundings_temperature()


# --- Commands -------------------------------------------------------------

## Drive Station: the share of available power sent to advancing, 0 to 1.
func set_power(power: float) -> void:
	_power = clampf(power, 0.0, 1.0)


## Drive: the pitch to steer toward, in degrees. +90 is nose straight down
## (diving), 0 is level, -90 is nose straight up (climbing).
func set_pitch(degrees: float) -> void:
	_pitch_setting = clampf(degrees, -90.0, 90.0)


## Thermal Station: the share of the heat sent into the Column, 0 to 1. The
## rest goes outward into the surrounding Medium through the hull.
func set_heat_split(to_column: float) -> void:
	_heat_split = clampf(to_column, 0.0, 1.0)


# --- Time step ------------------------------------------------------------

func advance(dt: float) -> void:
	_pitch = move_toward(_pitch, _pitch_setting, _PITCH_RATE * dt)
	var medium := _layout.medium_at(_depth)
	# The grip waves can only push as hard as the wall holds; the rest slips.
	var grip := medium.strength * _GRIP_PER_STRENGTH
	var gripped_power := minf(_power, grip)
	_slip = 0.0 if _power <= 0.0 else (_power - gripped_power) / _power
	_speed = _FULL_POWER_SPEED * gripped_power / medium.hardness
	# Every system that draws power makes heat; power lost to slip included.
	_heat_produced = _power * _HEAT_PER_POWER
	_heat_to_column = _heat_produced * _heat_split
	_shed_heat_outward(_heat_produced - _heat_to_column, dt)
	var travelled := _speed * dt
	_depth += travelled
	_record_survey(_distance, _distance + travelled)
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
	return _layout.medium_at(_depth).temperature + _GEOTHERMAL_K_PER_M * _depth


## Damage heat has done to the vessel so far, 0 (none) to 1. It only grows
## while the hull is hotter than it can bear.
func vessel_wear() -> float:
	return _vessel_wear


# --- Heat -----------------------------------------------------------------

## Passes heat outward through the hull for dt seconds. The hull settles toward
## the temperature at which it sheds that heat into the Medium, and wears for
## as long as it is above the temperature it can bear.
func _shed_heat_outward(heat: float, dt: float) -> void:
	var settled := surroundings_temperature() + heat / _HULL_SHED_PER_K
	var toward := exp(-dt * _HULL_SHED_PER_K / _HULL_HEAT_PER_K)
	_vessel_temperature = settled + (_vessel_temperature - settled) * toward
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
	return _unheated_share()


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


## The Medium of the Column at a distance along the path. The path is straight
## down for now, so distance is depth.
func _medium_at_distance(along_path: float) -> Medium:
	return _layout.medium_at(along_path)
