# Boundaries and the Shift, tested at the simulation's interface.
# Assert relationships, never tuned constants (ADR 0001).
extends GdUnitTestSuite


## Test values only: two Media strong enough that the grip waves never slip,
## one soft and one hard, so crossing between them changes the load.
func _soft() -> Medium:
	return Medium.new(&"soft", 1.0, 3.0, 0.3, 300.0, 1.0, {&"quartz": 1.0}, 0.5)


func _hard() -> Medium:
	return Medium.new(&"hard", 4.0, 3.0, 0.3, 300.0, 1.0, {&"feldspar": 1.0}, 0.5)


## Soft rock with one Boundary into hard rock at this depth.
func _one_boundary(at := 20.0) -> DiveSimulation:
	var sim := DiveSimulation.new(MediumLayout.layered([[0.0, _soft()], [at, _hard()]]))
	sim.set_power(0.5)
	return sim


## Advances until an event of this type is raised (or the time runs out) and
## returns it, or an empty Dictionary. Every event seen is kept in `seen`.
func _run_until(sim: DiveSimulation, type: StringName, seconds := 600.0,
		seen: Array = [], step := 0.1) -> Dictionary:
	for i in int(seconds / step):
		sim.advance(step)
		for event in sim.take_events():
			seen.append(event)
			if event.type == type:
				return event
	return {}


func _types(events: Array) -> Array:
	return events.map(func(e: Dictionary) -> StringName: return e.type)


func test_a_boundary_ahead_is_announced_before_it_is_crossed() -> void:
	var sim := _one_boundary()
	var seen := []

	var crossed := _run_until(sim, &"boundary_crossed", 600.0, seen)

	assert_dict(crossed).is_not_empty()
	var types := _types(seen)
	assert_int(types.count(&"boundary_approaching")).is_equal(1)
	assert_int(types.find(&"boundary_approaching")).is_less(types.find(&"boundary_crossed"))
	assert_str(String(crossed.from)).is_equal("soft")
	assert_str(String(crossed.to)).is_equal("hard")


func test_the_boundary_is_crossed_when_the_head_enters_the_new_medium() -> void:
	var sim := _one_boundary()

	var approaching := _run_until(sim, &"boundary_approaching")
	assert_str(String(sim.medium().name)).is_equal("soft")
	_run_until(sim, &"boundary_crossed")
	assert_str(String(sim.medium().name)).is_equal("hard")
	assert_str(String(approaching.to)).is_equal("hard")
