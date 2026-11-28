## What the crew can know of the Boundary ahead: the Inferred Boundary along
## the Head's direction, the countdown to it with its plus-or-minus, and the
## scan's guess of the Wobble beyond it (WobbleGuess), which STANDBY previews.
##
## Everything here that says where a Boundary is, when it comes or how sure
## that is comes from the patches fitted to Navigation's points
## (BoundaryFit.ahead()) and from the Head's own movement, and from nothing
## else. It is told two more things, both of which the crew have by other
## means: that a crossing was felt (the Wobble on the plasma changed), and the
## Wobble the echoes carry of the rock beyond, which the guess degrades by the
## scan's doubt. It is never told where a Boundary truly lies, so a scan that
## puts one where none is misleads the countdown and the guess alike (design
## record: "Topology is honest").
##
## Real basis: a reflection survey places a reflector by its echoes' travel
## times alone and is wrong by as much as they are; a driller knows a
## formation top was passed by the change at the bit, not from the survey.
##
## Owned by the simulation, which answers for it (a subsystem: see
## docs/conventions/simulation-interface.md).
class_name LookAhead
extends RefCounted

## The Boundary countdown reads as beyond this many seconds when the scan
## cannot say better. Tuned for play (ADR 0001): five minutes.
const _COUNTDOWN_CAP_S := 300.0
## The countdown's plus-or-minus, as a share of the distance to the Inferred
## Boundary ahead when its confidence is nothing; it shrinks to nothing as the
## confidence rises to 1. Tuned for play (ADR 0001): the truth lies inside it.
const _COUNTDOWN_DOUBT := 0.25
## Metres added to that distance, so the doubt does not vanish as the Head
## closes on an Inferred Boundary it is not sure of. Tuned for play (ADR 0001).
const _COUNTDOWN_NEAR_M := 10.0
## How far the scan is allowed to be out, in metres along the path. Run this
## far past where it put a Boundary with no crossing felt, the scan was wrong
## and that Boundary is given up; and a crossing felt spends whatever the scan
## put within this far ahead of it, as the Boundary just crossed. Tuned for
## play (ADR 0001): wider than a worked-at scan's scatter, narrower than the
## Media's layers.
const _SCAN_OUT_M := 15.0
## A sighting this close, in metres, when the line stops meeting it was
## reached, not turned away from. Tuned (ADR 0001): a few steps' travel.
const _REACHED_M := 1.0

## The Inferred Boundary ahead as the scan has it now.
var _sighting := Sighting.new()
## Where along the path (metres since the dive began) the sighting lies.
var _sighting_at := INF
## Path distance up to which what the scan shows is taken for a Boundary
## already crossed.
var _spent_until := -INF
## True from a crossing felt until settle(): the guess stays as it was.
var _holding := false
var _guess := WobbleGuess.of(Vector2.ZERO, 0.0, 0)


## The Inferred Boundary ahead, from the scan alone.
class Sighting:
	extends RefCounted
	## Metres to it along the Head's direction: INF with none ahead, 0 once the
	## Head has come to where the scan put it.
	var metres := INF
	## How sure the scan is of it, 0 to 1.
	var confidence := 0.0
	## Metres the Head has run past where the scan put it with no crossing
	## felt: it is overdue by this much.
	var overdue := 0.0

	func seen() -> bool:
		return not is_inf(metres)


## Looks ahead from `origin` along `direction` (a unit vector) with the Head
## `distance` metres along its path, at these patches. `beyond` is the Wobble
## the echoes carry, Vector2(frequency in hertz, amplitude), and
## `beyond_seed` fixes which way the guess of it errs. Does nothing while a
## crossing felt is being settled into (holding()).
func look(patches: Array[BoundaryPatch], origin: Vector3, direction: Vector3, distance: float,
		beyond: Vector2, beyond_seed: int) -> void:
	if _holding:
		return
	var found := BoundaryFit.ahead(patches, origin, direction, maxf(0.0, _spent_until - distance))
	if not is_inf(found.x):
		_sighting.metres = found.x
		_sighting.confidence = found.y
		_sighting.overdue = 0.0
		_sighting_at = distance + found.x
	elif _sighting.seen() and _sighting_at - distance <= _REACHED_M \
			and distance - _sighting_at <= _SCAN_OUT_M:
		# The Head has come to where the scan put it and nothing was felt.
		_sighting.metres = 0.0
		_sighting.overdue = maxf(0.0, distance - _sighting_at)
	else:
		_sighting = Sighting.new()
		_sighting_at = INF
	_guess = WobbleGuess.of(beyond, _sighting.confidence, beyond_seed)


## A crossing was felt with the Head `distance` metres along its path: the
## guess holds as it was until settle(), and what the scan put just ahead is
## that Boundary, not another.
func felt_crossing(distance: float) -> void:
	_holding = true
	_spent_until = distance + _SCAN_OUT_M
	_sighting = Sighting.new()
	_sighting_at = INF


## The vessel has come to rest in rock it reached without a Wobble on the
## plasma (a Glide): `guess` is the scan's guess of that rock, and it is held,
## as after a crossing felt, until settle(), so STANDBY reads against the rock
## round the vessel while the crew tune it.
func hold(guess: WobbleGuess) -> void:
	_holding = true
	_guess = guess
	_sighting = Sighting.new()
	_sighting_at = INF


## True from a crossing felt until settle().
func holding() -> bool:
	return _holding


## The crossing is behind: the next look() looks to the next Boundary.
func settle() -> void:
	_holding = false


## The scan's guess of the Wobble beyond the Inferred Boundary ahead, as sure
## as that Boundary is; held as it was while holding().
func guess() -> WobbleGuess:
	return _guess


## Seconds until the Head reaches the Inferred Boundary ahead at this speed
## (metres a second): 0 once it is overdue, INF with none ahead, when
## stopped, or beyond the cap.
func countdown(speed: float) -> float:
	if not _sighting.seen() or speed <= 0.0:
		return INF
	var seconds := _sighting.metres / speed
	return INF if seconds > _COUNTDOWN_CAP_S else seconds


## The countdown's plus-or-minus, in seconds: smaller the better resolved the
## Inferred Boundary ahead is, and growing by every metre it is overdue. INF
## while countdown() is.
func countdown_doubt(speed: float) -> float:
	if is_inf(countdown(speed)):
		return INF
	var unsure := (_sighting.metres + _COUNTDOWN_NEAR_M) * (1.0 - _sighting.confidence) \
			* _COUNTDOWN_DOUBT
	return (unsure + _sighting.overdue) / speed


## The seconds beyond which the countdown says no more than "beyond this".
func countdown_cap() -> float:
	return _COUNTDOWN_CAP_S
