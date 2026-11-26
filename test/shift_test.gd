# Boundaries, the Wobble, the Counter-wave, the Residual and the Band, tested
# at the simulation's interface. Assert relationships, never tuned constants
# (ADR 0001).
extends GdUnitTestSuite

const ACTIVE := DiveSimulation.CHANNEL_ACTIVE
const STANDBY := DiveSimulation.CHANNEL_STANDBY


## Test values only: two Media strong enough that the grip waves never slip,
## one soft and weaker, one hard and stronger, so crossing between them
## changes the Wobble's frequency and its amplitude.
func _soft() -> Medium:
	return Medium.new(&"soft", 1.0, 3.0, 0.3, 300.0, 1.0, {&"quartz": 1.0}, 0.5)


func _hard() -> Medium:
	return Medium.new(&"hard", 4.0, 6.0, 0.3, 300.0, 1.0, {&"feldspar": 1.0}, 0.5)


## Soft rock with one Boundary into hard rock at this depth.
func _one_boundary(at := 20.0) -> DiveSimulation:
	var sim := DiveSimulation.new(MediumLayout.layered([[0.0, _soft()], [at, _hard()]]))
	sim.set_power(0.5)
	return sim


## A dive at rest in uniform rock, the Residual flat.
func _at_rest() -> DiveSimulation:
	return DiveSimulation.new(MediumLayout.uniform(DiveTestKit.rock()))


## ACTIVE's Counter-wave set to the Wobble's with its frequency times
## `frequency` and its amplitude times `amplitude`.
func _detune(sim: DiveSimulation, frequency: float, amplitude := 1.0) -> void:
	var wobble := DiveTestKit.wobble(sim)
	DiveTestKit.tune(sim, ACTIVE, Vector2(wobble.x * frequency, wobble.y * amplitude))


## A dive at rest whose ACTIVE amplitude leaves a steady Residual `bands`
## times the Band (as the Band stands when it is set).
func _steady_residual(bands: float, sim: DiveSimulation = null) -> DiveSimulation:
	if sim == null:
		sim = _at_rest()
	sim.advance(0.1)
	DiveTestKit.tune(sim, ACTIVE, DiveTestKit.wobble(sim) + Vector2(0.0, bands * sim.band()))
	return sim


# --- Boundaries ---------------------------------------------------------------

func test_a_boundary_ahead_is_announced_before_it_is_crossed() -> void:
	var sim := _one_boundary()
	var seen := []

	var crossed := DiveTestKit.run_until(sim, &"boundary_crossed", 600.0, seen)

	assert_dict(crossed).is_not_empty()
	var types := DiveTestKit.types(seen)
	assert_int(types.count(&"boundary_approaching")).is_equal(1)
	assert_int(types.find(&"boundary_approaching")).is_less(types.find(&"boundary_crossed"))
	assert_str(String(crossed.from)).is_equal("soft")
	assert_str(String(crossed.to)).is_equal("hard")


func test_the_boundary_is_crossed_when_the_head_enters_the_new_medium() -> void:
	var sim := _one_boundary()

	var approaching := DiveTestKit.run_until(sim, &"boundary_approaching")
	assert_str(String(sim.medium().name)).is_equal("soft")
	DiveTestKit.run_until(sim, &"boundary_crossed")
	assert_str(String(sim.medium().name)).is_equal("hard")
	assert_str(String(approaching.to)).is_equal("hard")


func test_every_medium_puts_its_own_wobble_on_the_plasma() -> void:
	var sim := _one_boundary()
	var soft := DiveTestKit.wobble(sim)
	DiveTestKit.run_until(sim, &"boundary_crossed")
	var hard := DiveTestKit.wobble(sim)

	# Harder rock wobbles the plasma faster; stronger rock, bigger.
	assert_float(hard.x).is_greater(soft.x)
	assert_float(hard.y).is_greater(soft.y)


func test_crossing_a_boundary_puts_the_residual_outside_the_band() -> void:
	var sim := _one_boundary()
	sim.advance(0.1)
	assert_bool(sim.out_of_band()).is_false()
	assert_float(sim.residual(ACTIVE)).is_equal_approx(0.0, 1e-6)

	DiveTestKit.run_until(sim, &"boundary_crossed")

	# The old Counter-wave has stopped working: nothing about it changed.
	assert_bool(sim.out_of_band()).is_true()
	assert_float(sim.residual(ACTIVE)).is_greater(sim.band())


func test_a_new_wobble_unsettles_the_plasma_until_the_counter_wave_cancels_it() -> void:
	var sim := _one_boundary()
	DiveTestKit.run_until(sim, &"boundary_crossed")
	DiveTestKit.run(sim, 2.0, 0.1)
	assert_float(sim.plasma_stability()).is_less(1.0)

	DiveTestKit.cancel_wobble(sim)
	sim.advance(0.1)

	assert_bool(sim.out_of_band()).is_false()
	assert_float(sim.plasma_stability()).is_equal_approx(1.0 , 0.01)


# --- The Residual ---------------------------------------------------------------

func test_a_counter_wave_at_the_wobbles_frequency_and_amplitude_leaves_a_flat_residual_and_no_wear_however_long() -> void:
	var sim := _one_boundary(100000.0)
	sim.set_autopilot(DiveSimulation.STATION_THERMAL, true)

	DiveTestKit.fly_until(sim, func(_s: DiveSimulation) -> bool: return false, 3000.0)

	assert_float(sim.distance()).is_greater(100.0)
	assert_float(sim.residual(ACTIVE)).is_equal(0.0)
	for i in 50:
		assert_float(sim.residual_wave(ACTIVE, -i * 0.07)).is_equal_approx(0.0, 1e-6)
	assert_float(sim.head_wear()).is_equal(0.0)
	assert_float(sim.plasma_stability()).is_equal(1.0)
	assert_float(sim.shudder()).is_equal(0.0)


func test_the_residual_is_the_wobble_summed_with_the_counter_wave() -> void:
	var sim := _at_rest()
	_detune(sim, 1.1, 0.8)
	sim.advance(0.1)

	for i in 30:
		var t := -i * 0.11
		assert_float(sim.residual_wave(ACTIVE, t)).is_equal_approx(
				sim.wobble_wave(ACTIVE, t) + sim.counter_wave(ACTIVE, t), 1e-6)
	# The Counter-wave is the Wobble's inverse: cancelling, they are opposite.
	DiveTestKit.cancel_wobble(sim)
	sim.advance(0.1)
	for i in 30:
		assert_float(sim.counter_wave(ACTIVE, -i * 0.11)).is_equal_approx(
				-sim.wobble_wave(ACTIVE, -i * 0.11), 1e-6)


func test_a_wrong_amplitude_leaves_a_steady_residual_and_a_wrong_frequency_a_beating_one() -> void:
	var amplitude_off := _at_rest()
	var frequency_off := _at_rest()
	_detune(amplitude_off, 1.0, 0.7)
	_detune(frequency_off, 1.1, 1.0)
	amplitude_off.advance(0.1)
	frequency_off.advance(0.1)

	# Told apart by their parts.
	assert_float(amplitude_off.residual_steady(ACTIVE)).is_greater(0.0)
	assert_float(amplitude_off.residual_beat(ACTIVE)).is_equal_approx(0.0, 1e-6)
	assert_float(amplitude_off.residual_beat_frequency(ACTIVE)).is_equal(0.0)
	assert_float(frequency_off.residual_steady(ACTIVE)).is_equal_approx(0.0, 1e-6)
	assert_float(frequency_off.residual_beat(ACTIVE)).is_greater(0.0)
	assert_float(frequency_off.residual_beat_frequency(ACTIVE)).is_greater(0.0)
	# And by their waves: one the same size in every cycle of the Wobble, the
	# other swelling and fading over a beat.
	var cycle := 1.0 / amplitude_off.wobble_frequency()
	var cycles := ceili(1.0 / (frequency_off.residual_beat_frequency(ACTIVE) * cycle))
	var steady := DiveTestKit.swells(func(t: float) -> float: return amplitude_off.residual_wave(ACTIVE, t), cycle, cycles)
	var beating := DiveTestKit.swells(func(t: float) -> float: return frequency_off.residual_wave(ACTIVE, t), cycle, cycles)
	assert_float(steady.max() - steady.min()).is_less(0.05 * steady.max())
	assert_float(steady.max()).is_equal_approx(amplitude_off.residual_steady(ACTIVE), 0.01)
	assert_float(beating.min()).is_less(0.5 * beating.max())
	assert_float(beating.max()).is_equal_approx(frequency_off.residual(ACTIVE), 0.02)


func test_the_beats_slow_and_shrink_as_the_frequency_nears() -> void:
	var near := _at_rest()
	var far := _at_rest()
	_detune(near, 1.03)
	_detune(far, 1.2)

	assert_float(near.residual_beat_frequency(ACTIVE)).is_less(far.residual_beat_frequency(ACTIVE))
	assert_float(near.residual_beat(ACTIVE)).is_less(far.residual_beat(ACTIVE))
	# Off either way, and by either control, the Residual grows.
	var below := _at_rest()
	_detune(below, 0.97)
	assert_float(below.residual(ACTIVE)).is_greater(0.0)
	var both := _at_rest()
	_detune(both, 1.03, 1.2)
	assert_float(both.residual(ACTIVE)).is_greater(near.residual(ACTIVE))


# --- The Band and the Head's wear --------------------------------------------

func test_a_residual_inside_the_band_never_wears_the_head() -> void:
	var sim := _steady_residual(0.8)

	DiveTestKit.run(sim, 600.0)

	assert_float(sim.residual(ACTIVE)).is_greater(0.0)
	assert_bool(sim.out_of_band()).is_false()
	assert_float(sim.head_wear()).is_equal(0.0)
	assert_float(sim.plasma_stability()).is_equal(1.0)


func test_a_residual_outside_the_band_wears_the_head_more_the_further_out_and_the_longer() -> void:
	var near := _steady_residual(1.5)
	var far := _steady_residual(3.0)
	DiveTestKit.run(near, 20.0)
	DiveTestKit.run(far, 20.0)
	var near_early := near.head_wear()

	assert_float(near_early).is_greater(0.0)
	assert_float(far.head_wear()).is_greater(near_early)
	DiveTestKit.run(near, 20.0)
	assert_float(near.head_wear()).is_greater(near_early)


func test_a_beating_residual_wears_the_head_too() -> void:
	var sim := _at_rest()
	_detune(sim, 1.2)

	DiveTestKit.run(sim, 20.0, 0.1)

	assert_bool(sim.out_of_band()).is_true()
	assert_float(sim.head_wear()).is_greater(0.0)


func test_wear_stops_once_the_residual_is_back_inside_the_band() -> void:
	var sim := _steady_residual(3.0)
	DiveTestKit.run(sim, 20.0)
	DiveTestKit.cancel_wobble(sim)
	sim.advance(1.0)
	var worn := sim.head_wear()

	DiveTestKit.run(sim, 300.0)

	assert_float(worn).is_greater(0.0)
	assert_float(sim.head_wear()).is_equal(worn)


func test_a_residual_outside_the_band_grinds_with_heat_and_a_shudder_until_it_is_back_inside() -> void:
	var sim := _gently_under_way()
	var quiet_felt := sim.felt_acceleration()
	var quiet_heat := sim.heat_produced()
	_detune(sim, 1.0, 1.8)
	DiveTestKit.run(sim, 2.0, 0.1)
	var grinding_heat := sim.heat_produced()
	# The Drive asks little, so the unsteady plasma still supplies it all:
	# the same power drawn, and the grinding's heat on top.
	assert_float(grinding_heat).is_greater(quiet_heat + 1e-3)

	# The shudder: felt in the Habitat as a jolt on top of gravity.
	assert_float(sim.shudder()).is_greater(0.0)
	var jolt := 0.0
	for i in 20:
		sim.advance(0.03)
		jolt = maxf(jolt, quiet_felt.distance_to(sim.felt_acceleration()))
	assert_float(jolt).is_greater(0.1)
	# Further outside, it shudders harder.
	var milder := _gently_under_way()
	_detune(milder, 1.0, 1.4)
	DiveTestKit.run(milder, 2.0, 0.1)
	assert_float(milder.shudder()).is_greater(0.0)
	assert_float(milder.shudder()).is_less(sim.shudder())
	assert_float(milder.heat_produced()).is_less(grinding_heat)
	# Back inside the Band it is all gone.
	DiveTestKit.cancel_wobble(sim)
	DiveTestKit.run(sim, 2.0, 0.1)
	assert_float(sim.shudder()).is_equal(0.0)
	assert_vector(sim.felt_acceleration()).is_equal_approx(quiet_felt, Vector3.ONE * 1e-6)
	assert_float(sim.heat_produced()).is_equal_approx(quiet_heat, 1e-6)


## A dive under way in uniform rock, the Drive asking for little.
func _gently_under_way() -> DiveSimulation:
	var sim := _at_rest()
	sim.set_power(0.1)
	return DiveTestKit.run(sim, 5.0, 0.1)


func test_the_band_is_narrower_on_a_worn_head_than_a_fresh_one() -> void:
	var fresh := _at_rest()
	var worn := _at_rest()
	DiveTestKit.wear_head_gently(worn, 0.5)
	fresh.advance(0.1)
	worn.advance(0.1)

	assert_float(worn.band()).is_greater(0.0)
	assert_float(worn.band()).is_less(fresh.band())


func test_the_band_is_narrower_hot_than_cool_and_widens_again_as_the_hull_cools() -> void:
	var hot := DiveTestKit.run(_hot_or_cool(1.0), 400.0)
	var cool := DiveTestKit.run(_hot_or_cool(0.2), 400.0)
	assert_float(hot.head_wear()).is_equal(0.0)
	assert_float(hot.vessel_temperature()).is_greater(cool.vessel_temperature())
	assert_float(hot.band()).is_less(cool.band())

	var hot_band := hot.band()
	var hot_temperature := hot.vessel_temperature()
	hot.set_power(0.0)
	DiveTestKit.run(hot, 200.0)

	assert_float(hot.vessel_temperature()).is_less(hot_temperature)
	assert_float(hot.band()).is_greater(hot_band)


## A dive at this power toward a deep Boundary, so the hull settles hot or
## cool.
func _hot_or_cool(power: float) -> DiveSimulation:
	var sim := DiveSimulation.new(MediumLayout.layered([[0.0, _soft()], [3000.0, _hard()]]))
	sim.set_power(power)
	return sim


func test_the_same_residual_wears_a_hot_head_when_it_spares_a_cool_one() -> void:
	var hot := DiveTestKit.run(_hot_or_cool(1.0), 400.0)
	var cool := DiveTestKit.run(_hot_or_cool(0.2), 400.0)
	# A steady Residual between the two Bands.
	var between := (hot.band() + cool.band()) / 2.0
	for sim in [hot, cool]:
		DiveTestKit.tune(sim, ACTIVE, DiveTestKit.wobble(sim) + Vector2(0.0, between))
		DiveTestKit.run(sim, 20.0)

	assert_float(cool.head_wear()).is_equal(0.0)
	assert_float(hot.head_wear()).is_greater(0.0)


func test_the_same_residual_wears_a_worn_head_when_it_spares_a_fresh_one() -> void:
	var fresh := _at_rest()
	var worn := _at_rest()
	DiveTestKit.wear_head_gently(worn, 0.5)
	fresh.advance(0.1)
	var between := (fresh.band() + worn.band()) / 2.0
	var worn_before := worn.head_wear()
	for sim in [fresh, worn]:
		DiveTestKit.tune(sim, ACTIVE, DiveTestKit.wobble(sim) + Vector2(0.0, between))
		DiveTestKit.run(sim, 20.0)

	assert_float(fresh.head_wear()).is_equal(0.0)
	assert_float(worn.head_wear()).is_greater(worn_before)


func test_a_worn_head_delivers_less_power_at_the_same_reactor_setting() -> void:
	var fresh := _one_boundary(1000.0)
	var worn := _one_boundary(1000.0)
	worn.set_power(0.0)
	DiveTestKit.wear_head_gently(worn, 0.5)
	for sim in [fresh, worn]:
		sim.set_power(1.0)
		DiveTestKit.run(sim, 5.0, 0.1)

	assert_float(worn.residual(ACTIVE)).is_equal_approx(fresh.residual(ACTIVE), 1e-6)
	assert_float(worn.reactor_output()).is_less(fresh.reactor_output())


# --- What pulls the steadiness down ----------------------------------------------

func test_a_steady_plasma_reports_no_cause() -> void:
	var sim := _at_rest()
	sim.advance(0.1)

	assert_float(sim.plasma_stability()).is_equal(1.0)
	assert_array(sim.steadiness_causes()).is_empty()


func test_a_worn_head_alone_is_reported_as_worn() -> void:
	var sim := _at_rest()
	DiveTestKit.wear_head_gently(sim, 0.5)
	DiveTestKit.run(sim, 600.0)  # At rest, the hull as cool as the rock.

	assert_float(sim.plasma_stability()).is_less(1.0)
	assert_array(sim.steadiness_causes()).is_equal([DiveSimulation.CAUSE_WORN])


func test_a_residual_outside_the_band_alone_is_reported_as_out_of_the_band() -> void:
	var sim := _steady_residual(2.0)
	sim.advance(0.1)

	assert_float(sim.plasma_stability()).is_less(1.0)
	assert_array(sim.steadiness_causes()).is_equal([DiveSimulation.CAUSE_OUT_OF_BAND])


func test_a_hot_hull_is_reported_once_its_narrowed_band_tells() -> void:
	var hot := DiveTestKit.run(_hot_or_cool(1.0), 400.0)
	# Hot, but the Residual flat: nothing pulls the steadiness down.
	assert_array(hot.steadiness_causes()).is_empty()

	# A Residual a cool Head would bear, outside this one's narrowed Band.
	var cool := DiveTestKit.run(_hot_or_cool(0.2), 400.0)
	DiveTestKit.tune(hot, ACTIVE, DiveTestKit.wobble(hot) + Vector2(0.0, (hot.band() + 3.0 * cool.band()) / 4.0 + cool.band()))
	hot.advance(0.1)

	assert_array(hot.steadiness_causes()).contains([DiveSimulation.CAUSE_HOT, DiveSimulation.CAUSE_OUT_OF_BAND])
	assert_array(hot.steadiness_causes()).not_contains([DiveSimulation.CAUSE_WORN])


func test_every_cause_at_once_is_reported_one_by_one() -> void:
	var sim := _hot_or_cool(1.0)
	sim.debug_wear_head(0.5)
	DiveTestKit.run(sim, 400.0)
	_detune(sim, 1.2)
	DiveTestKit.run(sim, 1.0, 0.1)

	assert_array(sim.steadiness_causes()).contains_exactly_in_any_order(
			[DiveSimulation.CAUSE_WORN, DiveSimulation.CAUSE_HOT, DiveSimulation.CAUSE_OUT_OF_BAND])


func test_a_lost_plasma_reports_no_cause() -> void:
	var sim := _at_rest()
	sim.debug_lose_plasma()

	assert_array(sim.steadiness_causes()).is_empty()


# --- Crossing a Boundary -------------------------------------------------------

## Crosses the one Boundary and runs on `seconds` past it, the crew doing
## what `after_crossing` does on the first step past it (and nothing if it
## is not given). STANDBY is prepared for the hard rock if `prepared`.
func _cross(after_crossing := Callable(), prepared := false, seconds := 60.0) -> DiveSimulation:
	var sim := _one_boundary()
	if prepared:
		DiveTestKit.run_until(sim, &"boundary_approaching")
		DiveTestKit.tune(sim, STANDBY, Vector2(sim.wobble_ahead_frequency(), sim.wobble_ahead_amplitude()))
	DiveTestKit.run_until(sim, &"boundary_crossed")
	if after_crossing.is_valid():
		after_crossing.call(sim)
	DiveTestKit.run(sim, seconds, 0.1)
	return sim


## The crew tunes ACTIVE by hand after the crossing: a press of each control
## toward the Wobble every half second, as fast as hands and eyes manage.
func _tune_by_hand(sim: DiveSimulation, seconds := 60.0) -> void:
	sim.select_channel(ACTIVE)
	for i in int(seconds / 0.5):
		var wobble := DiveTestKit.wobble(sim)
		sim.tune_frequency(move_toward(sim.counter_wave_frequency(ACTIVE), wobble.x, 0.02 * wobble.x))
		sim.tune_amplitude(move_toward(sim.counter_wave_amplitude(ACTIVE), wobble.y, 0.02))
		DiveTestKit.run(sim, 0.5, 0.1)


func test_a_prepared_swap_at_the_crossing_wears_less_than_tuning_active_afterwards_which_wears_less_than_doing_nothing() -> void:
	var swapped := _cross(func(s: DiveSimulation) -> void: s.shift(), true)
	var tuned := _cross(func(s: DiveSimulation) -> void: _tune_by_hand(s), false, 0.0)
	var left := _cross(Callable(), false, 30.0)

	assert_bool(swapped.out_of_band()).is_false()
	assert_bool(tuned.out_of_band()).is_false()
	assert_bool(left.out_of_band()).is_true()
	assert_float(swapped.head_wear()).is_less(tuned.head_wear())
	assert_float(tuned.head_wear()).is_less(left.head_wear())


func test_a_prepared_swap_at_the_crossing_does_not_wear_the_head_at_all() -> void:
	var swapped := _cross(func(s: DiveSimulation) -> void: s.shift(), true)

	assert_float(swapped.head_wear()).is_equal(0.0)


func test_the_reactors_autopilot_tunes_active_back_inside_the_band_wearing_the_head_on_the_way() -> void:
	var sim := _one_boundary()
	sim.set_autopilot(DiveSimulation.STATION_REACTOR, true)
	DiveTestKit.run_until(sim, &"boundary_crossed")
	sim.advance(0.1)
	var just_past := DiveTestKit.counter_wave(sim, ACTIVE).distance_to(DiveTestKit.wobble(sim))
	DiveTestKit.run(sim, 3.0, 0.1)
	var on_the_way := DiveTestKit.counter_wave(sim, ACTIVE).distance_to(DiveTestKit.wobble(sim))

	# Slowly: still outside the Band, but its Counter-wave nearer the Wobble.
	assert_bool(sim.out_of_band()).is_true()
	assert_float(on_the_way).is_less(just_past)
	assert_bool(DiveTestKit.fly_until(sim, func(s: DiveSimulation) -> bool: return not s.out_of_band(), 600.0, 0.5, false)).is_true()
	assert_float(sim.head_wear()).is_greater(0.0)
	assert_bool(sim.plasma_lost()).is_false()
	assert_bool(sim.autopilot(DiveSimulation.STATION_REACTOR)).is_true()
	# It makes no Shift: STANDBY is as the crew left it.
	assert_float(sim.counter_wave_frequency(STANDBY)).is_equal_approx(DiveTestKit.wobble_in(_soft()).x, 1e-6)


func test_the_reactors_autopilot_wears_the_head_less_than_leaving_it_and_more_than_a_prepared_swap() -> void:
	var autopiloted := _cross(func(s: DiveSimulation) -> void: s.set_autopilot(DiveSimulation.STATION_REACTOR, true))
	var left := _cross(Callable(), false, 30.0)
	var swapped := _cross(func(s: DiveSimulation) -> void: s.shift(), true)

	assert_float(autopiloted.head_wear()).is_less(left.head_wear())
	assert_float(autopiloted.head_wear()).is_greater(swapped.head_wear())


func test_engaging_the_reactors_autopilot_never_changes_head_wear_in_that_step() -> void:
	# Engaged late, the Residual long outside the Band, on a fresh Head and
	# a badly worn one: the step it is engaged in wears no more than the
	# steps before it did.
	for wear in [0.0, 0.3]:
		var sim := _one_boundary()
		sim.debug_wear_head(wear)
		DiveTestKit.run_until(sim, &"boundary_crossed")
		DiveTestKit.run(sim, 10.0, 0.1)
		var most := 0.0
		for i in 50:
			var before := sim.head_wear()
			sim.advance(0.1)
			most = maxf(most, sim.head_wear() - before)
		var before_engaging := sim.head_wear()

		sim.set_autopilot(DiveSimulation.STATION_REACTOR, true)
		assert_float(sim.head_wear()).is_equal(before_engaging)
		sim.advance(0.1)

		assert_float(sim.head_wear() - before_engaging).is_less_equal(most)
		assert_bool(sim.plasma_lost()).is_false()


## Soft and hard rock taking turns every 15 m: Boundary after Boundary.
func _many_boundaries() -> DiveSimulation:
	var layers := []
	for i in 40:
		layers.append([i * 15.0, _soft() if i % 2 == 0 else _hard()])
	var sim := DiveSimulation.new(MediumLayout.layered(layers))
	sim.set_power(1.0)
	return sim


func test_left_to_the_autopilot_boundary_after_boundary_wears_the_head_until_the_plasma_is_lost() -> void:
	var sim := _many_boundaries()
	sim.set_autopilot(DiveSimulation.STATION_REACTOR, true)
	var seen := []

	var lost := DiveTestKit.run_until(sim, &"plasma_lost", 20000.0, seen, 0.25)

	assert_dict(lost).is_not_empty()
	# Carelessness has a limit, but not at the first Boundary.
	assert_int(DiveTestKit.types(seen).count(&"boundary_crossed")).is_greater(1)
	assert_float(sim.head_wear()).is_greater(0.0)
	assert_bool(sim.plasma_lost()).is_true()
	assert_float(sim.plasma_stability()).is_equal(0.0)
	DiveTestKit.run_until(sim, &"never", 60.0)
	assert_float(sim.reactor_output()).is_equal(0.0)
	assert_float(sim.speed()).is_equal(0.0)


func test_prepared_swaps_at_every_crossing_never_wear_the_head() -> void:
	var sim := _many_boundaries()
	DiveTestKit.tune(sim, STANDBY, DiveTestKit.wobble_in(_hard()))
	for i in 10:
		DiveTestKit.run_until(sim, &"boundary_crossed", 20000.0, [], 0.25)
		# The old ACTIVE, dropped to STANDBY, is ready for the rock after.
		sim.shift()

	sim.advance(0.25)
	assert_float(sim.head_wear()).is_equal(0.0)
	assert_bool(sim.plasma_lost()).is_false()


func test_a_boundary_crossed_with_the_hull_hot_wears_the_head_more() -> void:
	var hot := _crossed_hot_or_cool(1.0)
	var cool := _crossed_hot_or_cool(0.2)

	assert_float(hot.vessel_temperature()).is_greater(cool.vessel_temperature())
	assert_float(hot.head_wear()).is_greater(cool.head_wear())


## Dives at this power to a deep Boundary, so the hull settles hot or cool,
## then lets the autopilot tune ACTIVE back inside the Band.
func _crossed_hot_or_cool(power: float) -> DiveSimulation:
	var sim := DiveSimulation.new(MediumLayout.layered([[0.0, _soft()], [300.0, _hard()]]))
	sim.set_power(power)
	sim.set_autopilot(DiveSimulation.STATION_REACTOR, true)
	DiveTestKit.run_until(sim, &"boundary_crossed", 20000.0, [], 0.25)
	DiveTestKit.fly_until(sim, func(s: DiveSimulation) -> bool: return not s.out_of_band(), 600.0, 0.25, false)
	return sim


# --- Losing the plasma ------------------------------------------------------------

func test_a_residual_far_outside_the_band_loses_the_plasma_on_a_badly_worn_head_but_not_a_fresh_one() -> void:
	var fresh := _at_rest()
	var worn := _at_rest()
	DiveTestKit.wear_head_gently(worn, 0.6)
	var worn_before := worn.head_wear()
	fresh.take_events()

	for sim in [fresh, worn]:
		_detune(sim, 1.0, 2.5)
		DiveTestKit.run(sim, 10.0, 0.1)

	assert_bool(fresh.plasma_lost()).is_false()
	assert_float(fresh.head_wear()).is_greater(0.0)
	assert_bool(worn.plasma_lost()).is_true()
	# Not merely the last straw: what the same Residual wore into the fresh
	# Head would not have worn this one through.
	assert_float(worn_before + fresh.head_wear()).is_less(1.0)
	assert_float(worn.head_wear()).is_less(1.0)


func test_left_long_enough_outside_the_band_the_head_wears_through_or_is_disrupted() -> void:
	var sim := _steady_residual(2.0)

	var lost := DiveTestKit.run_until(sim, &"plasma_lost", 20000.0, [], 1.0)

	assert_dict(lost).is_not_empty()
	assert_bool(lost.cause in [&"worn_through", &"disrupted"]).is_true()


## The first dive to its first Boundary, sand into sandstone, the Head worn
## to `wear` first. Returns the sim just past the Boundary, nothing done at
## the Reactor.
func _first_boundary(wear := 0.0) -> DiveSimulation:
	var layout := MediumLayout.first_dive()
	var sim := DiveSimulation.new(layout)
	sim.set_attended(DiveSimulation.STATION_REACTOR, true)
	if wear > 0.0:
		DiveTestKit.wear_head_gently(sim, wear)
	sim.set_power(0.5)
	var crossed := DiveTestKit.run_until(sim, &"boundary_crossed", 20000.0, [], 0.25)
	var first := layout.boundary_depths()[0]
	assert_str(String(crossed.to)).is_equal(String(layout.medium_at(first + 1.0).name))
	assert_str(String(sim.medium().name)).is_equal(String(layout.medium_at(first + 1.0).name))
	return sim


func test_the_first_boundary_left_alone_for_a_while_grinds_a_fresh_head_but_keeps_the_plasma() -> void:
	var fresh := _first_boundary()

	DiveTestKit.run(fresh, 10.0, 0.1)

	assert_bool(fresh.out_of_band()).is_true()
	assert_float(fresh.head_wear()).is_greater(0.0)
	assert_float(fresh.shudder()).is_greater(0.0)
	assert_bool(fresh.plasma_lost()).is_false()
	# Cancelled then, the grinding stops.
	DiveTestKit.cancel_wobble(fresh)
	DiveTestKit.run(fresh, 5.0, 0.1)
	assert_float(fresh.shudder()).is_equal(0.0)
	assert_bool(fresh.plasma_lost()).is_false()


func test_the_first_boundary_left_alone_loses_the_plasma_on_a_badly_worn_head() -> void:
	var worn := _first_boundary(0.6)

	DiveTestKit.run(worn, 10.0, 0.1)

	assert_bool(worn.plasma_lost()).is_true()
