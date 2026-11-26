## Each Station's Caution lamps: a labelled lamp, lit while one cause is
## pulling the Station's system down (GLOSSARY.md), each cause its own lamp.
## Real basis: an airliner's annunciator panel, one labelled light per fault.
##
## Plain view logic over the simulation's queries: of() is what a Station's
## header strip shows (StationScreen.show_lamps()). A lamp keeps its place
## whether lit or not, so the crew learn where each one is.
##
## A new lamp is one line in of(): its label and the query that lights it. A
## cause with no query of its own gets a small function here, as head_worn().
class_name CautionLamps
extends RefCounted

const HEAD_WORN := "HEAD WORN"
const SHIFT_DUE := "SHIFT DUE"
const SLIPPING := "SLIPPING"
const HULL_HOT := "HULL HOT"
const LOW_POWER := "LOW POWER"
const TUNNEL_SEALING := "TUNNEL SEALING"


## The lamps of a Station (the simulation's name for it), left to right: each
## {label = the words on it, lit = whether its cause holds now}.
static func of(sim: DiveSimulation, station: StringName) -> Array[Dictionary]:
	match station:
		DiveSimulation.STATION_REACTOR:
			return [_lamp(HEAD_WORN, head_worn(sim)), _lamp(SHIFT_DUE, sim.shift_due())]
		DiveSimulation.STATION_DRIVE:
			return [_lamp(SLIPPING, sim.slip() > 0.0), _lamp(LOW_POWER, sim.drive_supplied() < 1.0)]
		DiveSimulation.STATION_THERMAL:
			return [_lamp(HULL_HOT, sim.heat_warning()), _lamp(LOW_POWER, sim.thermal_supplied() < 1.0)]
		DiveSimulation.STATION_NAVIGATION:
			return [_lamp(LOW_POWER, sim.navigation_supplied() < 1.0)]
		DiveSimulation.STATION_BORE:
			return [_lamp(TUNNEL_SEALING,
					sim.call_reason(DiveSimulation.STATION_BORE) == &"tunnel_about_to_seal")]
	return []


## Whether the Head is worn enough to tell on the plasma: from the first
## whole percent its wear reads on the Reactor's screen, so the lamp and the
## reading agree. The one place the Reactor's worn-Head lamp reads the
## simulation: repoint it here when the plasma gains a query of its own for
## "the Head's wear is narrowing what it tolerates".
static func head_worn(sim: DiveSimulation) -> bool:
	return roundi(sim.head_wear() * 100.0) >= 1


static func _lamp(label: String, lit: bool) -> Dictionary:
	return {label = label, lit = lit}
