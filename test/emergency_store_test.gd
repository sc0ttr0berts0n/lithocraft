# The emergency store and the relight, tested at the simulation's interface.
# Assert relationships, never tuned constants (ADR 0001).
extends GdUnitTestSuite


## Test values only. Dense rock the melt fills behind the Tail, so the tunnel
## seals almost at once, but it carries sound, so the slow link still works.
func _dense() -> Medium:
	return Medium.new(&"dense", 1.0, 3.0, 0.0, 300.0, 1.0, {&"quartz": 1.0}, 0.8)


## A dive in dense rock, sealed in with survey aboard, its plasma lost by poor
## Shifts: stranded. Rough Shifts disrupt the plasma on a worn Head short of
## wearing it through; gentle ones (`gently`) wear the Head through.
func _stranded(uploading := true, gently := false) -> DiveSimulation:
	var sim := DiveSimulation.new(MediumLayout.uniform(_dense()))
	_strand(sim, uploading, gently)
	return sim


## Dives `sim` from the surface until sealed in with survey aboard, then loses
## the plasma, roughly or gently (see _stranded()).
func _strand(sim: DiveSimulation, uploading: bool, gently := false) -> void:
	sim.set_uploading(uploading)
	sim.set_power(1.0)
	DiveTestKit.run_until(sim, &"tunnel_sealed", 600.0, [], 0.25)
	DiveTestKit.run(sim, 30.0, 0.25)
	if gently:
		_wear_through(sim)
	else:
		_lose_plasma(sim)
	sim.take_events()


## Shifts only a little wide of the wobble, each just poor enough to wear the
## Head a little, never rough enough to disrupt the plasma, until the Head is
## worn through and the plasma lost with it.
func _wear_through(sim: DiveSimulation) -> void:
	DiveTestKit.wear_head_gently(sim, 1.0)
	assert_bool(sim.stranded()).is_true()
	assert_float(sim.head_wear()).is_equal(1.0)


## Loses the plasma on a Head worn a little past half (DiveTestKit.lose_plasma()).
func _lose_plasma(sim: DiveSimulation) -> void:
	DiveTestKit.lose_plasma(sim)
	assert_bool(sim.stranded()).is_true()


func test_losing_the_plasma_switches_to_the_emergency_store() -> void:
	var sim := DiveSimulation.new(MediumLayout.uniform(_dense()))
	assert_bool(sim.on_emergency_store()).is_false()
	assert_float(sim.emergency_store()).is_greater(0.0)
	assert_float(sim.emergency_store()).is_equal(sim.emergency_store_capacity())

	_strand(sim, true)

	assert_bool(sim.on_emergency_store()).is_true()
	assert_float(sim.emergency_store()).is_greater(0.0)


func test_the_store_is_not_drawn_while_the_plasma_holds() -> void:
	var sim := DiveSimulation.new(MediumLayout.uniform(_dense()))
	sim.set_power(1.0)
	DiveTestKit.run_until(sim, &"tunnel_sealed", 600.0, [], 0.25)
	DiveTestKit.run(sim, 600.0, 1.0)

	assert_float(sim.paid()).is_greater(0.0)
	assert_float(sim.emergency_store()).is_equal(sim.emergency_store_capacity())


func test_while_stranded_uploading_survey_data_draws_on_the_store() -> void:
	var sim := _stranded()
	var paid := sim.paid()
	var store := sim.emergency_store()
	var aboard := sim.unsold_value()
	assert_float(aboard).is_greater(0.0)

	DiveTestKit.run(sim, 1200.0, 1.0)

	# Survey went up and was paid for even with the Head dark...
	assert_float(sim.paid()).is_greater(paid)
	assert_float(sim.unsold_value()).is_less(aboard)
	# ...and the store paid for sending it.
	assert_float(sim.emergency_store()).is_less(store)


func test_with_the_link_stopped_the_store_is_kept_and_nothing_goes_up() -> void:
	var sim := _stranded(false)
	var paid := sim.paid()
	var store := sim.emergency_store()

	DiveTestKit.run(sim, 1200.0, 1.0)

	assert_bool(sim.uploading()).is_false()
	assert_float(sim.link_rate()).is_equal(0.0)
	assert_float(sim.paid()).is_equal(paid)
	assert_float(sim.emergency_store()).is_equal(store)


func test_once_the_store_is_spent_nothing_more_goes_up() -> void:
	var sim := _stranded()
	for i in 100:
		DiveTestKit.run(sim, 600.0, 1.0)
		if sim.emergency_store() <= 0.0:
			break
	assert_float(sim.emergency_store()).is_equal(0.0)
	assert_float(sim.unsold_value()).is_greater(0.0)
	var paid := sim.paid()

	DiveTestKit.run(sim, 1200.0, 1.0)

	assert_float(sim.link_rate()).is_equal(0.0)
	assert_float(sim.paid()).is_equal(paid)


func test_a_stranding_keeps_the_survey_aboard_until_the_recovery() -> void:
	var sim := _stranded(false)
	var aboard := sim.unsold_value()
	assert_float(aboard).is_greater(0.0)
	DiveTestKit.run(sim, 60.0, 1.0)
	assert_float(sim.unsold_value()).is_equal(aboard)

	sim.recover()
	var recovered: Array = sim.take_events().filter(
			func(e: Dictionary) -> bool: return e.type == &"recovered")

	assert_int(recovered.size()).is_equal(1)
	assert_float(recovered[0].lost).is_greater_equal(aboard)
	assert_int(recovered[0].lost_stretches).is_greater(0)
	assert_float(sim.unsold_value()).is_equal(0.0)


## Asks for a relight and returns its &"relight_result".
func _relight(sim: DiveSimulation) -> Dictionary:
	sim.relight()
	return DiveTestKit.run_until(sim, &"relight_result", 1.0, [], 0.25)


## Relights until one comes out as `outcome` (&"lit" or &"failed"), losing the
## plasma again after a lit one and calling a recovery and stranding again (as
## `gently` says) when the store cannot pay for another. Returns that result,
## with the store before it as `store_before`.
func _relight_until(sim: DiveSimulation, outcome: StringName, gently := false) -> Dictionary:
	for attempt in 60:
		if sim.emergency_store() < sim.relight_cost():
			sim.recover()
			_strand(sim, false, gently)
		var before := sim.emergency_store()
		var result := _relight(sim)
		assert_dict(result).is_not_empty()
		if result.outcome == outcome:
			result["store_before"] = before
			return result
		if result.outcome == &"lit":
			_lose_plasma(sim)
			sim.take_events()
	return {}


func test_a_relight_costs_a_big_pulse_from_the_store() -> void:
	var sim := _stranded(false)
	var before := sim.emergency_store()
	assert_float(sim.relight_cost()).is_greater(0.0)
	assert_float(sim.relight_cost()).is_less_equal(before)

	var result := _relight(sim)

	assert_float(result.spent).is_equal(sim.relight_cost())
	assert_float(sim.emergency_store()).is_equal_approx(before - sim.relight_cost(), 0.0001)
	# Big: more than the link would draw sending a whole stretch of survey.
	var linked := _stranded()
	var store := linked.emergency_store()
	var paid := linked.paid()
	for i in 10000:
		linked.advance(1.0)
		if linked.paid() > paid:
			break
	assert_float(sim.relight_cost()).is_greater(store - linked.emergency_store())


func test_a_relight_is_refused_when_the_store_cannot_pay_it() -> void:
	var sim := _stranded()
	# Let the link spend the store below a relight's pulse.
	for i in 100000:
		if sim.emergency_store() < sim.relight_cost():
			break
		sim.advance(1.0)
	var store := sim.emergency_store()
	sim.set_uploading(false)

	var result := _relight(sim)

	assert_str(String(result.outcome)).is_equal("refused")
	assert_float(result.spent).is_equal(0.0)
	assert_float(sim.emergency_store()).is_equal(store)
	assert_bool(sim.stranded()).is_true()
	assert_bool(sim.plasma_lost()).is_true()


func test_a_successful_relight_ends_the_stranding_and_the_dive_goes_on() -> void:
	var sim := _stranded(false)

	var lit := _relight_until(sim, &"lit")

	assert_dict(lit).is_not_empty()
	assert_float(sim.emergency_store()).is_less(lit.store_before)
	assert_bool(sim.stranded()).is_false()
	assert_bool(sim.plasma_lost()).is_false()
	assert_bool(sim.on_emergency_store()).is_false()
	var depth := sim.depth()
	sim.set_power(1.0)
	DiveTestKit.run(sim, 10.0, 0.25)
	assert_float(sim.reactor_output()).is_greater(0.0)
	assert_float(sim.speed()).is_greater(0.0)
	assert_float(sim.depth()).is_greater(depth)
	assert_str(String(sim.call_reason(DiveSimulation.STATION_REACTOR))).is_not_equal("stranded")


func test_a_failed_relight_spends_the_energy_and_leaves_the_crew_stranded() -> void:
	var sim := _stranded(false)

	var failed := _relight_until(sim, &"failed")

	assert_dict(failed).is_not_empty()
	assert_float(failed.spent).is_equal(sim.relight_cost())
	assert_float(sim.emergency_store()).is_equal_approx(
			failed.store_before - sim.relight_cost(), 0.0001)
	assert_bool(sim.stranded()).is_true()
	assert_bool(sim.plasma_lost()).is_true()
	assert_bool(sim.on_emergency_store()).is_true()


func test_a_healthy_head_relights_more_reliably_than_a_worn_one() -> void:
	var fresh := DiveSimulation.new(MediumLayout.uniform(_dense()))
	var worn := DiveSimulation.new(MediumLayout.uniform(_dense()))
	var on := worn.plasma_frequency()
	worn.shift(on * 1.5)
	worn.advance(0.1)
	worn.shift(on)
	worn.advance(0.1)
	var disrupted := _stranded(false)
	var worn_through := _stranded(false, true)
	assert_float(fresh.head_wear()).is_less(worn.head_wear())
	assert_float(worn.head_wear()).is_less(disrupted.head_wear())
	assert_float(disrupted.head_wear()).is_less(worn_through.head_wear())

	assert_float(fresh.relight_chance()).is_greater(worn.relight_chance())
	assert_float(worn.relight_chance()).is_greater(disrupted.relight_chance())
	assert_float(disrupted.relight_chance()).is_greater(worn_through.relight_chance())
	# Even a Head worn through can be relit, sometimes.
	assert_float(worn_through.relight_chance()).is_greater(0.0)


## How many of `trials` strandings in a row the first relight lights: each a
## fresh dive stranded roughly or gently (see _stranded()), one relight, then
## the recovery. Each trial rolls the relight's luck once.
func _lit_in(trials: int, gently: bool) -> int:
	var sim := DiveSimulation.new(MediumLayout.uniform(_dense()))
	var lit := 0
	for i in trials:
		_strand(sim, false, gently)
		if _relight(sim).outcome == &"lit":
			lit += 1
			_lose_plasma(sim)
		sim.recover()
		sim.take_events()
	return lit


func test_a_plasma_lost_on_a_worn_head_relights_more_often_than_one_worn_through() -> void:
	# The same luck for both (the same rolls in the same order), so only the
	# Head's wear can tell them apart.
	var disrupted := _lit_in(40, false)
	var worn_through := _lit_in(40, true)

	assert_int(disrupted).is_greater(worn_through)
	assert_int(worn_through).is_greater(0)


func test_a_rough_shift_on_a_worn_head_loses_the_plasma_short_of_wearing_it_through() -> void:
	var sim := _stranded(false)

	assert_bool(sim.plasma_lost()).is_true()
	assert_float(sim.head_wear()).is_less(1.0)


func test_wearing_the_head_through_loses_the_plasma() -> void:
	var sim := _stranded(false, true)

	assert_bool(sim.plasma_lost()).is_true()
	assert_float(sim.head_wear()).is_equal(1.0)


func test_a_relit_head_worn_through_holds_through_a_clean_shift() -> void:
	var sim := _stranded(false, true)
	_relight_until(sim, &"lit", true)
	assert_float(sim.head_wear()).is_equal(1.0)

	sim.shift(sim.plasma_frequency())
	DiveTestKit.run(sim, 1.0, 0.25)

	assert_bool(sim.plasma_lost()).is_false()


func test_a_relight_is_only_for_a_lost_plasma() -> void:
	var sim := DiveSimulation.new(MediumLayout.uniform(_dense()))
	sim.set_power(1.0)
	DiveTestKit.run(sim, 5.0, 0.25)

	sim.relight()
	var seen := []
	DiveTestKit.run_until(sim, &"never", 1.0, seen, 0.25)

	assert_array(DiveTestKit.types(seen)).not_contains([&"relight_result"])
	assert_float(sim.emergency_store()).is_equal(sim.emergency_store_capacity())


func test_while_stranded_time_may_run_fast() -> void:
	var sim := _stranded()

	sim.set_time_rate(sim.max_time_rate())

	assert_float(sim.time_rate()).is_greater(1.0)
	assert_str(String(sim.call_reason(DiveSimulation.STATION_REACTOR))).is_equal("stranded")
