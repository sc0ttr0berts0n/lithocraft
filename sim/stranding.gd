## Stranding, recovery and death: what losing the Head's plasma, or the hull,
## comes to. Plasma lost with the tunnel sealed behind, the Lithocraft is
## stranded: it cannot move and no tunnel leads up, until recover(). Lost with
## the tunnel still open, the crew and the Lithocraft are brought home up it.
## Whenever the Lithocraft reaches the surface its repair is billed: the hull's
## wear and the Head's. A hull worn through by heat fails and
## the crew dies, with an Elite-style rebuy of the vessel. Owned by
## DiveSimulation, which asks it once a step what the vessel's state comes to
## and carries that out on the survey, the link and the vessel's place; it
## answers stranded() and dead() through it. Knows nothing of the survey or
## the path: whatever it needs is handed in.
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
const DIED := &"died"

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
## What repairing a hull worn through costs, in the units of paid(), charged
## in proportion to the wear whenever the Lithocraft reaches the surface. Less
## than the rebuy even for a hull all but failed. Tuned for play (ADR 0001).
const _HULL_REPAIR_COST := 1200.0
## What replacing a Lithocraft lost with its crew costs, in the units of
## paid(): the rebuy after the hull fails. A share of the vessel's worth, as in
## Elite; well above any repair. Tuned for play (ADR 0001).
const _REBUY_COST := 2000.0

## True once the plasma is lost while sealed in: the dive is over until
## recover().
var _stranded := false
## Energy left in the emergency store, in the units of set_power() x seconds.
## Full at the start of a dive; nothing recharges it until the next.
var _store := _STORE_CAPACITY
## True once the hull has failed: the crew is dead and the dive is over.
var _dead := false


## Once a step: what the vessel's state comes to now. DIED the step the hull
## fails (from then on dead() is true, stranded() false), whatever the plasma,
## stranded or not: the stranding clock running out is death too; STRANDED the step
## the plasma is lost with the tunnel sealed (from then on stranded() is true);
## BROUGHT_HOME the step it is lost with the tunnel open; NOTHING otherwise,
## and every step after any of them.
func check(plasma_lost: bool, tunnel_sealed: bool, hull_failed: bool) -> StringName:
	if _dead:
		return NOTHING
	if hull_failed:
		_dead = true
		_stranded = false
		return DIED
	if _stranded:
		return NOTHING
	if not plasma_lost:
		return NOTHING
	if not tunnel_sealed:
		return BROUGHT_HOME
	_stranded = true
	return STRANDED


## True once the plasma has been lost while sealed in.
func stranded() -> bool:
	return _stranded


## True once the hull has failed.
func dead() -> bool:
	return _dead


## What replacing the Lithocraft costs after the hull fails, in the units of
## paid().
func rebuy() -> float:
	return _REBUY_COST


## What repairing a hull this worn (0 to 1) costs at the surface, in the
## units of paid(). Repair is repair: only wear is billed, never running hours.
func hull_repair(vessel_wear: float) -> float:
	return vessel_wear * _HULL_REPAIR_COST


## What repairing a Head this worn (0 to 1) costs at the surface, in the units
## of paid(). Repair is repair: only wear is billed, never running hours.
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
