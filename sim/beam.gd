## Navigation's Beam: the scan of the way ahead, a cone of sound pulses about
## an axis, in one of three widths that all spend the same energy, so the
## narrower the cone the stronger its echoes and the further it reaches (real
## basis: a phased array of sound sources, whose beam narrows as it
## concentrates the same energy into a smaller solid angle). Owned by
## DiveSimulation (_beam);
## it holds the crew's width and the switch that pulses it by itself, and
## counts the ground covered since the last pulse. It knows nothing of the
## layout, the path or the points: the simulation hands it the axis and the
## ground covered, casts its rays through the rock and asks it how strong an
## echo is.
class_name Beam
extends RefCounted

## The three widths, widest first.
const WIDE := &"wide"
const MIDDLE := &"middle"
const NARROW := &"narrow"
const WIDTHS: Array[StringName] = [WIDE, MIDDLE, NARROW]

## Each width's half-angle, degrees. The middle one is the pulse of round 3,
## and the reference its gain is counted from. Tuned for play (ADR 0001).
const _HALF_ANGLE_DEG := {WIDE: 55.0, MIDDLE: 35.0, NARROW: 15.0}
## Rays a pulse is sent as, whatever its width: the same energy, so a narrower
## cone packs them closer. Tuned for play (ADR 0001).
const _RAYS := 300
## Metres a pulse of the middle width carries through a Medium of
## sound-carrying 1 before its echo has faded to 1/e (out and back counts
## twice). Tuned for play (ADR 0001).
const _FADE_M := 500.0
## Echoes weaker than this (1 = a perfect reflection close by from the middle
## width) are lost.
const _ECHO_CUTOFF := 0.01
## Ground covered between the pulses it sends by itself, metres: about one
## stretch of new ground a pulse, so a halted vessel sends none. Tuned for
## play (ADR 0001).
const _PULSE_EVERY_M := 15.0

var _width := MIDDLE
var _pulsing := false
var _ground := 0.0


## The width the crew has set, one of WIDTHS.
func width() -> StringName:
	return _width


## Sets the width; an unknown one is ignored.
func set_width(width: StringName) -> void:
	if width in WIDTHS:
		_width = width


## The cone's half-angle, degrees.
func half_angle() -> float:
	return _HALF_ANGLE_DEG[_width]


## How much stronger this width's echoes are than the middle one's: the same
## energy spread over the cone's solid angle, so it goes as one over
## the cap's area (1 - cos of the half-angle).
func gain() -> float:
	return (1.0 - cos(deg_to_rad(_HALF_ANGLE_DEG[MIDDLE]))) / (1.0 - cos(deg_to_rad(half_angle())))


## The furthest an echo comes back from through a Medium carrying sound this
## well (0 to 1), metres: where its strength has faded to the cutoff.
func reach(sound_carrying := 1.0) -> float:
	return maxf(log(gain() / _ECHO_CUTOFF), 0.0) * _FADE_M * sound_carrying / 2.0


## How much an echo fades over `metres` out through a Medium carrying sound
## this well, and as far back (an exponent: strength goes as exp(-fading)).
static func fading(metres: float, sound_carrying: float) -> float:
	return 2.0 * metres / (sound_carrying * _FADE_M)


## An echo's strength after fading this much (fading()), before what the
## Boundaries reflect: 0 when it is too weak to hear at all.
func strength(faded: float) -> float:
	var heard := gain() * exp(-faded)
	return heard if heard >= _ECHO_CUTOFF else 0.0


## One pulse's rays about `axis` (a unit vector), spread evenly over the
## cone's solid angle, drawn from `random`.
func rays(axis: Vector3, random: RandomNumberGenerator) -> Array[Vector3]:
	var side := axis.cross(Vector3.RIGHT if absf(axis.x) < 0.9 else Vector3.UP).normalized()
	var other_side := axis.cross(side)
	var min_cos := cos(deg_to_rad(half_angle()))
	var out: Array[Vector3] = []
	for ray in _RAYS:
		var c := random.randf_range(min_cos, 1.0)
		var s := sqrt(1.0 - c * c)
		var turn := random.randf() * TAU
		out.append(axis * c + (side * cos(turn) + other_side * sin(turn)) * s)
	return out


## Whether the Beam pulses by itself as the vessel covers ground.
func pulsing() -> bool:
	return _pulsing


## The switch: on, the Beam pulses by itself once per _PULSE_EVERY_M of ground
## covered from here; off, only by hand.
func set_pulsing(on: bool) -> void:
	if on and not _pulsing:
		_ground = 0.0
	_pulsing = on


## The vessel has covered `metres` of ground: whether a pulse is now due by
## itself. Never while the switch is off, nor without ground covered.
func covered(metres: float) -> bool:
	if not _pulsing:
		return false
	_ground += maxf(metres, 0.0)
	return _ground >= _PULSE_EVERY_M


## A pulse went out, by hand or by itself: the ground is counted afresh.
func sent() -> void:
	_ground = 0.0
