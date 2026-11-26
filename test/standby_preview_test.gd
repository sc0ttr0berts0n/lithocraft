# STANDBY's preview, the scan's guess of the Wobble ahead, and the Boundary
# countdown with its doubt, tested at the simulation's interface. Both are as
# sure as the Inferred Boundary ahead, which comes from points alone. Assert
# relationships, never tuned constants (ADR 0001).
extends GdUnitTestSuite

const ACTIVE := DiveSimulation.CHANNEL_ACTIVE
const STANDBY := DiveSimulation.CHANNEL_STANDBY
## Depth of the test layouts' one Boundary, metres.
const BOUNDARY_M := 80.0


## Test values only: soft, weaker rock over hard, stronger rock, both strong
## enough never to slip and both carrying sound well.
func _soft() -> Medium:
	return Medium.new(&"soft", 1.0, 3.0, 0.3, 300.0, 1.0, {&"quartz": 1.0}, 0.6)


func _hard() -> Medium:
	return Medium.new(&"hard", 4.0, 6.0, 0.3, 300.0, 1.0, {&"feldspar": 1.0}, 0.6)


## Under way in soft rock above one Boundary into hard rock.
func _dive() -> DiveSimulation:
	var sim := DiveSimulation.new(MediumLayout.layered([[0.0, _soft()], [BOUNDARY_M, _hard()]]))
	sim.set_power(0.5)
	DiveTestKit.run(sim, 5.0, 0.1)
	return sim


## A dive that has not scanned.
func _unscanned() -> DiveSimulation:
	return _dive()


## A dive whose only scan is one pulse sent under way, in its own noise.
func _poorly_scanned() -> DiveSimulation:
	var sim := _dive()
	sim.pulse()
	sim.advance(0.1)
	return sim


## A dive that stopped for a Quiet Ship scan of several pulses, under way
## again.
func _well_scanned() -> DiveSimulation:
	var sim := _dive()
	DiveTestKit.quiet_scan(sim, 6)
	DiveTestKit.run(sim, 5.0, 0.1)
	return sim


func _truth() -> Vector2:
	return DiveTestKit.wobble_in(_hard())


# --- The guess ----------------------------------------------------------------

func test_with_no_scan_the_guess_is_spurious_sines_only() -> void:
	var sim := _unscanned()

	assert_float(sim.wobble_ahead_confidence()).is_equal(0.0)
	assert_bool(is_nan(sim.wobble_ahead_frequency())).is_true()
	assert_bool(is_nan(sim.wobble_ahead_amplitude())).is_true()
	assert_float(sim.wobble_ahead_spurious()).is_greater(0.0)
	# There is a guess to draw all the same, and it moves.
	var sizes := DiveTestKit.swells(func(t: float) -> float: return sim.wobble_wave(STANDBY, t), 1.0, 3)
	assert_float(sizes.max()).is_greater(0.0)
	# With nothing to read it against, STANDBY has no predicted Residual.
	assert_bool(is_nan(sim.residual(STANDBY))).is_true()
	assert_bool(is_nan(sim.residual_wave(STANDBY, 0.0))).is_true()
	assert_bool(is_nan(sim.counter_wave(STANDBY, 0.0))).is_false()


func test_the_boundary_approaching_call_tells_the_guess_nothing() -> void:
	var sim := _unscanned()

	assert_dict(DiveTestKit.run_until(sim, &"boundary_approaching")).is_not_empty()

	assert_bool(is_nan(sim.wobble_ahead_frequency())).is_true()
	assert_bool(is_nan(sim.residual(STANDBY))).is_true()


func test_a_better_resolved_boundary_gives_a_guess_closer_to_the_true_wobble_and_weaker_spurious_sines() -> void:
	var poor := _poorly_scanned()
	var well := _well_scanned()
	var truth := _truth()

	assert_float(poor.wobble_ahead_confidence()).is_greater(0.0)
	assert_float(well.wobble_ahead_confidence()).is_greater(poor.wobble_ahead_confidence())
	var poor_guess := DiveTestKit.wobble_ahead(poor)
	var well_guess := DiveTestKit.wobble_ahead(well)
	assert_float(absf(poor_guess.x - truth.x)).is_greater(0.0)
	assert_float(absf(well_guess.x - truth.x)).is_less(absf(poor_guess.x - truth.x))
	assert_float(absf(poor_guess.y - truth.y)).is_greater(0.0)
	assert_float(absf(well_guess.y - truth.y)).is_less(absf(poor_guess.y - truth.y))
	assert_float(well.wobble_ahead_spurious()).is_less(poor.wobble_ahead_spurious())
	assert_float(poor.wobble_ahead_spurious()).is_less(_unscanned().wobble_ahead_spurious())


func test_the_guess_drawn_is_its_true_component_summed_with_the_spurious_sines() -> void:
	var sim := _poorly_scanned()
	var guess := DiveTestKit.wobble_ahead(sim)

	# Further from zero, at its fullest, than its true component alone could be.
	var sizes := DiveTestKit.swells(func(t: float) -> float: return sim.wobble_wave(STANDBY, t), 1.0, 30)
	assert_float(sizes.max()).is_greater(guess.y)
	assert_float(sizes.max()).is_less_equal(guess.y + sim.wobble_ahead_spurious() + 1e-4)


func test_more_pulses_sharpen_the_guess() -> void:
	var sim := _poorly_scanned()
	var before := sim.wobble_ahead_confidence()
	var spurious := sim.wobble_ahead_spurious()

	DiveTestKit.quiet_scan(sim, 3)

	assert_float(sim.wobble_ahead_confidence()).is_greater(before)
	assert_float(sim.wobble_ahead_spurious()).is_less(spurious)


# --- The predicted Residual ---------------------------------------------------

func test_standbys_predicted_residual_is_its_counter_wave_against_the_guess() -> void:
	var sim := _poorly_scanned()
	var guess := DiveTestKit.wobble_ahead(sim)
	var active_before := sim.residual(ACTIVE)
	# STANDBY starts as ACTIVE: the soft rock's Counter-wave.
	var before := sim.residual(STANDBY)
	assert_float(before).is_greater(sim.band())

	# Frequency first: the predicted Residual's beats go, its steady part stays.
	DiveTestKit.tune(sim, STANDBY, Vector2(guess.x, sim.counter_wave_amplitude(STANDBY)))
	assert_float(sim.residual_beat(STANDBY)).is_equal_approx(0.0, 1e-6)
	assert_float(sim.residual_steady(STANDBY)).is_greater(0.0)
	assert_float(sim.residual(STANDBY)).is_less(before)
	# Then amplitude: flat against the guess, whatever the truth is.
	DiveTestKit.tune(sim, STANDBY, guess)
	assert_float(sim.residual(STANDBY)).is_equal_approx(0.0, 1e-6)
	# The truth would not be flat.
	DiveTestKit.tune(sim, STANDBY, _truth())
	assert_float(sim.residual(STANDBY)).is_greater(0.0)

	# Preparing STANDBY does not move ACTIVE's Residual.
	assert_float(sim.residual(ACTIVE)).is_equal(active_before)


## Prepares STANDBY until its predicted Residual is flat, swaps it in on the
## crossing, and gives the wear on the Head some seconds on.
func _wear_after_a_swap_prepared_flat(sim: DiveSimulation) -> float:
	DiveTestKit.tune(sim, STANDBY, DiveTestKit.wobble_ahead(sim))
	assert_float(sim.residual(STANDBY)).is_equal_approx(0.0, 1e-6)
	assert_dict(DiveTestKit.run_until(sim, &"boundary_crossed")).is_not_empty()
	sim.shift()
	DiveTestKit.run(sim, 10.0, 0.1)
	return sim.head_wear()


func test_a_flat_prediction_on_a_poorly_resolved_boundary_can_still_wear_the_head_and_on_a_well_resolved_one_does_not() -> void:
	assert_float(_wear_after_a_swap_prepared_flat(_poorly_scanned())).is_greater(0.0)
	assert_float(_wear_after_a_swap_prepared_flat(_well_scanned())).is_equal(0.0)


func test_standby_keeps_its_guess_through_the_crossing_until_the_residual_is_inside_the_band() -> void:
	var sim := _well_scanned()
	assert_dict(DiveTestKit.run_until(sim, &"boundary_crossed")).is_not_empty()
	var guess := DiveTestKit.wobble_ahead(sim)
	assert_bool(is_nan(guess.x)).is_false()

	DiveTestKit.run(sim, 2.0, 0.1)

	# Still the guess of the rock just entered, for the swap.
	assert_bool(sim.out_of_band()).is_true()
	assert_vector(DiveTestKit.wobble_ahead(sim)).is_equal(guess)
	DiveTestKit.tune(sim, STANDBY, guess)
	assert_float(sim.residual(STANDBY)).is_equal_approx(0.0, 1e-6)
	sim.shift()
	DiveTestKit.run(sim, 1.0, 0.1)
	# Settled: STANDBY looks to the next Boundary, and there is none.
	assert_bool(sim.out_of_band()).is_false()
	assert_bool(is_nan(sim.wobble_ahead_frequency())).is_true()


# --- The countdown --------------------------------------------------------------

func test_with_no_scan_the_countdown_reads_beyond_five_minutes_however_near_the_boundary() -> void:
	var sim := _unscanned()
	assert_bool(is_inf(sim.boundary_countdown())).is_true()
	assert_bool(is_inf(sim.boundary_countdown_doubt())).is_true()

	# The call comes (the Boundary is seconds away) and no point has returned:
	# the countdown must not know.
	assert_dict(DiveTestKit.run_until(sim, &"boundary_approaching")).is_not_empty()

	assert_bool(is_inf(sim.boundary_countdown())).is_true()
	assert_bool(is_inf(sim.boundary_countdown_doubt())).is_true()


func test_a_scanned_boundary_is_counted_down_to_with_a_doubt() -> void:
	var sim := _well_scanned()

	var first := sim.boundary_countdown()
	assert_float(first).is_greater(0.0)
	assert_float(first).is_less(sim.boundary_countdown_cap())
	assert_float(sim.boundary_countdown_doubt()).is_greater(0.0)
	# About right: the truth lies within a few doubts of the best figure.
	var true_seconds := (BOUNDARY_M - sim.depth()) / sim.speed()
	assert_float(absf(first - true_seconds)).is_less(3.0 * sim.boundary_countdown_doubt() + 1.0)
	DiveTestKit.run(sim, 5.0, 0.1)
	assert_float(sim.boundary_countdown()).is_less(first)


func test_the_countdowns_doubt_is_smaller_after_a_quiet_ship_scan_than_after_one_pulse_under_way() -> void:
	var poor := _poorly_scanned()
	var well := _well_scanned()
	# Both under way at the same depth.
	while poor.depth() < well.depth():
		poor.advance(0.1)

	assert_bool(is_inf(poor.boundary_countdown())).is_false()
	assert_float(poor.speed()).is_equal_approx(well.speed(), 1e-3)
	assert_float(well.boundary_countdown_doubt()).is_less(poor.boundary_countdown_doubt())


func test_stopped_the_boundary_is_never_reached() -> void:
	var sim := _well_scanned()

	sim.set_quiet_ship(true)
	DiveTestKit.run(sim, 60.0, 0.1)

	assert_float(sim.speed()).is_equal(0.0)
	assert_bool(is_inf(sim.boundary_countdown())).is_true()
