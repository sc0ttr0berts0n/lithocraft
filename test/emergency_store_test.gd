# The emergency store and the relight, tested at the simulation's interface.
# Assert relationships, never tuned constants (ADR 0001).
extends GdUnitTestSuite


## Test values only. Dense rock the melt fills behind the Tail, so the tunnel
## seals almost at once, but it carries sound, so the slow link still works.
func _dense() -> Medium:
	return Medium.new(&"dense", 1.0, 3.0, 0.0, 300.0, 1.0, {&"quartz": 1.0}, 0.8)


## A dive in dense rock, sealed in with survey aboard, its plasma lost by poor
## Shifts: stranded.
func _stranded(uploading := true) -> DiveSimulation:
	var sim := DiveSimulation.new(MediumLayout.uniform(_dense()))
	_strand(sim, uploading)
	return sim


## Dives `sim` from the surface until sealed in with survey aboard, then loses
## the plasma.
func _strand(sim: DiveSimulation, uploading: bool) -> void:
	sim.set_uploading(uploading)
	sim.set_power(1.0)
	DiveTestKit.run_until(sim, &"tunnel_sealed", 600.0, [], 0.25)
	DiveTestKit.run(sim, 30.0, 0.25)
	_lose_plasma(sim)
	sim.take_events()


## Poor Shifts, each wide of the wobble and then back onto it, until the Head
## is worn through and the plasma lost.
func _lose_plasma(sim: DiveSimulation) -> void:
	var on := sim.plasma_frequency()
	for i in 20:
		sim.shift(on * 1.5)
		sim.advance(0.1)
		if sim.plasma_lost():
			break
		sim.shift(on)
		sim.advance(0.1)
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


func test_while_stranded_time_may_run_fast() -> void:
	var sim := _stranded()

	sim.set_time_rate(sim.max_time_rate())

	assert_float(sim.time_rate()).is_greater(1.0)
	assert_str(String(sim.call_reason(DiveSimulation.STATION_REACTOR))).is_equal("stranded")
