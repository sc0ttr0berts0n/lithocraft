## How an echo is heard, whichever of Navigation's tools sent the sound: how
## much it fades through the rock out and back, how its strength grows as the
## same energy is put into a narrower beam, and how weak it may be before it
## is lost. Static functions, no state; the Beam (sim/beam.gd) and the Sweep
## (sim/sweep.gd) each hand in their own gain, and DiveSimulation's
## _echoes_along() asks these for every ray. It knows nothing of the layout.
class_name Echoes
extends RefCounted

## The half-angle, degrees, of the beam whose gain is 1: the Beam's middle
## width, round 3's pulse. Not tuned: the reference gains are counted from.
const REFERENCE_HALF_ANGLE_DEG := 35.0
## Metres a sound of gain 1 carries through a Medium of sound-carrying 1
## before its echo has faded to 1/e (out and back counts twice). Tuned for
## play (ADR 0001).
const _FADE_M := 500.0
## Echoes weaker than this (1 = a perfect reflection close by at gain 1) are
## lost.
const _ECHO_CUTOFF := 0.01
## The most an echo's contrast, as heard, can be off the truth with next to
## no confidence, as a share of the contrast (contrast_heard()). Under 1, so
## an unsure scan misjudges how much harder or softer the rock beyond is,
## never which way. Tuned for play (ADR 0001).
const _CONTRAST_ERROR := 0.6


## How much stronger the echoes of a beam this wide (its half-angle, degrees)
## are than the reference's, for the same energy: one over the cap of the
## sphere it is spread over (1 - cos of the half-angle).
static func gain_of(half_angle_deg: float) -> float:
	return (1.0 - cos(deg_to_rad(REFERENCE_HALF_ANGLE_DEG))) / (1.0 - cos(deg_to_rad(half_angle_deg)))


## The furthest an echo of this gain comes back from through a Medium carrying
## sound this well (0 to 1), metres: where its strength has faded to the
## cutoff.
static func reach(gain: float, sound_carrying := 1.0) -> float:
	return maxf(log(gain / _ECHO_CUTOFF), 0.0) * _FADE_M * sound_carrying / 2.0


## How much an echo fades over `metres` out through a Medium carrying sound
## this well, and as far back (an exponent: strength goes as exp(-fading)).
static func fading(metres: float, sound_carrying: float) -> float:
	return 2.0 * metres / (sound_carrying * _FADE_M)


## An echo's strength at this gain after fading this much (fading()), before
## what the Boundaries reflect: 0 when it is too weak to hear at all.
static func strength(gain: float, faded: float) -> float:
	var heard := gain * exp(-faded)
	return heard if heard >= _ECHO_CUTOFF else 0.0


## The contrast an echo of this confidence (0 to 1) carries of a Boundary
## whose true contrast is `truth` (-1 to 1: the rock beyond against the rock
## the sound came through, positive harder and denser), as heard from that
## side: off the truth by a share of it that shrinks with the square of the
## doubt, as STANDBY's guess of the Wobble is off (WobbleGuess), and the same
## way as that guess errs for the same Boundary (`boundary_seed`,
## WobbleGuess.error_of()): where the guess puts the rock beyond harder than
## it is, so does this, so the two never disagree on which way they are
## wrong. Real basis: an echo's polarity gives which way the acoustic
## impedance changes across a Boundary, and its strength by how much, but the
## strength only as well as the sound's losses on the way are known, which a
## noisy echo tells worse.
static func contrast_heard(truth: float, confidence: float, boundary_seed: int) -> float:
	var doubt := 1.0 - clampf(confidence, 0.0, 1.0)
	var off := absf(truth) * WobbleGuess.error_of(boundary_seed) * _CONTRAST_ERROR * doubt * doubt
	return clampf(truth + off, -1.0, 1.0)
