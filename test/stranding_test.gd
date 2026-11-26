# Stranding, rescue and coming home through the tunnel, tested at the simulation's interface. Assert
# relationships, never tuned constants (ADR 0001).
extends GdUnitTestSuite

## Long enough for a careless dive to wear its Head through, in simulated
## seconds, and the step to run it in.
const PLENTY_S := 20000.0
const STEP_S := 0.25


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
## each needing a Shift nobody makes: the Reactor's autopilot's late Shifts
## wear the Head until the plasma is lost.
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
	sim.set_autopilot(DiveSimulation.STATION_REACTOR, true)
	return sim


func test_losing_the_plasma_sealed_in_strands_with_the_survey_aboard_and_calls_a_rescue() -> void:
	var sim := _careless_dive()
	var unsold := [0.0]
	var seen := []

	var stranded := DiveTestKit.run_until(sim, &"stranded", PLENTY_S, seen, STEP_S,
			func() -> void: unsold[0] = sim.unsold_value())

	assert_dict(stranded).is_not_empty()
	var types := DiveTestKit.types(seen)
	assert_array(types).contains([&"tunnel_sealed", &"plasma_lost"])
	assert_int(types.find(&"tunnel_sealed")).is_less(types.find(&"stranded"))
	assert_int(types.find(&"plasma_lost")).is_less(types.find(&"stranded"))
	assert_bool(sim.stranded()).is_true()
	# There was survey aboard, and it is still aboard while stranded.
	assert_float(unsold[0]).is_greater(0.0)
	assert_float(stranded.aboard).is_greater_equal(unsold[0])
	assert_float(sim.unsold_value()).is_equal(stranded.aboard)
	# A rescue is on its way, against the clock.
	assert_float(stranded.rescue_time).is_greater(0.0)
	assert_float(stranded.rescue_time).is_equal(sim.rescue_time())
	assert_float(stranded.clock).is_greater(0.0)


func test_losing_the_plasma_with_the_tunnel_open_does_not_strand() -> void:
	var sim := _careless_dive(40.0, false)
	var seen := []

	var lost := DiveTestKit.run_until(sim, &"plasma_lost", PLENTY_S, seen, STEP_S)
	DiveTestKit.run_until(sim, &"never", 60.0, seen, STEP_S)

	assert_dict(lost).is_not_empty()
	assert_bool(sim.tunnel_sealed()).is_false()
	assert_bool(sim.stranded()).is_false()
	assert_array(DiveTestKit.types(seen)).not_contains([&"stranded"])


func test_losing_the_plasma_with_the_tunnel_open_brings_the_crew_home_through_it() -> void:
	var sim := _careless_dive(40.0, false)
	var before := {unsold = 0.0, paid = 0.0}
	var seen := []

	var home := DiveTestKit.run_until(sim, &"brought_home", PLENTY_S, seen, STEP_S,
			func() -> void: before.merge({unsold = sim.unsold_value(), paid = sim.paid()}, true))

	assert_dict(home).is_not_empty()
	var types := DiveTestKit.types(seen)
	assert_int(types.find(&"plasma_lost")).is_less(types.find(&"brought_home"))
	assert_array(types).not_contains([&"stranded"])
	assert_bool(sim.stranded()).is_false()
	# Back at the surface, the dive over.
	assert_bool(sim.surfaced()).is_true()
	assert_float(sim.depth()).is_less_equal(0.0)
	# As on surfacing, &"paid" follows with the breakdown, telling how it came
	# home.
	assert_int(types.find(&"brought_home")).is_less(types.find(&"paid"))
	var paid: Dictionary = seen[types.find(&"paid")]
	assert_that(paid.arrival).is_equal(home)
	# Unlike a stranding, the survey aboard (the stretch being recorded, at
	# least) is kept and sold on return...
	assert_float(paid.carried_home).is_greater(0.0)
	assert_float(paid.carried_home).is_greater_equal(before.unsold)
	assert_float(sim.unsold_value()).is_equal(0.0)
	assert_int(sim.survey().size()).is_equal(sim.uploaded_survey().size())
	# ...and the worn Head is paid for out of it, any of the bill beyond what
	# the dive earned covered.
	assert_float(paid.head_repair).is_greater(0.0)
	assert_float(sim.paid()).is_equal_approx(before.paid + paid.carried_home
			- paid.head_repair - paid.hull_repair + paid.covered, 0.001)
	# What went up the link under way is never less than nothing.
	assert_float(paid.by_link).is_greater_equal(0.0)


func test_after_coming_home_through_the_tunnel_the_crew_can_dive_again() -> void:
	var sim := _careless_dive(40.0, false)
	DiveTestKit.run_until(sim, &"brought_home", PLENTY_S, [], STEP_S)
	var paid := sim.paid()

	sim.new_dive()
	var types := DiveTestKit.types(sim.take_events())
	sim.set_power(1.0)
	DiveTestKit.run(sim, 30.0, STEP_S)

	assert_array(types).contains([&"new_dive"])
	assert_bool(sim.plasma_lost()).is_false()
	assert_float(sim.head_wear()).is_equal(0.0)
	assert_float(sim.depth()).is_greater(10.0)
	assert_float(sim.paid()).is_greater_equal(paid)


## Strands `sim`, waits for the rescue, and starts another dive.
func _rescued_and_diving_again(sim: DiveSimulation) -> void:
	DiveTestKit.run_until(sim, &"stranded", PLENTY_S, [], STEP_S)
	DiveTestKit.run_until(sim, &"rescued", PLENTY_S, [], 1.0)
	sim.new_dive()


func test_a_rescue_keeps_what_was_paid_and_returns_to_the_surface() -> void:
	var sim := _careless_dive()
	DiveTestKit.run_until(sim, &"stranded", PLENTY_S, [], STEP_S)
	var paid := sim.paid()
	var up := sim.uploaded_survey().size()
	assert_float(paid).is_greater(0.0)

	var seen := []
	DiveTestKit.run_until(sim, &"rescued", PLENTY_S, seen, 1.0)
	sim.new_dive()
	sim.advance(0.25)
	var events := DiveTestKit.types(seen + sim.take_events())

	assert_array(events).contains([&"rescued", &"paid", &"new_dive"])
	assert_bool(sim.stranded()).is_false()
	# What was paid is kept, less the rescue and the repairs (any beyond what
	# the dive earned covered), and what was aboard is paid for on top.
	var bill: Dictionary = seen.back()
	assert_float(sim.paid()).is_equal_approx(paid + bill.carried_home - bill.rescue
			- bill.hull_repair - bill.head_repair + bill.covered, 0.001)
	assert_int(sim.uploaded_survey().size()).is_greater(up)
	# Back at the surface with a fresh vessel: nothing aboard, nothing lost.
	assert_float(sim.depth()).is_less(1.0)
	assert_bool(sim.tunnel_sealed()).is_false()
	assert_bool(sim.plasma_lost()).is_false()
	assert_float(sim.head_wear()).is_equal(0.0)
	assert_float(sim.unsold_value()).is_equal(0.0)


func test_after_a_rescue_the_crew_can_dive_again_and_be_paid_more() -> void:
	var sim := _careless_dive()
	_rescued_and_diving_again(sim)
	var paid := sim.paid()
	sim.take_events()

	sim.set_power(1.0)
	for i in 120:
		sim.advance(0.25)

	assert_float(sim.depth()).is_greater(10.0)
	assert_float(sim.speed()).is_greater(0.0)
	assert_float(sim.paid()).is_greater(paid)


func test_a_stranding_is_a_reactor_call_that_returns_the_time_rate_to_normal() -> void:
	var sim := _careless_dive()
	# Keep raising the rate after each call, as an impatient crew might.
	DiveTestKit.run_until(sim, &"stranded", PLENTY_S, [], STEP_S,
			func() -> void: sim.set_time_rate(sim.max_time_rate()))

	assert_str(String(sim.call_reason(DiveSimulation.STATION_REACTOR))).is_equal("stranded")
	assert_float(sim.call_urgency(DiveSimulation.STATION_REACTOR)).is_equal(1.0)
	assert_float(sim.time_rate()).is_equal(1.0)


func test_a_dive_after_a_rescue_starts_at_normal_time_with_the_crew_where_they_were() -> void:
	var sim := _careless_dive()
	sim.set_attended(DiveSimulation.STATION_NAVIGATION, true)
	DiveTestKit.run_until(sim, &"stranded", PLENTY_S, [], STEP_S)
	sim.set_time_rate(sim.max_time_rate())

	DiveTestKit.run_until(sim, &"rescued", PLENTY_S, [], 1.0)
	sim.new_dive()

	assert_float(sim.time_rate()).is_equal(1.0)
	assert_bool(sim.attended(DiveSimulation.STATION_NAVIGATION)).is_true()
	assert_float(sim.call_urgency(DiveSimulation.STATION_REACTOR)).is_equal(0.0)


func test_everything_a_new_dive_keeps_is_a_variable_of_the_simulation() -> void:
	# A variable renamed but left under its old name in the list would
	# silently stop being kept.
	var sim := DiveSimulation.new(MediumLayout.uniform(_open_rock()))
	var variables := []
	for property in sim.get_property_list():
		if property.usage & PROPERTY_USAGE_SCRIPT_VARIABLE:
			variables.append(StringName(property.name))

	assert_array(DiveSimulation._KEPT_BETWEEN_DIVES).is_not_empty()
	for kept in DiveSimulation._KEPT_BETWEEN_DIVES:
		assert_array(variables).contains([kept])
