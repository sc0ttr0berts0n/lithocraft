## The slide of the ring of Stations and the Arm's rail along the Habitat's
## wall, from one end to the other, as "down" flips between them.
##
## The ring follows the floor: it sets off for an end once that end is the
## floor, and slides there at a steady rate. While neither end is the floor
## (near level) it stays at, or goes on to, the end it last set off for. The
## slide is free: it draws no power and cannot fail.
##
## Real basis: a carriage on a rail up the wall.
##
## It is told only how much of the felt gravity lies along the Bore; it knows
## nothing of the path, the Stations or the plasma.
##
## Owned by the simulation, which answers for it (a subsystem: see
## docs/conventions/simulation-interface.md).
class_name RingSlide
extends RefCounted

## An end is the floor once "down" points more toward it than toward the
## outer wall, as this share of the felt gravity along the Bore.
const _END_IS_FLOOR := 0.70710678
## The seconds the slide takes. Tuned for play (ADR 0001): long enough to
## watch a Station leave, short beside the turn that causes it.
const _SLIDE_S := 6.0

## Which end's floor the ring is at or sliding to.
var _to_tail := false
## How far along the slide it is, 0 at the Head end to 1 at the Tail end, at
## a steady rate (place() eases it).
var _slide := 0.0


## Slides for dt seconds. `toward_head` is the share of the felt gravity that
## lies along the Bore, 1 with the Head straight down to -1 with it straight
## up.
func step(toward_head: float, dt: float) -> void:
	if toward_head >= _END_IS_FLOOR:
		_to_tail = false
	elif toward_head <= -_END_IS_FLOOR:
		_to_tail = true
	_slide = move_toward(_slide, 1.0 if _to_tail else 0.0, dt / _SLIDE_S)


## Where the ring is along the Habitat: 0 at working height above the Head
## end floor, 1 at working height above the Tail end floor, between while it
## slides (eased, so it sets off and arrives gently).
func place() -> float:
	return smoothstep(0.0, 1.0, _slide)


## Whether the ring is sliding from one end to the other now.
func sliding() -> bool:
	return _slide != (1.0 if _to_tail else 0.0)
