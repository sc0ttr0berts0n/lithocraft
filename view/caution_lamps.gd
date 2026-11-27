## Each Station's Caution lamps: a labelled lamp, lit while one cause is
## pulling the Station's system down (GLOSSARY.md), each cause its own lamp.
## Real basis: an airliner's annunciator panel, one labelled light per fault.
##
## Plain view logic over the simulation's queries: of() is what a Station's
## header strip shows (StationScreen.show_lamps()). A lamp keeps its place
## whether lit or not, so the crew learn where each one is.
##
## A new lamp is one line in of(): its label and the query that lights it.
## The Reactor's are the causes the simulation names for an unsteady plasma
## (DiveSimulation.steadiness_causes()), one lamp each.
class_name CautionLamps
extends RefCounted

const HEAD_WORN := "HEAD WORN"
const HOT := "HOT"
const OUT_OF_BAND := "OUT OF BAND"
const SLIPPING := "SLIPPING"
const HULL_HOT := "HULL HOT"
const LOW_POWER := "LOW POWER"
const TUNNEL_SEALING := "TUNNEL SEALING"


## The lamps of a Station (the simulation's name for it), left to right: each
## {label = the words on it, lit = whether its cause holds now}.
static func of(sim: DiveSimulation, station: StringName) -> Array[Dictionary]:
	match station:
		DiveSimulation.STATION_REACTOR:
			var causes := sim.steadiness_causes()
			return [_lamp(HEAD_WORN, DiveSimulation.CAUSE_WORN in causes),
					_lamp(HOT, DiveSimulation.CAUSE_HOT in causes),
					_lamp(OUT_OF_BAND, DiveSimulation.CAUSE_OUT_OF_BAND in causes)]
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


static func _lamp(label: String, lit: bool) -> Dictionary:
	return {label = label, lit = lit}
