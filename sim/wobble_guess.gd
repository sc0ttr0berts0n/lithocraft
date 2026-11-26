## The scan's guess of the Wobble in the Medium beyond the Boundary ahead:
## what STANDBY's lane previews. A sum of sines: the true Wobble, placed off
## the truth in frequency and amplitude by an error, and spurious sines beside
## it. Both the error and the spurious sines shrink as the Inferred Boundary
## ahead is better resolved, until the true sine stands out. With no scan of
## the Boundary there is no true component: spurious sines only.
##
## Real basis: every signal is a sum of sines (Fourier); an echo carries the
## contrast between the rock either side of a Boundary, so its returns say
## something of the rock beyond; seismic surveys stack repeated shots, which
## reinforces the coherent echo while incoherent ones cancel, so more and
## cleaner returns sharpen the estimate.
##
## Plain data, made by of(); DiveSimulation holds one and answers for it.
## Which way a Boundary's guess errs, and its spurious sines, are fixed by
## the Boundary (`boundary_seed`), so a guess only ever sharpens or blurs
## with its confidence and never jitters.
class_name WobbleGuess
extends RefCounted

## The most the guess's true component can be off the truth, with next to no
## confidence: in frequency as a share of the true frequency, and in
## amplitude. It is at least half this, one way or the other, so a poor scan
## always misleads somewhat. Tuned for play (ADR 0001): a Counter-wave
## prepared flat against a poor guess leaves a Residual well outside a fresh
## Head's Band, against a well-resolved one a Residual inside it.
const _FREQUENCY_ERROR := 0.25
const _AMPLITUDE_ERROR := 0.25
## The spurious sines: how many, the frequencies they are found between (in
## hertz, about the span of the Media's Wobbles) and the amplitudes, with no
## confidence at all. Tuned for play (ADR 0001): unscanned, they are about as
## big as a Wobble between them.
const _SPURIOUS := 3
const _SPURIOUS_HZ_LOW := 0.5
const _SPURIOUS_HZ_HIGH := 2.6
const _SPURIOUS_AMPLITUDE_LOW := 0.2
const _SPURIOUS_AMPLITUDE_HIGH := 0.4

## The true component as the scan places it: Vector2(frequency in hertz,
## amplitude), off the truth by the guess's error. NAN in both parts when
## there is none.
var wobble := Vector2(NAN, NAN)
## The spurious sines, each Vector3(frequency in hertz, amplitude, phase in
## radians).
var spurious: Array[Vector3] = []
## How sure the guess is, 0 (no scan: spurious sines only) to 1.
var confidence := 0.0


## The guess of the Wobble `truth` (frequency in hertz, amplitude) beyond a
## Boundary resolved with this `confidence`, 0 to 1. No confidence: no true
## component.
static func of(truth: Vector2, p_confidence: float, boundary_seed: int) -> WobbleGuess:
	var guess := WobbleGuess.new()
	guess.confidence = clampf(p_confidence, 0.0, 1.0)
	var doubt := 1.0 - guess.confidence
	var random := RandomNumberGenerator.new()
	random.seed = boundary_seed
	# The error falls off faster than the spurious sines do, so a scan worked
	# at leaves a Counter-wave prepared against it inside the Band while its
	# ripple still shows.
	var frequency_error := _error(random) * _FREQUENCY_ERROR * doubt * doubt
	var amplitude_error := _error(random) * _AMPLITUDE_ERROR * doubt * doubt
	if guess.confidence > 0.0:
		guess.wobble = Vector2(truth.x * (1.0 + frequency_error),
				maxf(0.0, truth.y + amplitude_error))
	for i in _SPURIOUS:
		guess.spurious.append(Vector3(
				random.randf_range(_SPURIOUS_HZ_LOW, _SPURIOUS_HZ_HIGH),
				random.randf_range(_SPURIOUS_AMPLITUDE_LOW, _SPURIOUS_AMPLITUDE_HIGH) * doubt,
				random.randf() * TAU))
	return guess


## Which way and how far an error goes, of the most it can: -1 to -0.5 or 0.5
## to 1.
static func _error(random: RandomNumberGenerator) -> float:
	return random.randf_range(0.5, 1.0) * (1.0 if random.randf() < 0.5 else -1.0)


## True when the guess has a true component: the Boundary ahead is scanned.
func has_wobble() -> bool:
	return not is_nan(wobble.x)


## The spurious sines' amplitudes summed: the most they add to the guess.
func spurious_reach() -> float:
	var total := 0.0
	for sine in spurious:
		total += sine.y
	return total
