## Stranding and recovery: what losing the Head's plasma comes to. Lost with
## the tunnel sealed behind, the Lithocraft is stranded: it cannot move and no
## tunnel leads up, until recover(). Lost with the tunnel still open, the crew
## and the Lithocraft are brought home up it, and the worn Head's repair is
## billed. Owned by DiveSimulation, which asks it once a step what the plasma's
## state comes to and carries that out on the survey, the link and the
## vessel's place; it answers stranded() through it. Knows nothing of the
## survey or the path: whatever it needs is handed in.
class_name Stranding
extends RefCounted

## What check() finds losing the plasma comes to.
const NOTHING := &""
const STRANDED := &"stranded"
const BROUGHT_HOME := &"brought_home"

## What repairing a Head worn through costs, in the units of paid(), charged
## in proportion to the wear when the crew is brought home through the open
## tunnel. About a few hundred metres of good survey. Tuned for play
## (ADR 0001).
const _HEAD_REPAIR_COST := 500.0

## True once the plasma is lost while sealed in: the dive is over until
## recover().
var _stranded := false


## Once a step: what the plasma's state comes to now. STRANDED the step the
## plasma is lost with the tunnel sealed (from then on stranded() is true);
## BROUGHT_HOME the step it is lost with the tunnel open; NOTHING otherwise,
## and every step after either.
func check(plasma_lost: bool, tunnel_sealed: bool) -> StringName:
	if _stranded or not plasma_lost:
		return NOTHING
	if not tunnel_sealed:
		return BROUGHT_HOME
	_stranded = true
	return STRANDED


## True once the plasma has been lost while sealed in.
func stranded() -> bool:
	return _stranded


## What repairing a Head this worn (0 to 1) costs when the crew is brought
## home, in the units of paid().
func head_repair(head_wear: float) -> float:
	return head_wear * _HEAD_REPAIR_COST
