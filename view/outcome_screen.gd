## The still outcome screen (play test finding 15): every dive ends with a
## lurch that settles to still, then a sentence that names how it ended
## (DiveSimulation.outcome()) above the payment breakdown. View logic: the
## Habitat calls start() as the dive ends, adds step() to the crew's shake in
## place of every other shake, and shows the breakdown once still().
class_name OutcomeScreen
extends RefCounted

## The least the end of a dive lurches, metres, so even a quiet ending is felt.
## Tuned for feel (ADR 0001).
const _LEAST_LURCH_M := 0.02
## How fast the lurch dies away (its time constant) and when it is fully
## still, in seconds. Tuned for feel (ADR 0001).
const _LURCH_S := 0.3
const _SETTLE_S := 1.2

## The lurch's starting shake, metres, and seconds since it began; NAN before
## a dive has ended.
var _peak := 0.0
var _age := NAN


## The dive has ended with the view shaking `shaking_m`: the lurch starts
## from that, or from a least lurch if that is less.
func start(shaking_m: float) -> void:
	_peak = maxf(shaking_m, _LEAST_LURCH_M)
	_age = 0.0


## A new dive: nothing to lurch, and not still until the next dive ends.
func reset() -> void:
	_peak = 0.0
	_age = NAN


## One frame of `delta` seconds on: the lurch's shake now, in metres. It dies
## away and is exactly 0 once settled, the frame still() turns true; 0
## before a dive has ended.
func step(delta: float) -> float:
	if is_nan(_age):
		return 0.0
	_age += delta
	return _shake_at(_age)


## True once the lurch has settled: the screen is still, so the outcome and
## its breakdown can show.
func still() -> bool:
	return not is_nan(_age) and _age >= _SETTLE_S


## True while the lurch is still settling: the dive has ended but its outcome
## is not yet shown. A new dive waits until it is, so Enter cannot skip the
## outcome screen.
func settling() -> bool:
	return not is_nan(_age) and _age < _SETTLE_S


## The lurch's shake `age` seconds after the dive ended: an exponential
## settling, faded to exactly 0 at _SETTLE_S so it ends still, not on a jump.
func _shake_at(age: float) -> float:
	return _peak * exp(-age / _LURCH_S) * maxf(0.0, 1.0 - age / _SETTLE_S)


## How the dive ended, in a sentence, from DiveSimulation.outcome(); empty
## while the dive is under way.
static func sentence(outcome: Dictionary) -> String:
	var depth := "%.0f m" % outcome.depth
	var stranded_for: float = outcome.stranded_for
	match outcome.ending:
		&"surfaced":
			return "Surfaced under the Lithocraft's own power."
		&"brought_home":
			return "Brought home up the open tunnel from %s: %s." % [depth,
					_plasma_lost(outcome.cause)]
		&"rescued":
			return "Rescued from %s after %s stranded: %s." % [depth,
					_spoken(stranded_for), _plasma_lost(outcome.cause)]
		&"dead":
			if outcome.cause == &"self_destruct":
				if stranded_for > 0.0:
					return "Dead at %s: stranded %s, the crew chose self-destruct." % [
							depth, _spoken(stranded_for)]
				return "Dead at %s: the crew chose self-destruct and cooked the hull through." % depth
			if stranded_for > 0.0:
				return "Dead at %s: stranded %s, the rock's heat soaked in and failed the hull before the rescue came." % [
						depth, _spoken(stranded_for)]
			return "Dead at %s: heat wore the hull through." % depth
	return ""


## Why the plasma was lost, as a clause.
static func _plasma_lost(by: StringName) -> String:
	match by:
		&"disrupted":
			return "a rough Shift on a worn Head disrupted the plasma"
		&"worn_through":
			return "a poor Shift wore the Head through and lost the plasma"
		&"scenario":
			return "the Scenario began with the Head dark"
		&"debug":
			return "the debug menu put the plasma out"
	return "the plasma was lost"


## A stretch of time as said aloud: under a minute, minutes, or hours and
## minutes.
static func _spoken(seconds: float) -> String:
	var minutes := roundi(seconds / 60.0)
	if minutes < 1:
		return "under a minute"
	if minutes < 60:
		return "%d min" % minutes
	return "%d h %d min" % [minutes / 60, minutes % 60]
