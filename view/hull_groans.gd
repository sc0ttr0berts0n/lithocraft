## When the hull groans as it creeps, how loud, and from where round the ring.
## A metal hull creeping under heat and load gives off sound as it deforms
## (acoustic emission, as a ship's hull or a loaded beam does): more often and
## louder the more it has already given and the harder it is stressed. Silent
## while it bears its heat. While the crew holds the self-destruct command it
## groans too, more often and louder the longer it is held: the hold is felt
## before it is armed. View logic: fed from DiveSimulation's
## hull_taking_damage(), vessel_wear(), hull_stress() and
## self_destruct_hold(); HullFeel plays what it decides. Constants are tuned
## for play (ADR 0001).
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
## How much more often, and how much louder, the hull groans with the
## self-destruct command held all the way, so a three-second hold is heard
## rising to it.
const _ARMING_FREQUENCY_GAIN := 20.0
const _ARMING_LOUDNESS_GAIN := 2.5

var _rng := RandomNumberGenerator.new()
## How long to the next groan, in mean waits (each wait is as long as the
## mean is now, so a quickening hull brings the next groan sooner); below 0
## while none is due (not creeping, not held).
var _until_next := -1.0


## `seed_value` makes the groans repeatable (tests); 0 seeds from the global
## generator: at random in play, repeatable once that is seeded (the
## screenshot tool), since when a groan comes decides what the sparks and the
## shake draw next.
func _init(seed_value := 0) -> void:
	_rng.seed = randi() if seed_value == 0 else seed_value


## One step of dt seconds. Returns the groans that start now, each
## {angle = radians round the ring (Habitat frame, from +X toward +Y),
## loudness = 0 to 1}. None while the hull is not creeping and the
## self-destruct command is not held (`arming`, 0 to 1, how far it has been
## held toward starting).
func step(dt: float, creeping: bool, wear: float, stress: float,
		arming := 0.0) -> Array[Dictionary]:
	var groans: Array[Dictionary] = []
	if not creeping and arming <= 0.0:
		_until_next = -1.0
		return groans
	if _until_next < 0.0:
		_until_next = _next_wait()
	_until_next -= dt / _mean_wait(wear, stress, arming)
	while _until_next <= 0.0:
		groans.append({angle = _rng.randf() * TAU, loudness = _loudness(wear, stress, arming)})
		_until_next += _next_wait()
	return groans


## Mean seconds between groans now.
func _mean_wait(wear: float, stress: float, arming: float) -> float:
	return _CALM_INTERVAL_S / ((1.0 + _WEAR_FREQUENCY_GAIN * clampf(wear, 0.0, 1.0))
			* maxf(stress, 1.0) * (1.0 + _ARMING_FREQUENCY_GAIN * clampf(arming, 0.0, 1.0)))


## The next wait, in mean waits.
func _next_wait() -> float:
	return _rng.randf_range(0.5, 1.5)


func _loudness(wear: float, stress: float, arming: float) -> float:
	var strain := _WEAR_LOUDNESS_GAIN * clampf(wear, 0.0, 1.0) \
			+ _STRESS_LOUDNESS_GAIN * (maxf(stress, 1.0) - 1.0) \
			+ _ARMING_LOUDNESS_GAIN * clampf(arming, 0.0, 1.0)
	var loudness := 1.0 - (1.0 - _QUIETEST) * exp(-strain)
	return loudness * _rng.randf_range(0.85, 1.0)
