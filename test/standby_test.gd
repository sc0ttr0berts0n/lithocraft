# The Shift dial as two channels, ACTIVE and STANDBY, each a Counter-wave,
# the selector that says which the controls tune, and the swap that is the
# Shift, tested at the simulation's interface. Assert relationships, never
# tuned constants (ADR 0001).
extends GdUnitTestSuite

const ACTIVE := DiveSimulation.CHANNEL_ACTIVE
const STANDBY := DiveSimulation.CHANNEL_STANDBY


## Test values only: soft, weaker rock over hard, stronger rock, both strong
## enough never to slip.
func _soft() -> Medium:
	return Medium.new(&"soft", 1.0, 3.0, 0.3, 300.0, 1.0, {&"quartz": 1.0}, 0.5)


func _hard() -> Medium:
	return Medium.new(&"hard", 4.0, 6.0, 0.3, 300.0, 1.0, {&"feldspar": 1.0}, 0.5)


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


# --- The selector and the two controls ---------------------------------------

func test_both_channels_start_cancelling_the_wobble_and_the_controls_start_on_standby() -> void:
	var sim := _one_boundary()

	assert_str(String(sim.selected_channel())).is_equal(String(STANDBY))
	for channel in [ACTIVE, STANDBY]:
		assert_vector(DiveTestKit.counter_wave(sim, channel)).is_equal(DiveTestKit.wobble(sim))


func test_the_controls_tune_the_selected_channel_only() -> void:
	var sim := _one_boundary()
	var wobble := DiveTestKit.wobble(sim)

	sim.tune_frequency(wobble.x * 1.5)
	sim.tune_amplitude(wobble.y * 0.5)

	assert_vector(DiveTestKit.counter_wave(sim, STANDBY)).is_equal_approx(Vector2(wobble.x * 1.5, wobble.y * 0.5), Vector2.ONE * 1e-6)
	assert_vector(DiveTestKit.counter_wave(sim, ACTIVE)).is_equal(wobble)

	sim.select_channel(ACTIVE)
	sim.tune_amplitude(wobble.y * 0.9)

	assert_str(String(sim.selected_channel())).is_equal(String(ACTIVE))
	assert_float(sim.counter_wave_amplitude(ACTIVE)).is_equal_approx(wobble.y * 0.9, 1e-6)
	assert_float(sim.counter_wave_amplitude(STANDBY)).is_equal_approx(wobble.y * 0.5, 1e-6)


func test_tuning_standby_changes_nothing_about_the_plasma() -> void:
	var sim := _one_boundary()
	var wobble := DiveTestKit.wobble(sim)

	sim.tune_frequency(wobble.x * 1.5)
	sim.tune_amplitude(wobble.y * 1.5)
	DiveTestKit.run(sim, 5.0, 0.1)

	assert_float(sim.residual(ACTIVE)).is_equal(0.0)
	assert_bool(sim.out_of_band()).is_false()
	assert_float(sim.head_wear()).is_equal(0.0)
	assert_float(sim.plasma_stability()).is_equal(1.0)


func test_tuning_active_moves_the_live_plasma_freely() -> void:
	var sim := _one_boundary()
	var wobble := DiveTestKit.wobble(sim)
	sim.select_channel(ACTIVE)

	sim.tune_amplitude(wobble.y * 1.6)
	DiveTestKit.run(sim, 2.0, 0.1)

	assert_bool(sim.out_of_band()).is_true()
	assert_float(sim.plasma_stability()).is_less(1.0)
	assert_float(sim.head_wear()).is_greater(0.0)
	# And back again, with no Shift made.
	sim.tune_amplitude(wobble.y)
	DiveTestKit.run(sim, 1.0, 0.1)
	assert_bool(sim.out_of_band()).is_false()
	assert_array(DiveTestKit.types(sim.take_events())).not_contains([&"shift_result"])


func test_tuning_and_selecting_leave_the_reactors_autopilot_engaged() -> void:
	var sim := _one_boundary()
	sim.set_autopilot(DiveSimulation.STATION_REACTOR, true)

	sim.tune_frequency(sim.wobble_frequency() * 1.2)
	sim.tune_amplitude(sim.wobble_amplitude() * 1.2)
	sim.select_channel(ACTIVE)
	sim.tune_frequency(sim.wobble_frequency() * 1.01)
	sim.advance(0.1)

	assert_bool(sim.autopilot(DiveSimulation.STATION_REACTOR)).is_true()
	assert_array(DiveTestKit.types(sim.take_events())).not_contains([&"autopilot_off"])


func test_a_swap_disengages_the_reactors_autopilot() -> void:
	var sim := _one_boundary()
	sim.set_autopilot(DiveSimulation.STATION_REACTOR, true)

	sim.shift()

	assert_bool(sim.autopilot(DiveSimulation.STATION_REACTOR)).is_false()


# --- The swap ---------------------------------------------------------------------

func test_a_swap_makes_standby_active_and_the_old_active_standby() -> void:
	var sim := _one_boundary()
	var active := DiveTestKit.counter_wave(sim, ACTIVE)
	var standby := Vector2(active.x * 1.5, active.y * 0.8)
	DiveTestKit.tune(sim, STANDBY, standby)

	var result := _swap(sim)

	assert_dict(result).is_not_empty()
	assert_vector(DiveTestKit.counter_wave(sim, ACTIVE)).is_equal_approx(standby, Vector2.ONE * 1e-6)
	assert_vector(DiveTestKit.counter_wave(sim, STANDBY)).is_equal_approx(active, Vector2.ONE * 1e-6)


func test_the_controls_stay_on_the_channel_they_were_on_after_a_swap() -> void:
	var sim := _one_boundary()

	_swap(sim)
	assert_str(String(sim.selected_channel())).is_equal(String(STANDBY))

	sim.select_channel(ACTIVE)
	_swap(sim)
	assert_str(String(sim.selected_channel())).is_equal(String(ACTIVE))


func test_a_prepared_swap_on_the_crossing_wears_nothing_and_an_early_or_late_one_wears_the_head() -> void:
	var ahead := DiveTestKit.wobble_in(_hard())
	var on_time := _one_boundary()
	var early := _one_boundary()
	var late := _one_boundary()
	for sim in [on_time, early, late]:
		DiveTestKit.run_until(sim, &"boundary_approaching")
		DiveTestKit.tune(sim, STANDBY, ahead)

	var early_result := _swap(early)
	DiveTestKit.run(early, 5.0, 0.1)
	DiveTestKit.run_until(on_time, &"boundary_crossed")
	var on_time_result := _swap(on_time)
	DiveTestKit.run_until(late, &"boundary_crossed")
	DiveTestKit.run(late, 10.0, 0.1)
	var late_result := _swap(late)

	assert_str(String(early.medium().name)).is_equal("soft")
	assert_bool(on_time_result.clean).is_true()
	assert_float(on_time.head_wear()).is_equal(0.0)
	# Early, the hard rock's Counter-wave is wrong for the soft rock still
	# being cut; late, the old one was wrong for the hard rock all the while.
	assert_bool(early_result.clean).is_false()
	assert_float(early_result.residual).is_greater(early_result.band)
	assert_float(early.head_wear()).is_greater(0.0)
	assert_bool(late_result.clean).is_true()
	assert_float(late.head_wear()).is_greater(0.0)


func test_swapping_back_brings_the_old_counter_wave_back() -> void:
	var sim := _one_boundary()
	DiveTestKit.run_until(sim, &"boundary_approaching")
	DiveTestKit.tune(sim, STANDBY, DiveTestKit.wobble_in(_hard()))
	DiveTestKit.run_until(sim, &"boundary_crossed")
	var swapped := _swap(sim)

	var back := _swap(sim)

	assert_bool(swapped.clean).is_true()
	assert_dict(back).is_not_empty()
	# Back to the soft rock's Counter-wave in the hard rock.
	assert_bool(back.clean).is_false()
	assert_vector(DiveTestKit.counter_wave(sim, ACTIVE)).is_equal_approx(DiveTestKit.wobble_in(_soft()), Vector2.ONE * 1e-6)
	assert_bool(sim.out_of_band()).is_true()


# --- STANDBY's preview ----------------------------------------------------------

func test_standby_has_no_residual_to_read_until_the_boundary_approaching_call() -> void:
	var sim := _one_boundary()
	sim.advance(0.1)

	assert_bool(is_nan(sim.residual(STANDBY))).is_true()
	assert_bool(is_nan(sim.wobble_ahead_frequency())).is_true()
	assert_bool(is_nan(sim.wobble_ahead_amplitude())).is_true()
	assert_bool(is_nan(sim.residual_wave(STANDBY, 0.0))).is_true()
	# Its Counter-wave is there all the same.
	assert_bool(is_nan(sim.counter_wave(STANDBY, 0.0))).is_false()
	DiveTestKit.run_until(sim, &"boundary_approaching")
	assert_bool(is_nan(sim.residual(STANDBY))).is_false()
	var ahead := DiveTestKit.wobble_in(_hard())
	assert_float(sim.wobble_ahead_frequency()).is_equal_approx(ahead.x, 1e-6)
	assert_float(sim.wobble_ahead_amplitude()).is_equal_approx(ahead.y, 1e-6)


func test_standby_is_read_against_the_medium_ahead_while_active_is_read_against_the_one_the_head_is_in() -> void:
	var sim := _one_boundary()
	DiveTestKit.run_until(sim, &"boundary_approaching")
	var standby_before := sim.residual(STANDBY)  # Standby starts as the active: the soft rock's.
	var active_before := sim.residual(ACTIVE)
	assert_float(standby_before).is_greater(sim.band())

	# Frequency first: the predicted Residual's beats go, its steady part stays.
	DiveTestKit.tune(sim, STANDBY, Vector2(sim.wobble_ahead_frequency(), sim.counter_wave_amplitude(STANDBY)))
	assert_float(sim.residual_beat(STANDBY)).is_equal_approx(0.0, 1e-6)
	assert_float(sim.residual_steady(STANDBY)).is_greater(0.0)
	assert_float(sim.residual(STANDBY)).is_less(standby_before)
	# Then amplitude: flat.
	DiveTestKit.tune(sim, STANDBY, DiveTestKit.wobble_in(_hard()))
	assert_float(sim.residual(STANDBY)).is_equal_approx(0.0, 1e-6)

	# Preparing standby does not move the active channel's Residual.
	assert_float(sim.residual(ACTIVE)).is_equal(active_before)


func test_standby_keeps_its_preview_through_the_crossing_for_the_swap() -> void:
	var sim := _one_boundary()
	DiveTestKit.run_until(sim, &"boundary_approaching")
	DiveTestKit.tune(sim, STANDBY, DiveTestKit.wobble_in(_hard()))
	var prepared := sim.residual(STANDBY)

	DiveTestKit.run_until(sim, &"boundary_crossed")

	assert_float(sim.residual(STANDBY)).is_equal_approx(prepared, 1e-6)
	_swap(sim)
	# The old active, now standby, would leave a big Residual in the rock entered.
	assert_float(sim.residual(STANDBY)).is_greater(sim.band())
