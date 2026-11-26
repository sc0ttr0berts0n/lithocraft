# The Shift dial as two channels, ACTIVE and STANDBY, and the swap that is
# the Shift, tested at the simulation's interface. Assert relationships,
# never tuned constants (ADR 0001).
extends GdUnitTestSuite


## Test values only: soft rock over hard, strong enough never to slip.
func _soft() -> Medium:
	return Medium.new(&"soft", 1.0, 3.0, 0.3, 300.0, 1.0, {&"quartz": 1.0}, 0.5)


func _hard() -> Medium:
	return Medium.new(&"hard", 4.0, 3.0, 0.3, 300.0, 1.0, {&"feldspar": 1.0}, 0.5)


## Soft rock with one Boundary into hard rock at this depth: deep enough that
## its call comes after the dive is under way.
func _one_boundary(at := 60.0) -> DiveSimulation:
	var sim := DiveSimulation.new(MediumLayout.layered([[0.0, _soft()], [at, _hard()]]))
	sim.set_power(0.5)
	return sim


## The &"shift_result" the next step raises after a swap, or {}.
func _swap(sim: DiveSimulation) -> Dictionary:
	sim.take_events()
	sim.shift()
	sim.advance(0.1)
	for event in sim.take_events():
		if event.type == &"shift_result":
			return event
	return {}


func test_tuning_standby_leaves_the_plasmas_tuning_unchanged() -> void:
	var sim := _one_boundary()
	var active := sim.plasma_tuning()

	sim.set_standby_tuning(active * 1.5)
	DiveTestKit.run(sim, 1.0, 0.1)

	assert_float(sim.plasma_tuning()).is_equal(active)
	assert_float(sim.standby_tuning()).is_equal_approx(active * 1.5, 1e-6)
	assert_bool(sim.shift_due()).is_false()


func test_a_swap_makes_standby_active_and_the_old_active_standby() -> void:
	var sim := _one_boundary()
	var active := sim.plasma_tuning()
	var standby := active * 1.5
	sim.set_standby_tuning(standby)

	var result := _swap(sim)

	assert_dict(result).is_not_empty()
	assert_float(sim.plasma_tuning()).is_equal_approx(standby, 1e-6)
	assert_float(sim.standby_tuning()).is_equal_approx(active, 1e-6)


func test_a_pretuned_swap_on_the_crossing_grades_better_than_an_early_or_late_one() -> void:
	var ahead := DiveTestKit.wobble_in(_hard())
	var on_time := _one_boundary()
	var early := _one_boundary()
	var late := _one_boundary()
	for sim in [on_time, early, late]:
		DiveTestKit.run_until(sim, &"boundary_approaching")
		sim.set_standby_tuning(ahead)

	var early_result := _swap(early)
	DiveTestKit.run_until(on_time, &"boundary_crossed")
	var on_time_result := _swap(on_time)
	DiveTestKit.run_until(late, &"boundary_crossed")
	DiveTestKit.run(late, late.shift_window_length() + 4.0, 0.1)
	var late_result := _swap(late)

	assert_str(String(early.medium().name)).is_equal("soft")
	assert_bool(on_time_result.clean).is_true()
	assert_float(early_result.grade).is_less(on_time_result.grade)
	assert_float(late_result.grade).is_less(on_time_result.grade)


func test_swapping_back_is_graded_as_a_shift() -> void:
	var sim := _one_boundary()
	DiveTestKit.run_until(sim, &"boundary_approaching")
	sim.set_standby_tuning(DiveTestKit.wobble_in(_hard()))
	DiveTestKit.run_until(sim, &"boundary_crossed")
	var swapped := _swap(sim)

	var back := _swap(sim)

	assert_dict(back).is_not_empty()
	assert_bool(back.autopilot).is_false()
	# Back to the soft rock's tuning in the hard rock: a poor Shift.
	assert_float(back.grade).is_less(swapped.grade)
	assert_float(sim.plasma_tuning()).is_equal_approx(DiveTestKit.wobble_in(_soft()), 1e-6)
	assert_bool(sim.shift_due()).is_true()


func test_standby_reads_no_match_until_the_boundary_approaching_call() -> void:
	var sim := _one_boundary()
	sim.advance(0.1)

	assert_bool(is_nan(sim.standby_match())).is_true()
	assert_bool(is_nan(sim.wobble_ahead())).is_true()
	DiveTestKit.run_until(sim, &"boundary_approaching")
	assert_bool(is_nan(sim.standby_match())).is_false()
	assert_float(sim.wobble_ahead()).is_equal_approx(DiveTestKit.wobble_in(_hard()), 1e-6)


func test_standby_matches_the_medium_ahead_while_active_matches_the_one_the_head_is_in() -> void:
	var sim := _one_boundary()
	DiveTestKit.run_until(sim, &"boundary_approaching")
	var standby_before := sim.standby_match()  # Standby starts as the active: the soft rock's.
	var active_before := sim.shift_match(sim.plasma_tuning())

	sim.set_standby_tuning(DiveTestKit.wobble_in(_hard()))

	assert_float(sim.standby_match()).is_greater(standby_before)
	# Pretuning standby does not make the active channel's match fall.
	assert_float(sim.shift_match(sim.plasma_tuning())).is_equal(active_before)


func test_standby_keeps_its_preview_through_the_crossing_for_the_swap() -> void:
	var sim := _one_boundary()
	DiveTestKit.run_until(sim, &"boundary_approaching")
	sim.set_standby_tuning(DiveTestKit.wobble_in(_hard()))
	var pretuned := sim.standby_match()

	DiveTestKit.run_until(sim, &"boundary_crossed")

	assert_float(sim.standby_match()).is_equal_approx(pretuned, 1e-6)
	_swap(sim)
	# The old active, now standby, reads as a poor match for the rock entered.
	assert_float(sim.standby_match()).is_less(pretuned)


func test_tuning_standby_leaves_the_reactors_autopilot_engaged() -> void:
	var sim := _one_boundary()
	sim.set_autopilot(DiveSimulation.STATION_REACTOR, true)

	sim.set_standby_tuning(sim.plasma_tuning() * 1.2)

	assert_bool(sim.autopilot(DiveSimulation.STATION_REACTOR)).is_true()


func test_a_swap_disengages_the_reactors_autopilot() -> void:
	var sim := _one_boundary()
	sim.set_autopilot(DiveSimulation.STATION_REACTOR, true)

	sim.shift()

	assert_bool(sim.autopilot(DiveSimulation.STATION_REACTOR)).is_false()
