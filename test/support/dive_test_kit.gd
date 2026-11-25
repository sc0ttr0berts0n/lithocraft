## Helpers shared by the simulation's test suites: test Media and ways of
## running a dive. Test values only, never tuned constants (ADR 0001).
class_name DiveTestKit
extends RefCounted


## Test values only: plain quartz rock. Defaults are strong enough that the
## grip waves never slip at full power.
static func rock(hardness := 2.0, strength := 2.0, porosity := 0.05) -> Medium:
	return Medium.new(&"rock", hardness, strength, porosity, 300.0, 1.0, {&"quartz": 1.0}, 0.5)


## Test values only: basalt, a pyroxene and plagioclase rock that carries
## sound well.
static func basalt(hardness := 1.0, strength := 0.5, porosity := 0.05) -> Medium:
	return Medium.new(&"basalt", hardness, strength, porosity, 300.0, 1.0,
			{&"pyroxene": 0.5, &"plagioclase": 0.5}, 0.8)


## Advances the simulation `seconds` in steps of `step` and returns it.
static func run(sim: DiveSimulation, seconds: float, step := 1.0) -> DiveSimulation:
	for i in int(seconds / step):
		sim.advance(step)
	return sim


## Advances in steps of `step` until an event of this type is raised (or the
## time runs out) and returns it, or an empty Dictionary. Every event taken is
## kept in `seen`, the whole of the step that raised the one wanted included.
## `before` is called before each step.
static func run_until(sim: DiveSimulation, type: StringName, seconds := 600.0,
		seen: Array = [], step := 0.1, before := Callable()) -> Dictionary:
	for i in int(seconds / step):
		if before.is_valid():
			before.call()
		sim.advance(step)
		var events := sim.take_events()
		seen.append_array(events)
		for event in events:
			if event.type == type:
				return event
	return {}


## The types of these events, in order.
static func types(events: Array) -> Array:
	return events.map(func(e: Dictionary) -> StringName: return e.type)
