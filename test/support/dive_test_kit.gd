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


## Where the gimbal of the Station with this name pivots (Habitat frame).
static func station_pivot(name: String) -> Vector3:
	return _Habitat.pivot(station_place(name))


## The simulation's name for the Station with this name on its screen
## (DiveSimulation.STATION_*), or &"".
static func station_sim_name(name: String) -> StringName:
	var place := station_place(name)
	return &"" if place < 0 else _Habitat.STATIONS[place][2]


## A Habitat in the suite's tree, freed with the test, that steps only when
## the test tells it (`habitat._physics_process(STEP)`): the staged Habitat
## every Habitat-level test starts from. It plays `scenario`, or the First
## dive.
static func staged_habitat(suite: GdUnitTestSuite, scenario: Scenario = null) -> Node3D:
	var habitat: Node3D = suite.auto_free((load("res://view/habitat.tscn") as PackedScene).instantiate())
	if scenario != null:
		habitat.scenario = scenario
	suite.add_child(habitat)
	habitat.set_physics_process(false)
	return habitat


## The Station of a Habitat with this name on its screen, or null.
static func station(habitat: Node3D, name: String) -> GimballedStation:
	for child in habitat.get_children():
		if child is GimballedStation and (child as GimballedStation).station_name == name:
			return child
	return null


## Every Station of a Habitat, the empty mount left out, in order round the
## ring.
static func stations(habitat: Node3D) -> Array[GimballedStation]:
	var found: Array[GimballedStation] = []
	for place in station_places():
		found.append(station(habitat, station_name(place)))
	return found


## Waits until a screen's Containers have placed its readings: two frames.
## Call with `await`.
static func laid_out(suite: GdUnitTestSuite) -> void:
	await suite.get_tree().process_frame
	await suite.get_tree().process_frame


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


## Sets a channel's Counter-wave (DiveSimulation.CHANNEL_ACTIVE or
## CHANNEL_STANDBY) to `wave`, Vector2(frequency in hertz, amplitude), as the
## crew does: select the channel, tune it, and select back what was selected.
static func tune(sim: DiveSimulation, channel: StringName, wave: Vector2) -> void:
	var selected := sim.selected_channel()
	sim.select_channel(channel)
	sim.tune_frequency(wave.x)
	sim.tune_amplitude(wave.y)
	sim.select_channel(selected)


## The Wobble on the plasma now, as Vector2(frequency in hertz, amplitude).
static func wobble(sim: DiveSimulation) -> Vector2:
	return Vector2(sim.wobble_frequency(), sim.wobble_amplitude())


## A channel's Counter-wave, as Vector2(frequency in hertz, amplitude).
static func counter_wave(sim: DiveSimulation, channel: StringName) -> Vector2:
	return Vector2(sim.counter_wave_frequency(channel), sim.counter_wave_amplitude(channel))


## A Shift straight to the Counter-wave `wave`: STANDBY prepared with it, then
## the swap, made on the next step.
static func shift_to(sim: DiveSimulation, wave: Vector2) -> void:
	tune(sim, DiveSimulation.CHANNEL_STANDBY, wave)
	sim.shift()


## ACTIVE's Counter-wave set to cancel the Wobble now exactly, as a crew
## tuning ACTIVE by hand would in the end: a flat Residual from the next step.
static func cancel_wobble(sim: DiveSimulation) -> void:
	tune(sim, DiveSimulation.CHANNEL_ACTIVE, wobble(sim))


## Holds ACTIVE's amplitude a little too big, its steady Residual just
## outside the Band (never far enough out to disrupt the plasma), until the
## Head's wear reaches `wear` or the plasma is lost; then cancels the Wobble
## again. Run with the vessel at rest or in one Medium.
static func wear_head_gently(sim: DiveSimulation, wear: float) -> void:
	for i in 20000:
		if sim.plasma_lost() or sim.head_wear() >= wear:
			break
		tune(sim, DiveSimulation.CHANNEL_ACTIVE, wobble(sim) + Vector2(0.0, 2.0 * sim.band()))
		sim.advance(5.0)
	if not sim.plasma_lost():
		cancel_wobble(sim)
		sim.advance(0.1)
	sim.take_events()


## Stops the Drive, lets the hull cool, wears the Head gently to a little more
## than half, then drives ACTIVE's Counter-wave far too big, a Residual far
## outside the Band, which disrupts the plasma on the worn Head, short of
## wearing it through. Sealed in, that strands the Lithocraft where it stands.
static func lose_plasma(sim: DiveSimulation) -> void:
	sim.set_power(0.0)
	run(sim, 600.0, 1.0)
	wear_head_gently(sim, 0.51)
	tune(sim, DiveSimulation.CHANNEL_ACTIVE, wobble(sim) + Vector2(0.0, 10.0))
	for i in 600:
		if sim.plasma_lost():
			return
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


## Advances in steps of `step` (the time rate raised before each, if `fast`)
## until `done` holds of the sim or `seconds` have passed, taking the events.
## Returns whether it held.
static func fly_until(sim: DiveSimulation, done: Callable, seconds := 3000.0,
		step := 1.0, fast := true) -> bool:
	for i in int(seconds / step):
		if done.call(sim):
			return true
		if fast:
			sim.set_time_rate(sim.max_time_rate())
		sim.advance(step)
		sim.take_events()
	return done.call(sim)


## Nudges an attended Drive until it steers this many degrees off where it
## steers now (as near as whole nudges come): heading + to the right, pitch +
## steeper down.
static func nudge(sim: DiveSimulation, heading_degrees: float, pitch_degrees: float) -> void:
	for i in roundi(absf(pitch_degrees) / sim.nudge_degrees()):
		sim.nudge_pitch(pitch_degrees)
	for i in roundi(absf(heading_degrees) / sim.nudge_degrees()):
		sim.nudge_heading(heading_degrees)


## The Wobble this Medium puts on the plasma, as Vector2(frequency in hertz,
## amplitude), read from a dive in it.
static func wobble_in(medium: Medium) -> Vector2:
	return wobble(DiveSimulation.new(MediumLayout.uniform(medium)))


## The fullest size the wave `wave(seconds)` reaches in each of `count`
## stretches of `stretch` seconds, one after another from now: steady when
## they are all alike, beating when they swell and fade.
static func swells(wave: Callable, stretch: float, count: int) -> Array[float]:
	var sizes: Array[float] = []
	for i in count:
		var size := 0.0
		for j in 40:
			size = maxf(size, absf(wave.call((i + j / 40.0) * stretch)))
		sizes.append(size)
	return sizes


## A Quiet Ship scan as a crew makes one: Quiet Ship on, wait until the
## vessel is still and silent, `pulses` pulses, Quiet Ship off again.
static func quiet_scan(sim: DiveSimulation, pulses := 3) -> void:
	sim.set_quiet_ship(true)
	for i in 600:
		sim.advance(0.1)
		if sim.speed() == 0.0 and sim.noise() == 0.0:
			break
	for i in pulses:
		sim.pulse()
		sim.advance(0.1)
	sim.set_quiet_ship(false)
	sim.advance(0.1)


## The scan's guess of the Wobble ahead (DiveSimulation.wobble_ahead_*), as
## Vector2(frequency in hertz, amplitude); NAN in both with no scan of it.
static func wobble_ahead(sim: DiveSimulation) -> Vector2:
	return Vector2(sim.wobble_ahead_frequency(), sim.wobble_ahead_amplitude())
