## A Station's power, as its screen reads it: the set point (what it asks for)
## against the actual (what the Reactor gave it), each a share of the Reactor's
## full output, and "starved" when the actual falls short of the set point.
class_name PowerLine
extends RefCounted


## "Power: set 8% · actual 3%: starved". requested and drawn are in the units
## of DiveSimulation.set_power(); full is DiveSimulation.reactor_full_output().
static func text(requested: float, drawn: float, full: float) -> String:
	var line := "Power: set %d%% · actual %d%%" % [percent(requested, full), percent(drawn, full)]
	return line + ": starved" if starved(requested, drawn, full) else line


## Whether the actual, as shown, is below the set point. A shortfall too small
## to show is not called starved, so the line never contradicts itself.
static func starved(requested: float, drawn: float, full: float) -> bool:
	return percent(drawn, full) < percent(requested, full)


## power as a whole-number percentage of the Reactor's full output.
static func percent(power: float, full: float) -> int:
	return roundi(power / full * 100.0)
