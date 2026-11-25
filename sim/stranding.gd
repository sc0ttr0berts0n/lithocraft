## Stranding and recovery: what losing the Head's plasma comes to. Lost with
## the tunnel sealed behind, the Lithocraft is stranded: it cannot move and no
## tunnel leads up, until recover(). Lost with the tunnel still open, the crew
## and the Lithocraft are brought home up it, and the worn Head's repair is
## billed. Owned by DiveSimulation, which asks it once a step what the plasma's
## state comes to and carries that out on the survey, the link and the
## vessel's place; it answers stranded() through it. Knows nothing of the
## survey or the path: whatever it needs is handed in.
##
## It also holds the emergency store: the one store of energy the Lithocraft
## falls back on once the plasma is lost. Whatever runs while the Head is dark
## (the link, a relight, cooling) draws on it through draw() or pay(), so every
## choice while stranded spends the same store.
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
## Energy the emergency store holds when full, in the units of set_power()
## times seconds: a couple of relights, or the slow link for an hour or so,
## not both. Tuned for play (ADR 0001). Real basis: a tokamak cannot restart
## itself; JET struck its plasmas from huge flywheel generators.
const _STORE_CAPACITY := 100.0

## True once the plasma is lost while sealed in: the dive is over until
## recover().
var _stranded := false
## Energy left in the emergency store, in the units of set_power() x seconds.
## Full at the start of a dive; nothing recharges it until the next.
var _store := _STORE_CAPACITY


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


## The Head has been relit from the store: the stranding is over and the dive
## goes on. Losing the plasma again strands it again.
func relit() -> void:
	_stranded = false


## Energy left in the emergency store.
func store() -> float:
	return _store


## Energy the emergency store holds when full.
func store_capacity() -> float:
	return _STORE_CAPACITY


## Draws up to `energy` from the store for something that can run on less
## (the link, cooling) and returns what it got: all of it, or what was left.
func draw(energy: float) -> float:
	var granted := clampf(energy, 0.0, _store)
	_store -= granted
	return granted


## Pays `energy` from the store for something that needs all of it at once
## (a relight's pulse): true and spent if the store holds that much, else
## false and nothing spent.
func pay(energy: float) -> bool:
	if energy > _store:
		return false
	_store -= energy
	return true
