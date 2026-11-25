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


# --- Time step ------------------------------------------------------------

func advance(dt: float) -> void:
	_pitch = move_toward(_pitch, _pitch_setting, _PITCH_RATE * dt)
	var medium := _layout.medium_at(_depth)
	_depth += _FULL_POWER_SPEED * _power / medium.hardness * dt


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
