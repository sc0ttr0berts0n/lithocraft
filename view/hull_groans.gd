## When the hull groans as it creeps, how loud, and from where round the ring.
## A metal hull creeping under heat and load gives off sound as it deforms
## (acoustic emission, as a ship's hull or a loaded beam does): more often and
## louder the more it has already given and the harder it is stressed. Silent
## while it bears its heat. View logic: fed from DiveSimulation's
## hull_taking_damage(), vessel_wear() and hull_stress(); HullFeel plays what
## it decides. Constants are tuned for play (ADR 0001).
class_name HullGroans
extends RefCounted

## Mean seconds between groans from a fresh hull at the surface's stress.
const _CALM_INTERVAL_S := 9.0
## How much more often a fully worn hull groans than a fresh one.
const _WEAR_FREQUENCY_GAIN := 4.0
## Loudness of a groan from a fresh hull at the surface's stress, 0 to 1.
const _QUIETEST := 0.25
## How fast loudness climbs toward full with wear, and with stress above the
## surface's.
const _WEAR_LOUDNESS_GAIN := 1.5
const _STRESS_LOUDNESS_GAIN := 0.6

var _rng := RandomNumberGenerator.new()
## Seconds to the next groan; below 0 while none is due (not creeping).
var _until_next := -1.0


## `seed_value` makes the groans repeatable (tests); 0 seeds at random.
func _init(seed_value := 0) -> void:
	if seed_value == 0:
		_rng.randomize()
	else:
		_rng.seed = seed_value


## One step of dt seconds. Returns the groans that start now, each
## {angle = radians round the ring (Habitat frame, from +X toward +Y),
## loudness = 0 to 1}. None while the hull is not creeping.
func step(dt: float, creeping: bool, wear: float, stress: float) -> Array[Dictionary]:
	var groans: Array[Dictionary] = []
	if not creeping:
		_until_next = -1.0
		return groans
	if _until_next < 0.0:
		_until_next = _next_wait(wear, stress)
	_until_next -= dt
	while _until_next <= 0.0:
		groans.append({angle = _rng.randf() * TAU, loudness = _loudness(wear, stress)})
		_until_next += _next_wait(wear, stress)
	return groans


func _next_wait(wear: float, stress: float) -> float:
	var mean := _CALM_INTERVAL_S / ((1.0 + _WEAR_FREQUENCY_GAIN * clampf(wear, 0.0, 1.0)) * maxf(stress, 1.0))
	return mean * _rng.randf_range(0.5, 1.5)


func _loudness(wear: float, stress: float) -> float:
	var strain := _WEAR_LOUDNESS_GAIN * clampf(wear, 0.0, 1.0) + _STRESS_LOUDNESS_GAIN * (maxf(stress, 1.0) - 1.0)
	var loudness := 1.0 - (1.0 - _QUIETEST) * exp(-strain)
	return loudness * _rng.randf_range(0.85, 1.0)
