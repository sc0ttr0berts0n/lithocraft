# Stranding and recovery, tested at the simulation's interface. Assert
# relationships, never tuned constants (ADR 0001).
extends GdUnitTestSuite


## Test values only. Porous rock the melt lines, so the tunnel stays open and
## the fast link pays for what goes up.
func _open_rock() -> Medium:
	return Medium.new(&"open", 1.0, 3.0, 0.5, 300.0, 1.0, {&"quartz": 1.0}, 0.5)


## Dense rock, soft and hard by turns: the tunnel seals behind the Tail, and it
## carries no sound, so nothing more goes up once sealed in.
func _dense_soft() -> Medium:
	return Medium.new(&"dense_soft", 1.0, 3.0, 0.0, 300.0, 1.0, {&"quartz": 1.0}, 0.0)


func _dense_hard() -> Medium:
	return Medium.new(&"dense_hard", 4.0, 3.0, 0.0, 300.0, 1.0, {&"feldspar": 1.0}, 0.0)


## Open rock down to `open_to` m, then dense rock with a Boundary every 15 m,
## each needing a Shift nobody makes: the autopilot's late Shifts wear the Head
## until the plasma is lost.
func _careless_dive(open_to := 40.0, dense := true) -> DiveSimulation:
	var layers := [[0.0, _open_rock()]]
	for i in 40:
		var hard := i % 2 == 0
		var medium: Medium
		if dense:
			medium = _dense_hard() if hard else _dense_soft()
		else:
			medium = Medium.new(&"hard" if hard else &"soft", 4.0 if hard else 1.0,
					3.0, 0.5, 300.0, 1.0, {&"quartz": 1.0}, 0.5)
		layers.append([open_to + i * 15.0, medium])
	var sim := DiveSimulation.new(MediumLayout.layered(layers))
	sim.set_power(1.0)
	return sim


## Advances until an event of this type is raised (or time runs out) and
## returns it, or an empty Dictionary. Every event seen is kept in `seen`.
## `before` is called before each step.
func _run_until(sim: DiveSimulation, type: StringName, seconds := 20000.0,
		seen: Array = [], before := Callable()) -> Dictionary:
	var step := 0.25
	for i in int(seconds / step):
		if before.is_valid():
			before.call()
		sim.advance(step)
		for event in sim.take_events():
			seen.append(event)
			if event.type == type:
				return event
	return {}


func _types(events: Array) -> Array:
	return events.map(func(e: Dictionary) -> StringName: return e.type)


func test_losing_the_plasma_sealed_in_strands_and_discards_the_unsold_survey() -> void:
	var sim := _careless_dive()
	var unsold := [0.0]
	var seen := []

	var stranded := _run_until(sim, &"stranded", 20000.0, seen,
			func() -> void: unsold[0] = sim.unsold_value())

	assert_dict(stranded).is_not_empty()
	var types := _types(seen)
	assert_array(types).contains([&"tunnel_sealed", &"plasma_lost"])
	assert_int(types.find(&"tunnel_sealed")).is_less(types.find(&"stranded"))
	assert_int(types.find(&"plasma_lost")).is_less(types.find(&"stranded"))
	assert_bool(sim.stranded()).is_true()
	# There was survey aboard to lose, and it is gone.
	assert_float(unsold[0]).is_greater(0.0)
	assert_float(stranded.lost).is_greater_equal(unsold[0])
	assert_float(sim.unsold_value()).is_equal(0.0)
	assert_array(sim.unsold_survey()).is_empty()
	# What is left of the survey is only what reached the surface.
	assert_int(sim.survey().size()).is_equal(sim.uploaded_survey().size())


func test_losing_the_plasma_with_the_tunnel_open_does_not_strand() -> void:
	var sim := _careless_dive(40.0, false)
	var seen := []

	var lost := _run_until(sim, &"plasma_lost", 20000.0, seen)
	_run_until(sim, &"never", 60.0, seen)

	assert_dict(lost).is_not_empty()
	assert_bool(sim.tunnel_sealed()).is_false()
	assert_bool(sim.stranded()).is_false()
	assert_array(_types(seen)).not_contains([&"stranded"])


func test_a_recovery_keeps_what_was_paid_and_returns_to_the_surface() -> void:
	var sim := _careless_dive()
	_run_until(sim, &"stranded")
	var paid := sim.paid()
	var up := sim.uploaded_survey().size()
	assert_float(paid).is_greater(0.0)

	sim.recover()
	sim.advance(0.25)
	var events := _types(sim.take_events())

	assert_array(events).contains([&"recovered"])
	assert_bool(sim.stranded()).is_false()
	assert_float(sim.paid()).is_equal(paid)
	assert_int(sim.uploaded_survey().size()).is_equal(up)
	# Back at the surface with a fresh vessel: nothing aboard, nothing lost.
	assert_float(sim.depth()).is_less(1.0)
	assert_bool(sim.tunnel_sealed()).is_false()
	assert_bool(sim.plasma_lost()).is_false()
	assert_float(sim.head_wear()).is_equal(0.0)
	assert_float(sim.unsold_value()).is_equal(0.0)


func test_after_a_recovery_the_crew_can_dive_again_and_be_paid_more() -> void:
	var sim := _careless_dive()
	_run_until(sim, &"stranded")
	var paid := sim.paid()
	sim.recover()
	sim.take_events()

	sim.set_power(1.0)
	for i in 120:
		sim.advance(0.25)

	assert_float(sim.depth()).is_greater(10.0)
	assert_float(sim.speed()).is_greater(0.0)
	assert_float(sim.paid()).is_greater(paid)


func test_a_recovery_is_only_for_a_stranded_dive() -> void:
	var sim := _careless_dive()
	for i in 80:
		sim.advance(0.25)
	var depth := sim.depth()

	sim.recover()

	assert_float(sim.depth()).is_equal(depth)
	assert_array(_types(sim.take_events())).not_contains([&"recovered"])


func test_a_stranding_is_a_reactor_call_that_returns_the_time_rate_to_normal() -> void:
	var sim := _careless_dive()
	# Keep raising the rate after each call, as an impatient crew might.
	_run_until(sim, &"stranded", 20000.0, [],
			func() -> void: sim.set_time_rate(sim.max_time_rate()))

	assert_str(String(sim.call_reason(DiveSimulation.STATION_REACTOR))).is_equal("stranded")
	assert_float(sim.call_urgency(DiveSimulation.STATION_REACTOR)).is_equal(1.0)
	assert_float(sim.time_rate()).is_equal(1.0)


func test_a_recovery_starts_at_normal_time_with_the_crew_where_they_were() -> void:
	var sim := _careless_dive()
	sim.set_attended(DiveSimulation.STATION_NAVIGATION, true)
	_run_until(sim, &"stranded")
	sim.set_time_rate(sim.max_time_rate())

	sim.recover()

	assert_float(sim.time_rate()).is_equal(1.0)
	assert_bool(sim.attended(DiveSimulation.STATION_NAVIGATION)).is_true()
	assert_float(sim.call_urgency(DiveSimulation.STATION_REACTOR)).is_equal(0.0)
