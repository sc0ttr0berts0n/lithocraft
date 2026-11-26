## The deviation in words: how far the Drive steers off the Course, as every
## screen that states it writes it, so the Drive's and Navigation's cannot
## disagree. Plain view logic over the simulation's deviation_pitch() and
## deviation_heading().
class_name CourseDeviation
extends RefCounted


## The deviation of this dive now: "30 deg up", "15 deg down, 45 deg right",
## or "" while the Drive follows the Course.
static func of(sim: DiveSimulation) -> String:
	return text(sim.deviation_pitch(), sim.deviation_heading())


## A deviation in words, from its pitch (+ steeper down, as the simulation
## signs pitch) and heading (+ to the right), in degrees; "" for none.
static func text(pitch: float, heading: float) -> String:
	var parts := PackedStringArray()
	if roundi(pitch) != 0:
		parts.append("%d deg %s" % [absi(roundi(pitch)), "down" if pitch > 0.0 else "up"])
	if roundi(heading) != 0:
		parts.append("%d deg %s" % [absi(roundi(heading)), "right" if heading > 0.0 else "left"])
	return ", ".join(parts)
