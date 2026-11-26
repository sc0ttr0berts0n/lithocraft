## Helpers shared by the test suites: test Media, ways of running a dive,
## and reading the Habitat's layout. Test values only, never tuned constants
## (ADR 0001).
class_name DiveTestKit
extends RefCounted

const _Habitat := preload("res://view/habitat.gd")


## The Habitat's places that have a Station on them, in order round the
## ring (the empty mount left out): the Stations the Arm carries to.
static func station_places() -> Array[int]:
	var places: Array[int] = []
	for place in _Habitat.STATIONS.size():
		if not station_name(place).is_empty():
			places.append(place)
	return places


## The name of the Station at a place round the ring, "" for the empty mount.
static func station_name(place: int) -> String:
	return _Habitat.STATIONS[place][0]


## The place round the ring of the Station with this name, or -1.
static func station_place(name: String) -> int:
	for place in _Habitat.STATIONS.size():
		if station_name(place) == name:
			return place
	return -1


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


## Gentle Shifts, each a little wide of the wobble, until the Head's wear
## reaches `wear` or the plasma is lost: each Shift wears the Head a little,
## never roughly enough to disrupt the plasma.
static func wear_head_gently(sim: DiveSimulation, wear: float) -> void:
	var on := sim.plasma_frequency()
	var off := 0.01
	for i in 2000:
		if sim.plasma_lost() or sim.head_wear() >= wear:
			return
		sim.shift(on * (1.0 + off))
		sim.advance(0.1)
		var results := sim.take_events().filter(
				func(e: Dictionary) -> bool: return e.type == &"shift_result")
		# Keep each Shift's wear small: wider while clean or barely worn,
		# closer once it wears more.
		if results[0].wear < 0.02:
			off *= 1.1
		elif results[0].wear > 0.05:
			off *= 0.9


## Stops the Drive, lets the hull cool, wears the Head gently to a little more
## than half, then makes Shifts well wide of the wobble until one disrupts the
## plasma on the worn Head, short of wearing it through. Sealed in, that
## strands the Lithocraft where it stands. The hull is let cool first, since a
## hot hull makes each Shift wear the Head harder.
static func lose_plasma(sim: DiveSimulation) -> void:
	sim.set_power(0.0)
	run(sim, 600.0, 1.0)
	wear_head_gently(sim, 0.51)
	var on := sim.plasma_frequency()
	for i in 20:
		if sim.plasma_lost():
			return
		sim.shift(on * 1.5)
		sim.advance(0.1)


## The state of the Checklist step with this id: DONE, PENDING or MISSED, or
## &"" if the Checklist has no such step.
static func step_state(sim: DiveSimulation, id: StringName) -> StringName:
	for phase in sim.checklist():
		for step in phase.steps:
			if step.id == id:
				return step.state
	return &""


## Whether the goal of the Orders with this id is achieved.
static func achieved(sim: DiveSimulation, id: StringName) -> bool:
	for goal in sim.orders():
		if goal.id == id:
			return goal.achieved
	return false


## The id of the Checklist's next step, or &"" when none is left.
static func next_step_id(sim: DiveSimulation) -> StringName:
	return sim.next_step().get("id", &"")


## The title of the Checklist phase now running.
static func phase_title(sim: DiveSimulation) -> String:
	return sim.checklist()[sim.checklist_phase()].title
